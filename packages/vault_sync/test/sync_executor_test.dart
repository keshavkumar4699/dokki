/// Queue executor tests (§9.7): upload idempotence, download
/// verification, delete semantics, full-jitter rescheduling, and the
/// queue-wide pause on rate limiting.
library;

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_sync/vault_sync.dart';

import 'support/fakes.dart';

void main() {
  late InMemorySyncState syncState;
  late FakeCloudProvider cloud;
  late _ExecutorBlobStore blobStore;
  late FakeClock clock;
  late SyncExecutor executor;

  setUp(() {
    syncState = InMemorySyncState();
    cloud = FakeCloudProvider();
    blobStore = _ExecutorBlobStore();
    clock = FakeClock();
    executor = SyncExecutor(
      syncState: syncState,
      cloud: cloud,
      blobStore: blobStore,
      retry: const RetryPolicy(
        base: Duration(seconds: 1),
        cap: Duration(minutes: 1),
      ),
      clock: clock,
      random: SeededRandom(),
    );
  });

  Future<void> enqueueUpload(String blobId) async {
    blobStore.blobs[blobId] = [1, 2, 3, 4];
    await syncState.enqueueUploadBlob(
      blobId: blobId,
      remoteName: 'b_$blobId.bin',
      idempotencyKey: 'blob:$blobId',
      priority: 100,
      now: clock.now(),
    );
  }

  test('an upload moves the sealed bytes and marks the object uploaded', () async {
    await enqueueUpload('blob-1');
    final report = (await executor.drain()).okOrNull!;
    expect(report.completed, 1);
    expect(cloud.putPayloads.single, [1, 2, 3, 4]);
    expect(
      cloud.objects.values.single.name,
      'b_blob-1.bin',
      reason: 'opaque remote name (§9.2)',
    );
    final record = syncState.cloudObjects['blob-1']!;
    expect(record.state, CloudObjectState.uploaded);
    expect(record.remoteId, isNotNull);
  });

  test('a throttled upload pauses the whole queue, not just this op', () async {
    await enqueueUpload('blob-1');
    await enqueueUpload('blob-2');
    cloud.script.add(const CloudRateLimited(retryAfter: Duration(seconds: 30)));
    final report = (await executor.drain()).okOrNull!;
    expect(report.paused, isTrue);
    expect(report.completed, 0);
    // Both ops remain pending for the next cycle.
    expect((await syncState.pendingOps()).okOrNull, hasLength(2));
  });

  test('a transient failure reschedules with backoff and keeps the lease free', () async {
    await enqueueUpload('blob-1');
    cloud.script.add(const SyncTransportFailure(httpStatus: 500));
    final report = (await executor.drain()).okOrNull!;
    expect(report.completed, 0);
    expect(report.rescheduled, 1);
    final pending = (await syncState.pendingOps()).okOrNull!;
    expect(pending.single.lastErrorCode, 'SYNC_TRANSPORT');
    // A later retry with a healthy cloud completes (past the backoff).
    clock.advance(const Duration(seconds: 5));
    final second = (await executor.drain()).okOrNull!;
    expect(second.completed, 1);
  });

  test('delete of an already-missing remote object is DONE (idempotent)', () async {
    await syncState.enqueueDeleteRemote(
      remoteId: 'remote-gone',
      idempotencyKey: 'del:1',
      now: clock.now(),
    );
    final report = (await executor.drain()).okOrNull!;
    expect(report.completed, 1);
  });

  test('a download verifies the ciphertext hash and flips state', () async {
    final bytes = [9, 8, 7, 6];
    cloud.objects['remote-1'] = (name: 'b_blob-9.bin', bytes: bytes);
    syncState.cloudObjects['blob-9'] = CloudObjectRecord(
      blobId: 'blob-9',
      remoteId: 'remote-1',
      remoteName: 'b_blob-9.bin',
      ciphertextSha256: _ExecutorBlobStore.shaOf(bytes),
      keyEpoch: 1,
      state: CloudObjectState.remoteOnly,
    );
    await syncState.enqueueDownloadBlob(
      blobId: 'blob-9',
      remoteName: 'b_blob-9.bin',
      idempotencyKey: 'download:blob-9',
      priority: 100,
      now: clock.now(),
    );
    final report = (await executor.drain()).okOrNull!;
    expect(report.completed, 1);
    expect(blobStore.blobs['blob-9'], bytes);
    expect(syncState.cloudObjects['blob-9']!.state, CloudObjectState.uploaded);
  });

  test('a tampered download is quarantined, never stored', () async {
    cloud.objects['remote-1'] = (name: 'b_blob-9.bin', bytes: [1, 1, 1]);
    cloud.corruptDownloads = true;
    syncState.cloudObjects['blob-9'] = CloudObjectRecord(
      blobId: 'blob-9',
      remoteId: 'remote-1',
      remoteName: 'b_blob-9.bin',
      ciphertextSha256: _ExecutorBlobStore.shaOf(const [1, 1, 1]),
      keyEpoch: 1,
      state: CloudObjectState.remoteOnly,
    );
    await syncState.enqueueDownloadBlob(
      blobId: 'blob-9',
      remoteName: 'b_blob-9.bin',
      idempotencyKey: 'download:blob-9',
      priority: 100,
      now: clock.now(),
    );
    final report = (await executor.drain()).okOrNull!;
    expect(report.completed, 0);
    expect(blobStore.blobs, isNot(contains('blob-9')));
    expect(syncState.cloudObjects['blob-9']!.state, CloudObjectState.tampered);
  });

  test('cancellation unwinds between ops', () async {
    await enqueueUpload('blob-1');
    await enqueueUpload('blob-2');
    final token = CancellationToken();
    cloud.script.add(const SyncTransportFailure(httpStatus: 500));
    token.cancel();
    final result = await executor.drain(cancel: token);
    expect(result.errOrNull, isA<OperationCancelled>());
  });
}

/// A tiny blob store for the executor: plaintext bytes keyed by id, with
/// a real FNV "sha" so the download verification has something to check.
final class _ExecutorBlobStore implements BlobStore {
  final Map<String, List<int>> blobs = {};

  static String shaOf(List<int> bytes) {
    var h = 0x811c9dc5;
    for (final b in bytes) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  @override
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id) async =>
      blobs.containsKey(id)
          ? Ok(_Handle(id))
          : Err(CorruptFile(id));

  @override
  Stream<List<int>>? ciphertextStream(BlobHandle handle) =>
      Stream.value(blobs[handle.token]!);

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
    if (expectedCiphertextSha256.isNotEmpty &&
        shaOf(bytes) != expectedCiphertextSha256) {
      return Err(RemoteObjectTampered(id));
    }
    blobs[id] = bytes;
    return Ok((ciphertextSize: bytes.length, ciphertextSha256: shaOf(bytes)));
  }

  @override
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, VaultFailure>> verify(BlobId id) async =>
      const Ok(null);

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

final class _Handle implements BlobHandle {
  const _Handle(this.token);

  @override
  final String token;

  @override
  int? get plaintextSize => null;
}
