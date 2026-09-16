/// `SyncStateRepository`: the persistence surface the sync engine needs
/// (§3 rule 3, §6.4).
///
/// `vault_sync` never imports Drift. Everything it must read or write —
/// queue rows, log segments, cursors, conflicts, tombstones, cloud-object
/// pointers, devices — goes through this port, implemented by
/// `vault_persistence`.
library;

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';
import '../sync/conflict.dart';
import '../sync/hlc.dart';
import '../sync/sync_op.dart';
import '../sync/tombstone.dart';
import 'blob_store.dart';
import 'sync_queue_port.dart';

enum SyncQueueState {
  pending('PENDING'),
  inflight('INFLIGHT'),
  done('DONE'),
  failed('FAILED'),
  dead('DEAD');

  const SyncQueueState(this.dbValue);

  final String dbValue;
}

/// One row of `sync_queue` (§6.4).
final class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.opType,
    required this.targetKind,
    required this.targetId,
    required this.idempotencyKey,
    required this.priority,
    required this.state,
    required this.attempts,
    required this.nextAttemptAt,
    required this.createdAt,
    this.lastErrorCode,
    this.resumeToken,
    this.bytesDone,
    this.bytesTotal,
    this.leaseOwner,
    this.leaseExpiresAt,
  });

  final int id;
  final SyncQueueOpType opType;
  final String targetKind;
  final String targetId;
  final String idempotencyKey;
  final int priority;
  final SyncQueueState state;
  final int attempts;
  final DateTime nextAttemptAt;
  final DateTime createdAt;
  final String? lastErrorCode;
  final String? resumeToken;
  final int? bytesDone;
  final int? bytesTotal;
  final String? leaseOwner;
  final DateTime? leaseExpiresAt;
}

enum CloudObjectState {
  localOnly('LOCAL_ONLY'),
  uploading('UPLOADING'),
  uploaded('UPLOADED'),
  remoteOnly('REMOTE_ONLY'),
  missing('MISSING'),
  tampered('TAMPERED');

  const CloudObjectState(this.dbValue);

  final String dbValue;
}

/// One row of `cloud_objects` (§6.4).
final class CloudObjectRecord {
  const CloudObjectRecord({
    required this.blobId,
    required this.remoteName,
    required this.ciphertextSha256,
    required this.keyEpoch,
    required this.state,
    this.remoteId,
    this.remoteSize,
    this.uploadedAt,
    this.verifiedAt,
  });

  final BlobId blobId;
  final String? remoteId;
  final String remoteName;
  final String ciphertextSha256;
  final int keyEpoch;
  final CloudObjectState state;
  final int? remoteSize;
  final DateTime? uploadedAt;
  final DateTime? verifiedAt;
}

/// One row of `sync_log_segments` (§6.4).
final class LogSegmentRecord {
  const LogSegmentRecord({
    required this.deviceId,
    required this.seq,
    required this.remoteName,
    required this.opCount,
    this.remoteId,
    this.blobId,
    this.hlcLow,
    this.hlcHigh,
    this.sealedAt,
    this.uploadedAt,
    this.appliedAt,
  });

  final DeviceId deviceId;
  final int seq;
  final String remoteName;
  final int opCount;
  final String? remoteId;

  /// The sealed segment blob (present once sealed).
  final BlobId? blobId;

  final String? hlcLow;
  final String? hlcHigh;

  /// `null` = still being appended to locally.
  final DateTime? sealedAt;

  final DateTime? uploadedAt;

  /// `null` = fetched but not yet replayed.
  final DateTime? appliedAt;
}

/// One row of `devices` (§6.1).
final class DeviceRecord {
  const DeviceRecord({
    required this.id,
    required this.label,
    required this.isSelf,
    required this.createdAt,
    this.lastSeenHlc,
    this.lastSyncedAt,
  });

  final DeviceId id;
  final String label;
  final bool isSelf;
  final DateTime createdAt;
  final Hlc? lastSeenHlc;
  final DateTime? lastSyncedAt;
}

abstract interface class SyncStateRepository {
  // ── Devices ────────────────────────────────────────────────────────────

  Future<Result<void, VaultFailure>> ensureSelfDevice({
    required DeviceId id,
    required String label,
    required DateTime now,
  });

  Future<Result<void, VaultFailure>> upsertPeerDevice({
    required DeviceId id,
    required String label,
    required DateTime now,
  });

  Future<Result<List<DeviceRecord>, VaultFailure>> listDevices();

  Future<Result<void, VaultFailure>> updateDeviceCursor({
    required DeviceId id,
    required Hlc? lastSeenHlc,
    required DateTime? lastSyncedAt,
  });

  // ── Queue ──────────────────────────────────────────────────────────────

