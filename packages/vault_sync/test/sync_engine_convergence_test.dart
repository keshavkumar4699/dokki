/// Two full `SyncEngine` instances over one `FakeCloudProvider` (§13.5
/// lite): real crypto, real sealer/reducer/executor, two devices. The
/// capstone of Phase 7: offline divergence, convergence, deterministic
/// conflict winner, and nothing lost.
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';
import 'package:vault_crypto/vault_crypto.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_sync/vault_sync.dart';

import 'support/fakes.dart';

/// A blob store that really seals/opens Envelope v1 via the dev
/// primitive, so segments move as ciphertext exactly as in production.
final class _SealedMemBlobStore implements BlobStore {
  _SealedMemBlobStore(this.crypto, this.ids);

  final CryptoEngine crypto;
  final SequenceIds ids;
  final Map<String, List<int>> blobs = {};

  @override
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final id = ids.newBlobId();
    final bytes = <int>[];
    await crypto
        .sealStream(source, keyEpoch: 1, purpose: _purposeOf(storageClass))
        .forEach(bytes.addAll);
    blobs[id] = bytes;
    return Ok(
      BlobRef(
        id: id,
        storageClass: storageClass,
        relPath: 'mem/$id',
        keyEpoch: 1,
        wrappedDek: const [1],
        plaintextSize: expectedSize,
        ciphertextSize: bytes.length,
        ciphertextSha256: 'ab' * 32,
        plaintextSha256: 'cd' * 32,
      ),
    );
  }

  @override
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id) async =>
      blobs.containsKey(id) ? Ok(_Handle(id)) : Err(CorruptFile(id));

  @override
  Stream<List<int>>? ciphertextStream(BlobHandle handle) =>
      blobs[handle.token] == null ? null : Stream.value(blobs[handle.token]!);

  @override
  Future<Result<({int ciphertextSize, String ciphertextSha256}), VaultFailure>>
  writeSealed(
    BlobId id,
    Stream<List<int>> ciphertext, {
    StorageClass storageClass = StorageClass.asset,
    required String expectedCiphertextSha256,
    CancellationToken? cancel,
  }) async {
    final bytes = <int>[];
    await ciphertext.forEach(bytes.addAll);
    blobs[id] = bytes;
    return Ok((ciphertextSize: bytes.length, ciphertextSha256: ''));
  }

  /// Opens and decrypts a stored blob (test helper).
  Future<List<int>> openPlaintext(BlobId id) async {
    final bytes = <int>[];
    await crypto
        .openStream(
          Stream.value(blobs[id]!),
          expectedPurpose: EnvelopePurpose.logSegment,
        )
        .forEach(bytes.addAll);
    return bytes;
  }

  EnvelopePurpose _purposeOf(StorageClass cls) => switch (cls) {
    StorageClass.asset => EnvelopePurpose.asset,
    StorageClass.thumbnail => EnvelopePurpose.thumbnail,
    StorageClass.exportArtifact => EnvelopePurpose.exportArtifact,
    StorageClass.syncLog => EnvelopePurpose.logSegment,
  };

  @override
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  }) async => Ok(blobs[id]!);

  @override
  Future<Result<void, VaultFailure>> verify(BlobId id) async =>
      const Ok(null);

  @override
  Future<Result<void, VaultFailure>> evict(BlobId id) => purge(id);

  @override
  Future<Result<void, VaultFailure>> purge(BlobId id) async {
    blobs.remove(id);
    return const Ok(null);
  }

  @override
  Future<Result<bool, VaultFailure>> exists(BlobId id) async =>
      Ok(blobs.containsKey(id));
}

final class _Handle implements BlobHandle {
  const _Handle(this.token);

  @override
  final String token;

  @override
  int? get plaintextSize => null;
}

