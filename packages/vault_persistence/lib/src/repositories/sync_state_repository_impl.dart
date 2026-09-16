/// `SyncStateRepository` implementation over Drift (§6.4).
///
/// The local device's op log is buffered durably in `sync_log_ops`
/// (documented deviation) so a crash between "op accepted" and "segment
/// sealed+uploaded" loses nothing.
library;

import 'package:convert/convert.dart' show hex;
import 'package:drift/drift.dart';
import 'package:vault_domain/vault_domain.dart';

import '../daos/devices_dao.dart';
import '../daos/sync_dao.dart';
import '../daos/versions_dao.dart';
import '../database/app_database.dart';
import '../error_boundary.dart';

/// Drift-backed [SyncStateRepository].
final class SyncStateRepositoryImpl implements SyncStateRepository {
  SyncStateRepositoryImpl(this._db);

  final AppDatabase _db;

  SyncDao get _sync => _db.syncDao;
  DevicesDao get _devices => _db.devicesDao;
  VersionsDao get _versions => _db.versionsDao;

  // ── Devices ────────────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> ensureSelfDevice({
    required DeviceId id,
    required String label,
    required DateTime now,
  }) => guardDb(
    'ensureSelfDevice',
    () => _devices.upsertDeviceRow(
      DevicesCompanion.insert(
        id: id,
        label: Value(label),
        isSelf: const Value(true),
        createdAt: now,
      ),
      promoteToSelf: true,
    ),
  );

  @override
  Future<Result<void, VaultFailure>> upsertPeerDevice({
    required DeviceId id,
    required String label,
    required DateTime now,
  }) => guardDb(
    'upsertPeerDevice',
    () => _devices.upsertDeviceRow(
      DevicesCompanion.insert(
        id: id,
        label: Value(label),
        isSelf: const Value(false),
        createdAt: now,
      ),
      promoteToSelf: false,
    ),
  );

  @override
  Future<Result<List<DeviceRecord>, VaultFailure>> listDevices() =>
      guardDb('listDevices', () async {
        final rows = await _devices.allDevices();
        return rows.map(_deviceFrom).toList(growable: false);
      });

  @override
  Future<Result<void, VaultFailure>> updateDeviceCursor({
    required DeviceId id,
    required Hlc? lastSeenHlc,
    required DateTime? lastSyncedAt,
  }) => guardDb(
    'updateDeviceCursor',
    () => _devices.updateDeviceCursorRow(
      id,
      lastSeenHlc: lastSeenHlc?.toSortableString(),
      lastSyncedAt: lastSyncedAt,
    ),
  );

  // ── Queue ──────────────────────────────────────────────────────────────

  @override
  Future<Result<SyncQueueItem?, VaultFailure>> claimNext({
    required String workerId,
    required DateTime now,
    required Duration lease,
  }) => guardDb(
    'claimNext',
    () => _db.transaction(() async {
      final candidate = await _sync.nextPendingRow(now);
      if (candidate == null) {
        return null;
      }
      final claimed = await _sync.tryClaim(
        candidate.id,
        workerId,
        now.add(lease),
        candidate.attempts,
      );
      if (claimed == 0) {
        return null;
      }
      final row = await _sync.queueRowById(candidate.id);
      return row == null ? null : _itemFrom(row);
    }),
  );

  @override
  Future<Result<void, VaultFailure>> completeOp(int opId) =>
      guardDb('completeOp', () => _sync.completeQueueOp(opId));

  @override
  Future<Result<void, VaultFailure>> failOp(
    int opId, {
    required String errorCode,
    required DateTime retryAt,
    String? resumeToken,
  }) => guardDb('failOp', () async {
    final row = await _sync.queueRowById(opId);
    if (row == null) {
      throw PersistenceException(DatabaseFailure('failOp: no queue row $opId'));
    }
    await _sync.failQueueOp(
      opId,
      errorCode: errorCode,
      retryAt: retryAt,
      resumeToken: resumeToken,
      attempts: row.attempts,
    );
  });

  @override
  Future<Result<void, VaultFailure>> updateOpProgress(
    int opId, {
    required int bytesDone,
    int? bytesTotal,
    String? resumeToken,
  }) => guardDb(
    'updateOpProgress',
    () => _sync.updateQueueProgress(
      opId,
      bytesDone: bytesDone,
      bytesTotal: bytesTotal,
      resumeToken: resumeToken,
    ),
  );

  @override
  Future<Result<List<SyncQueueItem>, VaultFailure>> pendingOps() =>
      guardDb('pendingOps', () async {
        final rows = await _sync.pendingQueueRows();
        return rows.map(_itemFrom).toList(growable: false);
      });

  @override
  Future<Result<void, VaultFailure>> enqueueUploadBlob({
    required BlobId blobId,
    required String remoteName,
    required String idempotencyKey,
    required int priority,
    required DateTime now,
  }) => guardDb(
    'enqueueUploadBlob',
    () => _sync.insertQueueRow(
      SyncQueueCompanion.insert(
        opType: SyncQueueOpType.uploadBlob.dbValue,
        targetKind: 'BLOB',
        targetId: blobId,
        idempotencyKey: idempotencyKey,
        priority: Value(priority),
        nextAttemptAt: now,
        createdAt: now,
      ),
    ),
  );

  @override
  Future<Result<void, VaultFailure>> enqueueDeleteRemote({
    required String remoteId,
    required String idempotencyKey,
    required DateTime now,
  }) => guardDb(
    'enqueueDeleteRemote',
    () => _sync.insertQueueRow(
      SyncQueueCompanion.insert(
        opType: SyncQueueOpType.deleteRemote.dbValue,
        targetKind: 'BLOB',
        targetId: remoteId,
        idempotencyKey: idempotencyKey,
        nextAttemptAt: now,
        createdAt: now,
      ),
    ),
  );

  // ── Cloud objects ──────────────────────────────────────────────────────

  @override
  Future<Result<CloudObjectRecord?, VaultFailure>> findCloudObject(
    BlobId blobId,
  ) => guardDb('findCloudObject', () async {
    final row = await _sync.cloudObjectRow(blobId);
    return row == null ? null : _cloudFrom(row);
  });

  @override
  Future<Result<void, VaultFailure>> upsertCloudObject(
    CloudObjectRecord record,
  ) => guardDb(
    'upsertCloudObject',
    () => _sync.upsertCloudObjectRow(
      CloudObjectsCompanion.insert(
        blobId: record.blobId,
        remoteId: Value(record.remoteId),
        remoteName: record.remoteName,
        remoteSize: Value(record.remoteSize),
        ciphertextSha256: Uint8List.fromList(
          hex.decode(record.ciphertextSha256),
        ),
        keyEpoch: record.keyEpoch,
        state: record.state.dbValue,
        uploadedAt: Value(record.uploadedAt),
        verifiedAt: Value(record.verifiedAt),
      ),
    ),
  );

  @override
  Future<Result<void, VaultFailure>> markCloudObjectState(
    BlobId blobId,
    CloudObjectState state, {
    String? remoteId,
    DateTime? uploadedAt,
    DateTime? verifiedAt,
  }) => guardDb(
    'markCloudObjectState',
    () => _sync.updateCloudState(
      blobId,
      CloudObjectsCompanion(
        state: Value(state.dbValue),
        remoteId: remoteId == null ? const Value.absent() : Value(remoteId),
        uploadedAt: uploadedAt == null
            ? const Value.absent()
            : Value(uploadedAt),
        verifiedAt: verifiedAt == null
            ? const Value.absent()
            : Value(verifiedAt),
      ),
    ),
  );

  // ── Log segments ───────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> appendLogOp(
    SyncOp op, {
    required DateTime now,
  }) => guardDb('appendLogOp', () {
    final deviceId = op.origin;
    final hlc = op.hlc.toSortableString();
    final opJson = encodeSyncOp(op);
    return _db.transaction(() async {
      final openSegment = await _sync.openSegmentRow(deviceId);
      if (openSegment == null) {
        final seq = await _sync.maxSegmentSeq(deviceId) + 1;
        await _sync.insertSegmentRow(
          SyncLogSegmentsCompanion.insert(
            deviceId: deviceId,
            seq: seq,
            remoteName: _segmentRemoteName(deviceId, seq),
            opCount: const Value(1),
            hlcLow: Value(hlc),
            hlcHigh: Value(hlc),
          ),
        );
        await _sync.insertOpRow(
          SyncLogOpsCompanion.insert(
            deviceId: deviceId,
            opJson: opJson,
            hlc: hlc,
            seq: seq,
          ),
        );
      } else {
        await _sync.appendToOpenSegment(
          deviceId,
          hlcHigh: hlc,
          opCount: openSegment.opCount + 1,
        );
        await _sync.insertOpRow(
          SyncLogOpsCompanion.insert(
            deviceId: deviceId,
            opJson: opJson,
            hlc: hlc,
            seq: openSegment.seq,
          ),
        );
      }
    });
  });

  @override
  Future<Result<LogSegmentRecord?, VaultFailure>> openSegment(
    DeviceId deviceId,
  ) => guardDb('openSegment', () async {
    final row = await _sync.openSegmentRow(deviceId);
    return row == null ? null : _segmentFrom(row);
  });

  @override
  Future<Result<LogSegmentRecord, VaultFailure>> sealSegment({
    required DeviceId deviceId,
    required BlobRef blob,
    required int opCount,
    required String hlcLow,
    required String hlcHigh,
    required DateTime now,
  }) => guardDb(
    'sealSegment',
    () => _db.transaction(() async {
      final openSegment = await _sync.openSegmentRow(deviceId);
      if (openSegment == null) {
        throw PersistenceException(
          DatabaseFailure('sealSegment: no open segment for $deviceId'),
        );
      }
      await _versions.insertBlob(
        BlobsCompanion.insert(
          id: blob.id,
          storageClass: StorageClass.syncLog.dbValue,
          relPath: blob.relPath,
          envelopeVersion: Value(blob.envelopeVersion),
          keyEpoch: blob.keyEpoch,
          wrappedDek: Uint8List.fromList(blob.wrappedDek),
          ciphertextSize: blob.ciphertextSize,
          plaintextSize: blob.plaintextSize,
          ciphertextSha256: Uint8List.fromList(
            hex.decode(blob.ciphertextSha256),
          ),
          localState: 'PRESENT',
          createdAt: now,
        ),
      );
      await _sync.sealSegmentRow(
        deviceId,
        blobId: blob.id,
        opCount: opCount,
        hlcLow: hlcLow,
        hlcHigh: hlcHigh,
        now: now,
      );
      final sealed = await _sync.segmentRow(deviceId, openSegment.seq);
      if (sealed == null) {
        throw const PersistenceException(
          DatabaseFailure('sealSegment: segment row vanished'),
        );
      }
      return _segmentFrom(sealed);
    }),
  );

  @override
  Future<Result<List<LogSegmentRecord>, VaultFailure>> unuploadedSegments() =>
      guardDb('unuploadedSegments', () async {
        final rows = await _sync.sealedUnuploadedSegments();
        return rows.map(_segmentFrom).toList(growable: false);
      });

  @override
  Future<Result<void, VaultFailure>> markSegmentUploaded(
    int deviceSeq, {
    required DeviceId deviceId,
    required String remoteId,
    required DateTime now,
  }) => guardDb(
    'markSegmentUploaded',
    () => _sync.markSegmentUploadedRow(
      deviceId,
      deviceSeq,
      remoteId: remoteId,
      now: now,
    ),
  );

  @override
  Future<Result<List<LogSegmentRecord>, VaultFailure>> unappliedSegments() =>
      guardDb('unappliedSegments', () async {
        final rows = await _sync.unappliedSegments();
        return rows.map(_segmentFrom).toList(growable: false);
      });

  @override
  Future<Result<List<SyncOp>, VaultFailure>> segmentOps(
    LogSegmentRecord segment,
  ) => guardDb('segmentOps', () async {
    final rows = await _sync.opsForSegment(segment.deviceId, segment.seq);
    return rows.map((row) => decodeSyncOp(row.opJson)).toList(growable: false);
  });

  @override
  Future<Result<void, VaultFailure>> markSegmentApplied(
    LogSegmentRecord segment, {
    required DateTime now,
  }) => guardDb(
    'markSegmentApplied',
    () => _sync.markSegmentAppliedRow(segment.deviceId, segment.seq, now: now),
  );

  @override
  Future<Result<List<SyncOp>, VaultFailure>> openSegmentOps(
    DeviceId deviceId,
  ) => guardDb('openSegmentOps', () async {
    final openSegment = await _sync.openSegmentRow(deviceId);
    if (openSegment == null) {
      return const <SyncOp>[];
    }
    final rows = await _sync.opsForSegment(deviceId, openSegment.seq);
    return rows.map((row) => decodeSyncOp(row.opJson)).toList(growable: false);
  });

  // ── Cursors ────────────────────────────────────────────────────────────

  @override
  Future<Result<int, VaultFailure>> lastAppliedSeq(DeviceId deviceId) =>
      guardDb('lastAppliedSeq', () async {
        final row = await _sync.cursorRow(deviceId);
        return row?.lastAppliedSeq ?? 0;
      });

  @override
  Future<Result<void, VaultFailure>> setLastAppliedSeq(
    DeviceId deviceId,
    int seq, {
    required Hlc hlc,
  }) => guardDb(
    'setLastAppliedSeq',
    () => _sync.setCursorRow(
      SyncCursorCompanion.insert(
        deviceId: deviceId,
        lastAppliedSeq: Value(seq),
        lastAppliedHlc: Value(hlc.toSortableString()),
      ),
    ),
  );

  // ── Conflicts ──────────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> recordConflict(Conflict conflict) =>
      guardDb(
        'recordConflict',
        () => _sync.insertConflictRow(
          ConflictsCompanion.insert(
            id: conflict.id,
            entityKind: conflict.kind.dbValue,
            entityId: conflict.entityId,
            localStateJson: conflict.localStateJson,
            remoteStateJson: conflict.remoteStateJson,
            provisionalWinner: conflict.provisionalWinner.name.toUpperCase(),
            detectedAt: conflict.detectedAt,
            detectedHlc: conflict.detectedHlc.toSortableString(),
            resolvedAt: Value(conflict.resolvedAt),
            resolution: Value(conflict.resolution?.name.toUpperCase()),
            resolvedByDevice: Value(conflict.resolvedByDevice),
          ),
        ),
      );

  @override
  Future<Result<List<Conflict>, VaultFailure>> openConflicts() =>
      guardDb('openConflicts', () async {
        final rows = await _sync.openConflictRows();
        return rows.map(_conflictFrom).toList(growable: false);
      });

  @override
  Future<Result<List<Conflict>, VaultFailure>> conflictsFor(
    String entityId, {
    ConflictKind? kind,
  }) => guardDb('conflictsFor', () async {
    final rows = await _sync.conflictsForEntity(entityId, kind: kind?.dbValue);
    return rows.map(_conflictFrom).toList(growable: false);
  });

  @override
  Future<Result<void, VaultFailure>> resolveConflict(
    ConflictId id, {
    required ConflictResolution resolution,
    required DateTime at,
    required DeviceId byDevice,
  }) => guardDb(
    'resolveConflict',
    () => _sync.resolveConflictRow(
      id,
      resolution: resolution.name.toUpperCase(),
      at: at,
      byDevice: byDevice,
    ),
  );

  // ── Tombstones ─────────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> recordTombstone(Tombstone tombstone) =>
      guardDb(
        'recordTombstone',
        () => _sync.insertTombstoneRow(
          TombstonesCompanion.insert(
            entityKind: tombstone.entityKind.dbValue,
            entityId: tombstone.entityId,
            deletedHlc: tombstone.deletedHlc.toSortableString(),
            originDevice: tombstone.originDevice,
            purgeAfter: tombstone.purgeAfter,
          ),
        ),
      );

  @override
  Future<Result<Tombstone?, VaultFailure>> findTombstone(
    TombstoneEntityKind kind,
    String entityId,
  ) => guardDb('findTombstone', () async {
    final row = await _sync.tombstoneRow(kind.dbValue, entityId);
    return row == null ? null : _tombstoneFrom(row);
  });

  @override
  Future<Result<List<Tombstone>, VaultFailure>> expiredTombstones(
    DateTime now,
  ) => guardDb('expiredTombstones', () async {
    final rows = await _sync.expiredTombstoneRows(now);
    return rows.map(_tombstoneFrom).toList(growable: false);
  });

  @override
  Future<Result<void, VaultFailure>> purgeTombstone(
    TombstoneEntityKind kind,
    String entityId,
  ) => guardDb(
    'purgeTombstone',
    () => _sync.deleteTombstoneRow(kind.dbValue, entityId),
  );

  @override
  Future<Result<void, VaultFailure>> enqueueDownloadBlob({
    required BlobId blobId,
    required String remoteName,
    required String idempotencyKey,
    required int priority,
    required DateTime now,
  }) => guardDb(
    'enqueueDownloadBlob',
    () => _sync.insertQueueRow(
      SyncQueueCompanion.insert(
        opType: SyncQueueOpType.downloadBlob.dbValue,
        targetKind: 'BLOB',
        targetId: blobId,
        idempotencyKey: idempotencyKey,
        priority: Value(priority),
        nextAttemptAt: now,
        createdAt: now,
      ),
    ),
  );

  @override
  Future<Result<void, VaultFailure>> markBlobPresent(BlobId blobId) =>
      guardDb('markBlobPresent', () => _versions.markBlobPresentRow(blobId));

  // ── Remote segment registration ──────────────────────────────────────

  /// Inserts a remote segment row so [unappliedSegments] can see it.
  @override
  Future<Result<void, VaultFailure>> upsertRemoteSegment(
    LogSegmentRecord segment,
  ) => guardDb(
    'upsertRemoteSegment',
    () => _sync.insertSegmentRow(
      SyncLogSegmentsCompanion.insert(
        deviceId: segment.deviceId,
        seq: segment.seq,
        remoteId: Value(segment.remoteId),
        remoteName: segment.remoteName,
        blobId: Value(segment.blobId),
        opCount: Value(segment.opCount),
        hlcLow: Value(segment.hlcLow),
        hlcHigh: Value(segment.hlcHigh),
        sealedAt: Value(segment.sealedAt ?? segment.uploadedAt),
        uploadedAt: Value(segment.uploadedAt),
        appliedAt: Value(segment.appliedAt),
      ),
      mode: InsertMode.insertOrReplace,
    ),
  );

  // ── Internals ──────────────────────────────────────────────────────────

  SyncQueueItem _itemFrom(SyncQueueData row) => SyncQueueItem(
    id: row.id,
    opType: SyncQueueOpType.values.firstWhere(
      (type) => type.dbValue == row.opType,
      orElse: () => SyncQueueOpType.uploadBlob,
    ),
    targetKind: row.targetKind,
    targetId: row.targetId,
    idempotencyKey: row.idempotencyKey,
    priority: row.priority,
    state: SyncQueueState.values.firstWhere(
      (state) => state.dbValue == row.state,
      orElse: () => SyncQueueState.pending,
    ),
    attempts: row.attempts,
    nextAttemptAt: row.nextAttemptAt,
    createdAt: row.createdAt,
    lastErrorCode: row.lastErrorCode,
    resumeToken: row.resumeToken,
    bytesDone: row.bytesDone,
    bytesTotal: row.bytesTotal,
    leaseOwner: row.leaseOwner,
    leaseExpiresAt: row.leaseExpiresAt,
  );

  CloudObjectRecord _cloudFrom(CloudObjectData row) => CloudObjectRecord(
    blobId: row.blobId,
    remoteId: row.remoteId,
    remoteName: row.remoteName,
    ciphertextSha256: hex.encode(row.ciphertextSha256),
    keyEpoch: row.keyEpoch,
    state: CloudObjectState.values.firstWhere(
      (state) => state.dbValue == row.state,
      orElse: () => CloudObjectState.localOnly,
    ),
    remoteSize: row.remoteSize,
    uploadedAt: row.uploadedAt,
    verifiedAt: row.verifiedAt,
  );

  LogSegmentRecord _segmentFrom(SyncLogSegmentData row) => LogSegmentRecord(
    deviceId: row.deviceId,
    seq: row.seq,
    remoteName: row.remoteName,
    opCount: row.opCount,
    remoteId: row.remoteId,
    blobId: row.blobId,
    hlcLow: row.hlcLow,
    hlcHigh: row.hlcHigh,
    sealedAt: row.sealedAt,
    uploadedAt: row.uploadedAt,
    appliedAt: row.appliedAt,
  );

  DeviceRecord _deviceFrom(DeviceData row) => DeviceRecord(
    id: row.id,
    label: row.label ?? '',
    isSelf: row.isSelf,
    createdAt: row.createdAt,
    lastSeenHlc: row.lastSeenHlc == null ? null : Hlc.parse(row.lastSeenHlc!),
    lastSyncedAt: row.lastSyncedAt,
  );

  Conflict _conflictFrom(ConflictData row) => Conflict(
    id: row.id,
    kind: ConflictKind.fromDbValue(row.entityKind) ?? ConflictKind.assetCurrent,
    entityId: row.entityId,
    localStateJson: row.localStateJson,
    remoteStateJson: row.remoteStateJson,
    provisionalWinner: row.provisionalWinner.toLowerCase() == 'local'
        ? ConflictWinner.local
        : ConflictWinner.remote,
    detectedAt: row.detectedAt,
    detectedHlc: Hlc.parse(row.detectedHlc),
    resolvedAt: row.resolvedAt,
    resolution: row.resolution == null
        ? null
        : ConflictResolution.values.firstWhere(
            (r) => r.name == row.resolution!.toLowerCase(),
            orElse: () => ConflictResolution.auto,
          ),
    resolvedByDevice: row.resolvedByDevice,
  );

  Tombstone _tombstoneFrom(TombstoneData row) => Tombstone(
    entityKind: TombstoneEntityKind.fromDbValue(row.entityKind),
    entityId: row.entityId,
    deletedHlc: Hlc.parse(row.deletedHlc),
    originDevice: row.originDevice,
    purgeAfter: row.purgeAfter,
  );

  String _segmentRemoteName(String deviceId, int seq) {
    final short = deviceId.length <= 8 ? deviceId : deviceId.substring(0, 8);
    return 'l_${short}_${seq.toString().padLeft(7, '0')}.bin';
  }
}