  /// Claims one ready op with a lease (§9.7). Conditional UPDATE inside a
  /// transaction, so two workers can never process the same op.
  Future<Result<SyncQueueItem?, VaultFailure>> claimNext({
    required String workerId,
    required DateTime now,
    required Duration lease,
  });

  Future<Result<void, VaultFailure>> completeOp(int opId);

  Future<Result<void, VaultFailure>> failOp(
    int opId, {
    required String errorCode,
    required DateTime retryAt,
    String? resumeToken,
  });

  Future<Result<void, VaultFailure>> updateOpProgress(
    int opId, {
    required int bytesDone,
    int? bytesTotal,
    String? resumeToken,
  });

  Future<Result<List<SyncQueueItem>, VaultFailure>> pendingOps();

  Future<Result<void, VaultFailure>> enqueueUploadBlob({
    required BlobId blobId,
    required String remoteName,
    required String idempotencyKey,
    required int priority,
    required DateTime now,
  });

  Future<Result<void, VaultFailure>> enqueueDeleteRemote({
    required String remoteId,
    required String idempotencyKey,
    required DateTime now,
  });

  // ── Cloud objects ──────────────────────────────────────────────────────

  Future<Result<CloudObjectRecord?, VaultFailure>> findCloudObject(
    BlobId blobId,
  );

  Future<Result<void, VaultFailure>> upsertCloudObject(
    CloudObjectRecord record,
  );

  Future<Result<void, VaultFailure>> markCloudObjectState(
    BlobId blobId,
    CloudObjectState state, {
    String? remoteId,
    DateTime? uploadedAt,
    DateTime? verifiedAt,
  });

  // ── Log segments ───────────────────────────────────────────────────────

  /// Appends [op] to the local device's open segment. The caller (sync
  /// engine) seals and uploads segments; this persists the op durably.
  Future<Result<void, VaultFailure>> appendLogOp(
    SyncOp op, {
    required DateTime now,
  });

  /// The current open (unsealed) segment for [deviceId], if any.
  Future<Result<LogSegmentRecord?, VaultFailure>> openSegment(
    DeviceId deviceId,
  );

  /// Seals the open segment: persists the sealed [blob], op count, HLC
  /// range. The blob has already been written by the `BlobStore`.
  Future<Result<LogSegmentRecord, VaultFailure>> sealSegment({
    required DeviceId deviceId,
    required BlobRef blob,
    required int opCount,
    required String hlcLow,
    required String hlcHigh,
    required DateTime now,
  });

  Future<Result<List<LogSegmentRecord>, VaultFailure>> unuploadedSegments();

  Future<Result<void, VaultFailure>> markSegmentUploaded(
    int deviceSeq, {
    required DeviceId deviceId,
    required String remoteId,
    required DateTime now,
  });

  Future<Result<List<LogSegmentRecord>, VaultFailure>> unappliedSegments();

  /// Ops of a segment, HLC-sorted.
  Future<Result<List<SyncOp>, VaultFailure>> segmentOps(
    LogSegmentRecord segment,
  );

  Future<Result<void, VaultFailure>> markSegmentApplied(
    LogSegmentRecord segment, {
    required DateTime now,
  });

  /// The current local segment's unsealed ops (for crash recovery).
  Future<Result<List<SyncOp>, VaultFailure>> openSegmentOps(DeviceId deviceId);

  // ── Cursors ────────────────────────────────────────────────────────────

  Future<Result<int, VaultFailure>> lastAppliedSeq(DeviceId deviceId);

  Future<Result<void, VaultFailure>> setLastAppliedSeq(
    DeviceId deviceId,
    int seq, {
    required Hlc hlc,
  });

  // ── Conflicts ──────────────────────────────────────────────────────────

  Future<Result<void, VaultFailure>> recordConflict(Conflict conflict);

  Future<Result<List<Conflict>, VaultFailure>> openConflicts();

  Future<Result<List<Conflict>, VaultFailure>> conflictsFor(
    String entityId, {
    ConflictKind? kind,
  });

  Future<Result<void, VaultFailure>> resolveConflict(
    ConflictId id, {
    required ConflictResolution resolution,
    required DateTime at,
    required DeviceId byDevice,
  });

  // ── Tombstones ─────────────────────────────────────────────────────────

  Future<Result<void, VaultFailure>> recordTombstone(Tombstone tombstone);

  Future<Result<Tombstone?, VaultFailure>> findTombstone(
    TombstoneEntityKind kind,
    String entityId,
  );

  Future<Result<List<Tombstone>, VaultFailure>> expiredTombstones(DateTime now);

  Future<Result<void, VaultFailure>> purgeTombstone(
    TombstoneEntityKind kind,
    String entityId,
  );
}