/// One simulated device: engine + full in-memory port stack.
final class _Device {
  _Device(this.id, this.crypto, this.cloud) {
    clock = FakeClock();
    final ids = SequenceIds();
    syncState = InMemorySyncState();
    apply = InMemoryApplyPort();
    blobStore = _SealedMemBlobStore(crypto, ids);
    engine = SyncEngine(
      deviceId: id,
      syncState: syncState,
      apply: apply,
      blobStore: blobStore,
      cloud: cloud,
      crypto: crypto,
      ids: ids,
      clock: clock,
      random: SeededRandom(),
    );
  }

  final String id;
  final CryptoEngine crypto;
  final FakeCloudProvider cloud;
  late final FakeClock clock;
  late final InMemorySyncState syncState;
  late final InMemoryApplyPort apply;
  late final _SealedMemBlobStore blobStore;
  late final SyncEngine engine;

  int _hlcCounter = 0;

  Hlc nextHlc() => Hlc(clock.now().millisecondsSinceEpoch, _hlcCounter++, id);

  /// Emits the create-entry op set into the local log (what
  /// `EntryRepositoryImpl` does in production).
  Future<void> createEntry(String entryId, String assetId) async {
    final hlc = nextHlc();
    for (final op in <SyncOp>[
      UpsertEntryOp(
        hlc: hlc,
        origin: id,
        id: entryId,
        type: 'PHOTO',
        sealedTitleBase64: base64Encode(utf8.encode('doc-$entryId')),
        sealedNoteBase64: null,
        sealedTagsBase64: null,
        createdAtMillis: hlc.physicalMillis,
        deletedAtMillis: null,
      ),
      UpsertAssetOp(
        hlc: hlc,
        origin: id,
        id: assetId,
        entryId: entryId,
        role: 'PRIMARY',
        ordinal: 0,
        createdAtMillis: hlc.physicalMillis,
      ),
      AddVersionOp(
        hlc: hlc,
        origin: id,
        id: 'v0-$assetId',
        assetId: assetId,
        parentVersionId: null,
        kind: 'ORIGINAL',
        seq: 0,
        blobId: 'blob-v0-$assetId',
        recipeJson: null,
        recipeDeterministic: true,
        meta: ImageMeta(
          width: 10,
          height: 10,
          mime: 'image/jpeg',
          plaintextSha256: 'cd' * 32,
          byteSize: 100,
        ),
        createdAtMillis: hlc.physicalMillis,
        blobKeyEpoch: 1,
        blobWrappedDekBase64: base64Encode(const [1, 2, 3]),
        blobCiphertextSha256: 'ab' * 32,
        blobCiphertextSize: 160,
      ),
      SetCurrentOp(
        hlc: hlc,
        origin: id,
        assetId: assetId,
        versionId: 'v0-$assetId',
      ),
    ]) {
      await syncState.appendLogOp(op, now: clock.now());
    }
  }

  /// Emits an edit (new version + pointer move), the §9.5 v7/v8 shape.
  Future<void> edit(String assetId, String versionId, String parentId) async {
    final hlc = nextHlc();
    for (final op in <SyncOp>[
      AddVersionOp(
        hlc: hlc,
        origin: id,
        id: versionId,
        assetId: assetId,
        parentVersionId: parentId,
        kind: 'DERIVED',
        seq: 1,
        blobId: 'blob-$versionId',
        recipeJson: '[{"op":"rotate","quarterTurns":1}]',
        recipeDeterministic: true,
        meta: ImageMeta(
          width: 10,
          height: 10,
          mime: 'image/jpeg',
          plaintextSha256: 'cd' * 32,
          byteSize: 100,
        ),
        createdAtMillis: hlc.physicalMillis,
        blobKeyEpoch: 1,
        blobWrappedDekBase64: base64Encode(const [1, 2, 3]),
        blobCiphertextSha256: 'ab' * 32,
        blobCiphertextSize: 160,
      ),
      SetCurrentOp(
        hlc: hlc,
        origin: id,
        assetId: assetId,
        versionId: versionId,
      ),
    ]) {
      await syncState.appendLogOp(op, now: clock.now());
    }
  }

