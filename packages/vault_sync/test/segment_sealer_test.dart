/// Segment sealer tests (§9.3): due conditions, sealing, upload enqueue.
library;

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_sync/vault_sync.dart';

import 'support/fakes.dart';

void main() {
  late InMemorySyncState syncState;
  late FakeClock clock;
  late _MemBlobStore blobStore;
  late SegmentSealer sealer;

  UpsertEntryOp op(String id, int ms) => UpsertEntryOp(
    hlc: hlcAt(ms, 0, 'dev-a'),
    origin: 'dev-a',
    id: id,
    type: 'PHOTO',
    sealedTitleBase64: sealedField(id),
    sealedNoteBase64: null,
    sealedTagsBase64: null,
    createdAtMillis: ms,
    deletedAtMillis: null,
  );

  setUp(() {
    syncState = InMemorySyncState();
    clock = FakeClock(DateTime.utc(2026, 1, 1, 12));
    blobStore = _MemBlobStore();
    sealer = SegmentSealer(
      syncState: syncState,
      blobStore: blobStore,
      clock: clock,
    );
  });

  test('no open segment means nothing to seal', () async {
    final sealed = await sealer.sealIfDue('dev-a');
    expect(sealed.okOrNull, isNull);
  });

  test('a young, small open segment is left open', () async {
    await syncState.appendLogOp(
      op('e1', DateTime.utc(2026, 1, 1, 11, 59).millisecondsSinceEpoch),
      now: clock.now(),
    );
    final sealed = await sealer.sealIfDue('dev-a');
    expect(sealed.okOrNull, isNull);
  });

  test('an aged segment seals, persists, and queues the upload', () async {
    // Op stamped 10 minutes ago: the 5-minute age rule fires.
    final oldMs = clock.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch;
    await syncState.appendLogOp(op('e1', oldMs), now: clock.now());
    await syncState.appendLogOp(op('e2', oldMs + 1000), now: clock.now());

    final sealed = (await sealer.sealIfDue('dev-a')).okOrNull!;
    expect(sealed, isNotNull);
    expect(sealed.opCount, 2);
    expect(sealed.blobId, isNotNull);
    expect(sealed.remoteName, startsWith('l_dev-a_'));

    // The payload is a valid sealed blob in the store.
    expect(blobStore.blobs, contains(sealed.blobId));

    // The upload is queued, idempotent by segment identity.
    final pending = (await syncState.pendingOps()).okOrNull!;
    expect(pending.single.opType, SyncQueueOpType.uploadBlob);
    expect(pending.single.targetId, sealed.blobId);
    expect(pending.single.idempotencyKey, 'segment:dev-a:${sealed.seq}');

    // A new open segment starts fresh; the sealed one is immutable.
    expect((await syncState.openSegment('dev-a')).okOrNull, isNull);
  });

  test('a payload at the size cap seals regardless of age', () async {
    final nowMs = clock.now().millisecondsSinceEpoch;
    final big = 'x' * 1024;
    for (var i = 0; i < 300; i++) {
      await syncState.appendLogOp(
        UpsertEntryOp(
          hlc: hlcAt(nowMs + i, 0, 'dev-a'),
          origin: 'dev-a',
          id: 'e$i',
          type: 'PHOTO',
          sealedTitleBase64: sealedField(big),
          sealedNoteBase64: null,
          sealedTagsBase64: null,
          createdAtMillis: nowMs + i,
          deletedAtMillis: null,
        ),
        now: clock.now(),
      );
    }
    final sealed = (await sealer.sealIfDue('dev-a')).okOrNull!;
    expect(sealed, isNotNull);
  });
}

final class _MemBlobStore implements BlobStore {
  final Map<String, List<int>> blobs = {};
  int _n = 0;

  @override
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final bytes = <int>[];
    await source.forEach(bytes.addAll);
    final id = 'blob-${++_n}';
    blobs[id] = bytes;
    return Ok(
      BlobRef(
        id: id,
        storageClass: storageClass,
        relPath: 'logs/$id',
        keyEpoch: 1,
        wrappedDek: const [1],
        plaintextSize: bytes.length,
        ciphertextSize: bytes.length + 64,
        ciphertextSha256: 'ab' * 32,
        plaintextSha256: 'cd' * 32,
      ),
    );
  }

  @override
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id) =>
      throw UnimplementedError();

  @override
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  }) async => Ok(blobs[id]!);

  @override
  Future<Result<void, VaultFailure>> verify(BlobId id) async =>
      const Ok(null);

  @override
  Stream<List<int>>? ciphertextStream(BlobHandle handle) => null;

  @override
  Future<Result<({int ciphertextSize, String ciphertextSha256}), VaultFailure>>
  writeSealed(
    BlobId id,
    Stream<List<int>> ciphertext, {
    StorageClass storageClass = StorageClass.asset,
    required String expectedCiphertextSha256,
    CancellationToken? cancel,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, VaultFailure>> evict(BlobId id) =>
      throw UnimplementedError();

  @override
  Future<Result<void, VaultFailure>> purge(BlobId id) =>
      throw UnimplementedError();

  @override
  Future<Result<bool, VaultFailure>> exists(BlobId id) async =>
      Ok(blobs.containsKey(id));
}
