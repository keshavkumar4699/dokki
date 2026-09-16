/// DAO for the sync tables: `sync_queue`, `cloud_objects`,
/// `sync_log_segments`, `sync_log_ops`, `sync_cursor`, `conflicts`,
/// `tombstones`.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'sync_dao.g.dart';

@DriftAccessor(
  tables: [
    SyncQueue,
    CloudObjects,
    SyncLogSegments,
    SyncLogOps,
    SyncCursor,
    Conflicts,
    Tombstones,
  ],
)
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  // ── sync_queue ─────────────────────────────────────────────────────────

  Future<void> insertQueueRow(SyncQueueCompanion companion) =>
      into(syncQueue).insert(companion, mode: InsertMode.insertOrIgnore);

  Future<SyncQueueData?> nextPendingRow(DateTime now) {
    final query = select(syncQueue)
      ..where(
        (t) =>
            t.state.equals('PENDING') &
            t.nextAttemptAt.isSmallerOrEqualValue(now.millisecondsSinceEpoch),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.priority),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Conditional claim: only succeeds while the row is still PENDING.
  Future<int> tryClaim(
    int id,
    String workerId,
    DateTime leaseExpiresAt,
    int attempts,
  ) =>
      (update(
        syncQueue,
      )..where((t) => t.id.equals(id) & t.state.equals('PENDING'))).write(
        SyncQueueCompanion(
          state: const Value('INFLIGHT'),
          leaseOwner: Value(workerId),
          leaseExpiresAt: Value(leaseExpiresAt),
          attempts: Value(attempts + 1),
        ),
      );

  Future<SyncQueueData?> queueRowById(int id) =>
      (select(syncQueue)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> completeQueueOp(int id) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        const SyncQueueCompanion(
          state: Value('DONE'),
          leaseOwner: Value(null),
          leaseExpiresAt: Value(null),
        ),
      );

  Future<void> failQueueOp(
    int id, {
    required String errorCode,
    required DateTime retryAt,
    String? resumeToken,
    required int attempts,
  }) => (update(syncQueue)..where((t) => t.id.equals(id))).write(
    SyncQueueCompanion(
      state: const Value('PENDING'),
      nextAttemptAt: Value(retryAt),
      lastErrorCode: Value(errorCode),
      lastErrorAt: Value(retryAt),
      resumeToken: Value(resumeToken),
      attempts: Value(attempts + 1),
      leaseOwner: const Value(null),
      leaseExpiresAt: const Value(null),
    ),
  );

  Future<void> updateQueueProgress(
    int id, {
    required int bytesDone,
    int? bytesTotal,
    String? resumeToken,
  }) => (update(syncQueue)..where((t) => t.id.equals(id))).write(
    SyncQueueCompanion(
      bytesDone: Value(bytesDone),
      bytesTotal: Value(bytesTotal),
      resumeToken: Value(resumeToken),
    ),
  );

  Future<List<SyncQueueData>> pendingQueueRows() {
    final query = select(syncQueue)
      ..where((t) => t.state.equals('PENDING'))
      ..orderBy([
        (t) => OrderingTerm.asc(t.priority),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  // ── cloud_objects ──────────────────────────────────────────────────────

  Future<CloudObjectData?> cloudObjectRow(String blobId) => (select(
    cloudObjects,
  )..where((t) => t.blobId.equals(blobId))).getSingleOrNull();

  Future<void> upsertCloudObjectRow(CloudObjectsCompanion companion) =>
      into(cloudObjects).insert(companion, mode: InsertMode.insertOrReplace);

  Future<void> updateCloudState(
    String blobId,
    CloudObjectsCompanion companion,
  ) => (update(
    cloudObjects,
  )..where((t) => t.blobId.equals(blobId))).write(companion);

  // ── sync_log_segments / sync_log_ops ───────────────────────────────────

  Future<SyncLogSegmentData?> openSegmentRow(String deviceId) =>
      (select(syncLogSegments)
            ..where((t) => t.deviceId.equals(deviceId) & t.sealedAt.isNull()))
          .getSingleOrNull();

  Future<int> maxSegmentSeq(String deviceId) async {
    final seq = syncLogSegments.seq.max();
    final query = selectOnly(syncLogSegments)
      ..addColumns([seq])
      ..where(syncLogSegments.deviceId.equals(deviceId));
    final row = await query.getSingleOrNull();
    return row?.read(seq) ?? 0;
  }

  Future<void> insertSegmentRow(
    SyncLogSegmentsCompanion companion, {
    InsertMode mode = InsertMode.insert,
  }) => into(syncLogSegments).insert(companion, mode: mode);

  /// Appends one op to the open segment: bumps the HLC high-water mark and
  /// the op count.
  Future<void> appendToOpenSegment(
    String deviceId, {
    required String hlcHigh,
    required int opCount,
  }) =>
      (update(
        syncLogSegments,
      )..where((t) => t.deviceId.equals(deviceId) & t.sealedAt.isNull())).write(
        SyncLogSegmentsCompanion(
          hlcHigh: Value(hlcHigh),
          opCount: Value(opCount),
        ),
      );

  Future<void> sealSegmentRow(
    String deviceId, {
    required String blobId,
    required int opCount,
    required String hlcLow,
    required String hlcHigh,
    required DateTime now,
  }) =>
      (update(
        syncLogSegments,
      )..where((t) => t.deviceId.equals(deviceId) & t.sealedAt.isNull())).write(
        SyncLogSegmentsCompanion(
          blobId: Value(blobId),
          opCount: Value(opCount),
          hlcLow: Value(hlcLow),
          hlcHigh: Value(hlcHigh),
          sealedAt: Value(now),
        ),
      );

  Future<SyncLogSegmentData?> segmentRow(String deviceId, int seq) =>
      (select(syncLogSegments)
            ..where((t) => t.deviceId.equals(deviceId) & t.seq.equals(seq)))
          .getSingleOrNull();

  Future<List<SyncLogSegmentData>> sealedUnuploadedSegments() {
    final query = select(syncLogSegments)
      ..where((t) => t.sealedAt.isNotNull() & t.uploadedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.deviceId),
        (t) => OrderingTerm.asc(t.seq),
      ]);
    return query.get();
  }

  Future<void> markSegmentUploadedRow(
    String deviceId,
    int seq, {
    required String remoteId,
    required DateTime now,
  }) =>
      (update(
        syncLogSegments,
      )..where((t) => t.deviceId.equals(deviceId) & t.seq.equals(seq))).write(
        SyncLogSegmentsCompanion(
          remoteId: Value(remoteId),
          uploadedAt: Value(now),
        ),
      );

  Future<List<SyncLogSegmentData>> unappliedSegments() {
    final query = select(syncLogSegments)
      ..where((t) => t.blobId.isNotNull() & t.appliedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.deviceId),
        (t) => OrderingTerm.asc(t.seq),
      ]);
    return query.get();
  }

  Future<void> markSegmentAppliedRow(
    String deviceId,
    int seq, {
    required DateTime now,
  }) =>
      (update(syncLogSegments)
            ..where((t) => t.deviceId.equals(deviceId) & t.seq.equals(seq)))
          .write(SyncLogSegmentsCompanion(appliedAt: Value(now)));

  Future<void> insertOpRow(SyncLogOpsCompanion companion) =>
      into(syncLogOps).insert(companion);

  /// Ops of one segment, HLC-sorted.
  Future<List<SyncLogOpData>> opsForSegment(String deviceId, int seq) {
    final query = select(syncLogOps)
      ..where((t) => t.deviceId.equals(deviceId) & t.seq.equals(seq))
      ..orderBy([
        (t) => OrderingTerm.asc(t.hlc),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  // ── sync_cursor ────────────────────────────────────────────────────────

  Future<SyncCursorData?> cursorRow(String deviceId) => (select(
    syncCursor,
  )..where((t) => t.deviceId.equals(deviceId))).getSingleOrNull();

  Future<void> setCursorRow(SyncCursorCompanion companion) =>
      into(syncCursor).insert(companion, mode: InsertMode.insertOrReplace);

  // ── conflicts ──────────────────────────────────────────────────────────

  Future<void> insertConflictRow(ConflictsCompanion companion) =>
      into(conflicts).insert(companion, mode: InsertMode.insertOrIgnore);

  Future<ConflictData?> conflictRowById(String id) =>
      (select(conflicts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ConflictData>> openConflictRows() {
    final query = select(conflicts)
      ..where((t) => t.resolvedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.detectedAt)]);
    return query.get();
  }

  Future<List<ConflictData>> conflictsForEntity(
    String entityId, {
    String? kind,
  }) {
    final query = select(conflicts)
      ..where((t) => t.entityId.equals(entityId) & t.resolvedAt.isNull());
    if (kind != null) {
      query.where((t) => t.entityKind.equals(kind));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.detectedAt)]);
    return query.get();
  }

  Future<bool> hasOpenConflict(String entityId, {String? kind}) async {
    final query = selectOnly(conflicts)
      ..addColumns([conflicts.id.count()])
      ..where(
        conflicts.entityId.equals(entityId) & conflicts.resolvedAt.isNull(),
      );
    if (kind != null) {
      query.where(conflicts.entityKind.equals(kind));
    }
    final row = await query.getSingle();
    return row.read(conflicts.id.count())! > 0;
  }

  Future<void> resolveConflictRow(
    String id, {
    required String resolution,
    required DateTime at,
    required String byDevice,
  }) =>
      (update(
        conflicts,
      )..where((t) => t.id.equals(id) & t.resolvedAt.isNull())).write(
        ConflictsCompanion(
          resolution: Value(resolution),
          resolvedAt: Value(at),
          resolvedByDevice: Value(byDevice),
        ),
      );

  // ── tombstones ─────────────────────────────────────────────────────────

  Future<void> insertTombstoneRow(TombstonesCompanion companion) =>
      into(tombstones).insert(companion, mode: InsertMode.insertOrReplace);

  Future<TombstoneData?> tombstoneRow(String entityKind, String entityId) =>
      (select(tombstones)..where(
            (t) =>
                t.entityKind.equals(entityKind) & t.entityId.equals(entityId),
          ))
          .getSingleOrNull();

  Future<List<TombstoneData>> expiredTombstoneRows(DateTime now) {
    final query = select(tombstones)
      ..where(
        (t) => t.purgeAfter.isSmallerOrEqualValue(now.millisecondsSinceEpoch),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.purgeAfter)]);
    return query.get();
  }

  Future<void> deleteTombstoneRow(String entityKind, String entityId) =>
      (delete(tombstones)..where(
            (t) =>
                t.entityKind.equals(entityKind) & t.entityId.equals(entityId),
          ))
          .go();
}