  Future<SyncCycleReport> sync() => engine
      .syncNow()
      .then((r) => r.fold((v) => v, (f) => throw StateError('$f')));
}

void main() {
  late FakeCloudProvider cloud;
  late CryptoEngine crypto;
  late _Device a;
  late _Device b;

  setUp(() {
    cloud = FakeCloudProvider();
    final primitive = DartEnvelopePrimitive()
      ..bindMasterKey(1, SecretKey(List<int>.filled(32, 7)));
    crypto = CryptoEngineImpl(
      cipher: EnvelopeCipher(primitive: primitive, random: SeededRandom()),
      activeKeyEpoch: () => 1,
    );
    a = _Device('device-a', crypto, cloud);
    b = _Device('device-b', crypto, cloud);
  });

  test('a sealed segment reaches the peer and converges state', () async {
    await a.createEntry('entry-1', 'asset-1');
    // Force the segment to seal now (default 5-minute age would defer).
    final sealer = SegmentSealer(
      syncState: a.syncState,
      blobStore: a.blobStore,
      clock: a.clock,
      maxAge: Duration.zero,
    );
    expect((await sealer.sealIfDue(a.id)).okOrNull, isNotNull);
    await a.sync();

    // The segment is on the "cloud" as ciphertext.
    expect(cloud.objects.values, isNotEmpty);
    final uploaded = cloud.putPayloads.first;
    expect(
      utf8.decode(uploaded, allowMalformed: true),
      isNot(contains('upsertEntry')),
      reason: 'segments travel sealed, never as readable JSON (T5)',
    );

    await b.sync();
    expect(b.apply.entries, contains('entry-1'));
    expect(b.apply.assets, contains('asset-1'));
    expect(b.apply.versions, contains('v0-asset-1'));
    final pointer = (await b.apply.currentPointer('asset-1')).okOrNull!;
    expect(pointer.versionId, 'v0-asset-1');
    // Downloads were queued for the remote-only blob.
    expect(
      (await b.syncState.pendingOps()).okOrNull!
          .map((op) => op.opType),
      contains(SyncQueueOpType.downloadBlob),
    );
  });

  test('offline divergence: both edits survive, one deterministic winner', () async {
    await a.createEntry('entry-1', 'asset-1');
    final sealer = SegmentSealer(
      syncState: a.syncState,
      blobStore: a.blobStore,
      clock: a.clock,
      maxAge: Duration.zero,
    );
    await sealer.sealIfDue(a.id);
    await a.sync();
    await b.sync();
    // Partition. A writes v7 (newer), B writes v8 (older).
    a.clock.advance(const Duration(minutes: 2));
    await a.edit('asset-1', 'v7', 'v0-asset-1');
    await b.edit('asset-1', 'v8', 'v0-asset-1');
    // Heal: two rounds to quiesce.
    final sealerB = SegmentSealer(
      syncState: b.syncState,
      blobStore: b.blobStore,
      clock: b.clock,
      maxAge: Duration.zero,
    );
    await sealer.sealIfDue(a.id);
    await sealerB.sealIfDue(b.id);
    await a.sync();
    await b.sync();
    await a.sync();
    await b.sync();

    final pa = (await a.apply.currentPointer('asset-1')).okOrNull!;
    final pb = (await b.apply.currentPointer('asset-1')).okOrNull!;
    expect(pa.versionId, pb.versionId, reason: 'pointers converge');
    expect(pa.versionId, 'v7', reason: 'higher HLC wins on both devices');
    // Both versions exist on both devices — nothing was overwritten (M2).
    for (final d in [a, b]) {
      expect(d.apply.versions.keys, containsAll(['v7', 'v8']));
    }
    // Exactly one conflict, same provisional winner on both.
    expect(a.syncState.conflicts.values.single.provisionalWinner,
        b.syncState.conflicts.values.single.provisionalWinner);
  });
}
