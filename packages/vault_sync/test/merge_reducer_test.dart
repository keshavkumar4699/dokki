/// Merge reducer tests (§9.5): LWW upserts, lineage-aware pointer
/// arbitration, deterministic fork outcomes, tombstone-vs-edit, and
/// replay idempotence (P6).
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_sync/vault_sync.dart';

import 'support/fakes.dart';

void main() {
  late InMemoryApplyPort apply;
  late InMemorySyncState syncState;
  late FakeClock clock;
  late MergeReducer reducer;

  setUp(() {
    apply = InMemoryApplyPort();
    syncState = InMemorySyncState();
    clock = FakeClock();
    reducer = MergeReducer(
      apply: apply,
      syncState: syncState,
      ids: SequenceIds(),
      clock: clock,
    );
  });

  UpsertEntryOp entryOp(String id, int ms, {String origin = 'dev-a'}) =>
      UpsertEntryOp(
        hlc: hlcAt(ms, 0, origin),
        origin: origin,
        id: id,
        type: 'PHOTO',
        sealedTitleBase64: sealedField('title-$ms'),
        sealedNoteBase64: null,
        sealedTagsBase64: null,
        createdAtMillis: ms,
        deletedAtMillis: null,
      );

  UpsertAssetOp assetOp(
    String id,
    String entryId,
    int ms, {
    String origin = 'dev-a',
  }) => UpsertAssetOp(
    hlc: hlcAt(ms, 0, origin),
    origin: origin,
    id: id,
    entryId: entryId,
    role: 'PRIMARY',
    ordinal: 0,
    createdAtMillis: ms,
  );

  AddVersionOp versionOp(
    String id,
    String assetId,
    String? parent,
    int ms, {
    String origin = 'dev-a',
    int seq = 1,
  }) => AddVersionOp(
    hlc: hlcAt(ms, 0, origin),
    origin: origin,
    id: id,
    assetId: assetId,
    parentVersionId: parent,
    kind: parent == null ? 'ORIGINAL' : 'DERIVED',
    seq: seq,
    blobId: 'blob-$id',
    recipeJson: null,
    recipeDeterministic: true,
    meta: ImageMeta(
      width: 100,
      height: 80,
      mime: 'image/jpeg',
      plaintextSha256: 'cd' * 32,
      byteSize: 1234,
    ),
    createdAtMillis: ms,
    blobKeyEpoch: 1,
    blobWrappedDekBase64: base64Encode([1, 2, 3]),
    blobCiphertextSha256: 'ab' * 32,
    blobCiphertextSize: 1300,
  );

  SetCurrentOp currentOp(
    String assetId,
    String versionId,
    int ms, {
    String origin = 'dev-a',
  }) => SetCurrentOp(
    hlc: hlcAt(ms, 0, origin),
    origin: origin,
    assetId: assetId,
    versionId: versionId,
  );

  Future<void> seedEntry() async {
    await reducer.replay([
      entryOp('entry-1', 100),
      assetOp('asset-1', 'entry-1', 100),
      versionOp('v1', 'asset-1', null, 100),
      currentOp('asset-1', 'v1', 100),
    ]);
  }

  test('upserts apply in order and LWW by HLC', () async {
    await seedEntry();
    // Older rename loses; newer wins.
    await reducer.replay([entryOp('entry-1', 50)]);
    expect(apply.entries['entry-1']!.hlc, hlcAt(100, 0, 'dev-a'));
    await reducer.replay([entryOp('entry-1', 200)]);
    expect(apply.entries['entry-1']!.hlc, hlcAt(200, 0, 'dev-a'));
  });

  test('AddVersionOp registers the blob REMOTE_ONLY first (FK order)', () async {
    await seedEntry();
    expect(apply.versions, contains('v1'));
    expect(apply.remoteOnlyBlobs, contains('blob-v1'));
  });

  test('a fast-forward pointer move is not a conflict', () async {
    await seedEntry();
    // Peer continues our lineage: v2 derives from v1 and points at it.
    final report = await reducer.replay([
      versionOp('v2', 'asset-1', 'v1', 300, origin: 'dev-b'),
      currentOp('asset-1', 'v2', 300, origin: 'dev-b'),
    ]);
    expect(report.okOrNull!.conflictsRaised, 0);
    final pointer = (await apply.currentPointer('asset-1')).okOrNull;
    expect(pointer!.versionId, 'v2');
    expect(syncState.conflicts, isEmpty);
  });

  test('a fork raises a deterministic conflict and pins both versions', () async {
    await seedEntry();
    // Local edit: v7 derives from v1, pointer moves (device a, ms 400).
    await reducer.replay([
      versionOp('v7', 'asset-1', 'v1', 400),
      currentOp('asset-1', 'v7', 400),
    ]);
    // Remote edit (device b): v8 derives from v1 too, ms 350 (older).
    final report = await reducer.replay([
      versionOp('v8', 'asset-1', 'v1', 350, origin: 'dev-b'),
      currentOp('asset-1', 'v8', 350, origin: 'dev-b'),
    ]);
    expect(report.okOrNull!.conflictsRaised, 1);
    // v7 stays current (higher HLC), both versions exist and are pinned.
    final pointer = (await apply.currentPointer('asset-1')).okOrNull;
    expect(pointer!.versionId, 'v7');
    expect(apply.versions.keys, containsAll(['v7', 'v8']));
    expect(
      apply.pins,
      containsAll([
        ('v7', 'CONFLICT', 'asset-1'),
        ('v8', 'CONFLICT', 'asset-1'),
      ]),
    );
    final conflict = syncState.conflicts.values.single;
    expect(conflict.kind, ConflictKind.assetCurrent);
    expect(conflict.provisionalWinner, ConflictWinner.local);
    expect(
      (jsonDecode(conflict.remoteStateJson) as Map)['versionId'],
      'v8',
    );
  });

  test('the fork winner is deterministic regardless of arrival side', () async {
    // Mirror of the previous test from the other device's perspective:
    // v8 (ms 350 local) is current; v7 (ms 400) arrives and must win.
    await seedEntry();
    await reducer.replay([
      versionOp('v8', 'asset-1', 'v1', 350, origin: 'dev-b'),
      currentOp('asset-1', 'v8', 350, origin: 'dev-b'),
    ]);
    final report = await reducer.replay([
      versionOp('v7', 'asset-1', 'v1', 400),
      currentOp('asset-1', 'v7', 400),
    ]);
    expect(report.okOrNull!.conflictsRaised, 1);
    final pointer = (await apply.currentPointer('asset-1')).okOrNull;
    expect(pointer!.versionId, 'v7', reason: 'higher HLC wins on both');
    final conflict = syncState.conflicts.values.single;
    expect(conflict.provisionalWinner, ConflictWinner.remote);
  });

  test('replay is idempotent: the same ops twice change nothing (P6)', () async {
    await seedEntry();
    final ops = [
      versionOp('v2', 'asset-1', 'v1', 300, origin: 'dev-b'),
      currentOp('asset-1', 'v2', 300, origin: 'dev-b'),
    ];
    await reducer.replay(ops);
    final first = (await apply.currentPointer('asset-1')).okOrNull;
    final second = await reducer.replay(ops);
    expect(second.okOrNull!.applied, 0);
    final pointer = (await apply.currentPointer('asset-1')).okOrNull;
    expect(pointer!.versionId, first!.versionId);
    expect(syncState.conflicts, isEmpty);
  });

  test('a tombstone loses to a causally-newer local edit', () async {
    await seedEntry();
    await reducer.replay([entryOp('entry-1', 500)]); // edit at 500
    final report = await reducer.replay([
      TombstoneOp(
        hlc: hlcAt(400, 0, 'dev-b'),
        origin: 'dev-b',
        entityKind: TombstoneEntityKind.entry,
        entityId: 'entry-1',
      ),
    ]);
    expect(report.okOrNull!.conflictsRaised, 1);
    expect(apply.entries['entry-1']!.deletedAt, isNull);
    expect(
      syncState.conflicts.values.single.kind,
      ConflictKind.tombstoneVsEdit,
    );
  });

  test('a tombstone applies when no newer edit exists', () async {
    await seedEntry();
    await reducer.replay([
      TombstoneOp(
        hlc: hlcAt(400, 0, 'dev-b'),
        origin: 'dev-b',
        entityKind: TombstoneEntityKind.entry,
        entityId: 'entry-1',
      ),
    ]);
    expect(apply.entries['entry-1']!.deletedAt, isNotNull);
  });

  test('reorder applies when newer, ignored when stale', () async {
    await seedEntry();
    await reducer.replay([
      ReorderPagesOp(
        hlc: hlcAt(50, 0, 'dev-b'),
        origin: 'dev-b',
        entryId: 'entry-1',
        assetIds: const ['asset-1'],
      ),
    ]);
    expect(apply.entries['entry-1']!.hlc, hlcAt(100, 0, 'dev-a'));
    await reducer.replay([
      ReorderPagesOp(
        hlc: hlcAt(600, 0, 'dev-b'),
        origin: 'dev-b',
        entryId: 'entry-1',
        assetIds: const ['asset-1'],
      ),
    ]);
    expect(apply.entries['entry-1']!.hlc, hlcAt(600, 0, 'dev-b'));
  });

  test('eviction is idempotent and clears the blob pointer', () async {
    await seedEntry();
    final ops = [EvictVersionOp(hlc: hlcAt(700, 0, 'dev-b'), origin: 'dev-b', versionId: 'v1')];
    await reducer.replay(ops);
    expect(apply.versions['v1']!.evicted, isTrue);
    expect(apply.versions['v1']!.blobId, isNull);
    final second = await reducer.replay(ops);
    expect(second.okOrNull!.applied, 0);
  });

  test('unknown ops are skipped without side effects', () async {
    final report = await reducer.replay([
      UnknownSyncOp(
        hlc: hlcAt(800, 0, 'dev-z'),
        origin: 'dev-z',
        opSchemaVersion: 99,
        rawJson: const {'op': 'shareEntry', 'id': 'e9'},
      ),
    ]);
    expect(report.okOrNull!.skipped, 1);
    expect(apply.entries, isEmpty);
  });
}
