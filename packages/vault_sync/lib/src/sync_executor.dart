/// The queue executor (§9.7): drains `sync_queue` rows with leases,
/// full-jitter backoff, and queue-wide pause on rate limiting.
///
/// The executor moves CIPHERTEXT only. It never decrypts anything and
/// never needs a user-authenticated key, which is why it can run in a
/// background WorkManager job (§7.2 payoff).
library;

import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';

/// How one drain pass ended.
final class DrainReport {
  const DrainReport({
    required this.completed,
    required this.rescheduled,
    required this.paused,
  });

  final int completed;
  final int rescheduled;

  /// The queue stopped early on rate limiting or auth failure.
  final bool paused;
}

final class SyncExecutor {
  const SyncExecutor({
    required this.syncState,
    required this.cloud,
    required this.blobStore,
    required this.retry,
    required this.clock,
    required this.random,
    this.workerId = 'sync-main',
    this.lease = const Duration(minutes: 2),
  });

  final SyncStateRepository syncState;
  final CloudProvider cloud;
  final BlobStore blobStore;
  final RetryPolicy retry;
  final Clock clock;
  final RandomSource random;
  final String workerId;
  final Duration lease;

  /// Processes ready ops until the queue is empty, [maxOps] is hit, or a
  /// queue-wide stop is required (429/auth).
  Future<Result<DrainReport, VaultFailure>> drain({
    int maxOps = 64,
    CancellationToken? cancel,
  }) => guardSync('drain', () async {
    var completed = 0;
    var rescheduled = 0;
    while (completed + rescheduled < maxOps) {
      cancel?.throwIfCancelled();
      final claimed = unwrapSync(
        await syncState.claimNext(
          workerId: workerId,
          now: clock.now(),
          lease: lease,
        ),
      );
      if (claimed == null) {
        break;
      }
      final outcome = await _execute(claimed, cancel);
      if (outcome == null) {
        unwrapSync(await syncState.completeOp(claimed.id));
        completed++;
        continue;
      }
      // Queue-wide stops: a 429 pauses everything, not just this op
      // (retrying in lockstep is how a 429 becomes a sustained 429).
      if (outcome is CloudRateLimited || outcome is SyncAuthRequired) {
        return DrainReport(
          completed: completed,
          rescheduled: rescheduled,
          paused: true,
        );
      }
      if (outcome is RemoteObjectMissing &&
          claimed.opType == SyncQueueOpType.deleteRemote) {
        // Already gone remotely: the delete's goal is met (idempotent).
        unwrapSync(await syncState.completeOp(claimed.id));
        completed++;
        continue;
      }
      if (!retry.hasAttemptsLeft(claimed.attempts)) {
        // Dead-letter: keep the row for diagnosis but stop retrying.
        unwrapSync(
          await syncState.failOp(
            claimed.id,
            errorCode: outcome.code,
            retryAt: clock.now().add(const Duration(days: 3650)),
          ),
        );
        rescheduled++;
        continue;
      }
      final delay = retry.delayForAttempt(claimed.attempts, random);
      unwrapSync(
        await syncState.failOp(
          claimed.id,
          errorCode: outcome.code,
          retryAt: clock.now().add(delay),
        ),
      );
      rescheduled++;
    }
    return DrainReport(
      completed: completed,
      rescheduled: rescheduled,
      paused: false,
    );
  });

  /// Executes one claimed op. A null return means DONE; a failure means
  /// reschedule (or pause/dead-letter, decided by the caller).
  Future<VaultFailure?> _execute(
    SyncQueueItem item,
    CancellationToken? cancel,
  ) async {
    final result = await switch (item.opType) {
      SyncQueueOpType.uploadBlob => _uploadBlob(item, cancel),
      SyncQueueOpType.downloadBlob => _downloadBlob(item, cancel),
      SyncQueueOpType.deleteRemote => cloud.delete(item.targetId),
      SyncQueueOpType.appendLog ||
      SyncQueueOpType.fetchLog ||
      SyncQueueOpType.verifyRemote => Future<Result<void, VaultFailure>>.value(
        const Err(
          SyncTransportFailure(),
        ), // handled at the engine level, not the queue
      ),
    };
    return result.fold((_) => null, (failure) => failure);
  }

  /// Uploads a sealed blob byte-for-byte (§9.8). Idempotent: the remote
  /// name is deterministic and `put` of identical bytes is a no-op.
  Future<Result<void, VaultFailure>> _uploadBlob(
    SyncQueueItem item,
    CancellationToken? cancel,
  ) async {
    final blobId = item.targetId;
    final opened = await blobStore.openRead(blobId);
    if (opened.isErr) {
      // The file is gone locally: if it is already uploaded, the op is
      // done; otherwise it is unrecoverable locally — dead-letter it.
      return Err(opened.errOrNull!);
    }
    final handle = opened.okOrNull!;
    final existing = unwrapSync(await syncState.findCloudObject(blobId));
    final remoteName = existing?.remoteName ?? _remoteNameFor(blobId);
    unwrapSync(
      await syncState.upsertCloudObject(
        CloudObjectRecord(
          blobId: blobId,
          remoteName: remoteName,
          ciphertextSha256: existing?.ciphertextSha256 ?? '',
          keyEpoch: existing?.keyEpoch ?? 1,
          state: CloudObjectState.uploading,
        ),
      ),
    );
    final stream = blobStore.ciphertextStream(handle);
    if (stream == null) {
      return const Err(CorruptFile(''));
    }
    final put = await cloud.put(
      remoteName,
      stream,
      totalBytes: handle.plaintextSize ?? 0,
      resumeToken: item.resumeToken,
      cancel: cancel,
    );
    if (put.isErr) {
      return Err(put.errOrNull!);
    }
    final remote = put.okOrNull!;
    unwrapSync(
      await syncState.markCloudObjectState(
        blobId,
        CloudObjectState.uploaded,
        remoteId: remote.remoteId,
        uploadedAt: clock.now(),
      ),
    );
    return const Ok(null);
  }

  /// Downloads a blob the merge registered as REMOTE_ONLY (§9.8):
  /// streamed to a sealed local file, ciphertext hash verified BEFORE it
  /// becomes visible under the real blob path (T12).
  Future<Result<void, VaultFailure>> _downloadBlob(
    SyncQueueItem item,
    CancellationToken? cancel,
  ) async {
    final blobId = item.targetId;
    final record = unwrapSync(await syncState.findCloudObject(blobId));
    if (record == null || record.remoteId == null) {
      return Err(RemoteObjectMissing(blobId));
    }
    final got = await cloud.get(record.remoteId!);
    if (got.isErr) {
      return Err(got.errOrNull!);
    }
    final stored = await blobStore.writeSealed(
      blobId,
      got.okOrNull!,
      expectedCiphertextSha256: record.ciphertextSha256,
      cancel: cancel,
    );
    if (stored.isErr) {
      if (stored.errOrNull is RemoteObjectTampered) {
        unwrapSync(
          await syncState.markCloudObjectState(
            blobId,
            CloudObjectState.tampered,
          ),
        );
      }
      return Err(stored.errOrNull!);
    }
    unwrapSync(
      await syncState.markCloudObjectState(
        blobId,
        CloudObjectState.uploaded,
        verifiedAt: clock.now(),
      ),
    );
    return const Ok(null);
  }

  String _remoteNameFor(BlobId blobId) => 'b_$blobId.bin';
}
