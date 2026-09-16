import 'package:test/test.dart';
import 'package:vault_domain/src/imaging/image_meta.dart';
import 'package:vault_domain/src/sync/conflict.dart';
import 'package:vault_domain/src/sync/hlc.dart';
import 'package:vault_domain/src/sync/sync_op.dart';
import 'package:vault_domain/src/sync/tombstone.dart';

const _hlc = Hlc(1700000000123, 5, 'dev-a');
const _origin = 'dev-a';
const _meta = ImageMeta(
  width: 4,
  height: 3,
  mime: 'image/jpeg',
  plaintextSha256: 'h',
  byteSize: 12,
);

final List<SyncOp> _allOps = [
  const UpsertEntryOp(
    hlc: _hlc,
    origin: _origin,
    id: 'e1',
    type: 'DOCUMENT',
    sealedTitleBase64: 'QUJD',
    sealedNoteBase64: null,
    sealedTagsBase64: null,
    createdAtMillis: 1700000000000,
    deletedAtMillis: null,
  ),
  const UpsertAssetOp(
    hlc: _hlc,
    origin: _origin,
    id: 'a1',
    entryId: 'e1',
    role: 'PAGE',
    ordinal: 0,
    createdAtMillis: 1700000000000,
  ),
  const AddVersionOp(
    hlc: _hlc,
    origin: _origin,
    id: 'v1',
    assetId: 'a1',
    parentVersionId: 'v0',
    kind: 'DERIVED',
    seq: 1,
    blobId: 'b1',
    recipeJson: '[{"op":"rotate","quarterTurns":1}]',
    recipeDeterministic: true,
    meta: _meta,
    createdAtMillis: 1700000000000,
  ),
  const SetCurrentOp(
    hlc: _hlc,
    origin: _origin,
    assetId: 'a1',
    versionId: 'v1',
  ),
  const ReorderPagesOp(
    hlc: _hlc,
    origin: _origin,
    entryId: 'e1',
    assetIds: ['a2', 'a1'],
  ),
  const EvictVersionOp(hlc: _hlc, origin: _origin, versionId: 'v0'),
  const TombstoneOp(
    hlc: _hlc,
    origin: _origin,
    entityKind: TombstoneEntityKind.entry,
    entityId: 'e1',
  ),
  const ResolveConflictOp(
    hlc: _hlc,
    origin: _origin,
    conflictId: 'c1',
    resolution: ConflictResolution.keepRemote,
  ),
  const DeviceJoinedOp(
    hlc: _hlc,
    origin: _origin,
    deviceId: 'dev-b',
    label: 'Pixel 7a',
  ),
];

void main() {
  test('every op round-trips through JSON', () {
    for (final op in _allOps) {
      final decoded = decodeSyncOp(encodeSyncOp(op));
      expect(decoded.runtimeType, op.runtimeType);
      expect(decoded.toJson(), op.toJson());
    }
  });

  test('op types are stable strings', () {
    expect(_allOps.map((SyncOp op) => op.opType), [
      'upsertEntry',
      'upsertAsset',
      'addVersion',
      'setCurrent',
      'reorderPages',
      'evictVersion',
      'tombstone',
      'resolveConflict',
      'deviceJoined',
    ]);
  });

  test('ops carry hlc, origin, and schema version', () {
    for (final op in _allOps) {
      expect(op.hlc, _hlc);
      expect(op.origin, _origin);
      expect(op.opSchemaVersion, currentOpSchemaVersion);
    }
  });

  test(
    'unknown ops throw FormatException (preserved at the segment layer)',
    () {
      expect(
        () => decodeSyncOp(
          '{"op":"futureThing","hlc":"0:0:x","origin":"d",'
          '"opSchemaVersion":9}',
        ),
        throwsFormatException,
      );
    },
  );

  test('encodeSyncOp is valid JSON text', () {
    final text = encodeSyncOp(_allOps.first);
    expect(text, startsWith('{'));
    expect(text, contains('"op":"upsertEntry"'));
  });

  test('AddVersionOp preserves eviction state', () {
    const op = AddVersionOp(
      hlc: _hlc,
      origin: _origin,
      id: 'v2',
      assetId: 'a1',
      parentVersionId: 'v1',
      kind: 'DERIVED',
      seq: 2,
      blobId: null,
      recipeJson: null,
      recipeDeterministic: true,
      meta: _meta,
      createdAtMillis: 1700000000000,
      evictedAtMillis: 1700000100000,
    );
    final decoded = decodeSyncOp(encodeSyncOp(op)) as AddVersionOp;
    expect(decoded.blobId, isNull);
    expect(decoded.evictedAtMillis, 1700000100000);
  });
}
