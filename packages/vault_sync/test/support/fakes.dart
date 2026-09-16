/// In-memory doubles for the sync engine's ports (§13.6): an
/// `InMemorySyncState`, a `FakeCloudProvider` with scripted chaos, and an
/// `InMemoryApplyPort`. Deterministic; zero I/O.
library;

import 'dart:convert';

import 'package:vault_domain/vault_domain.dart';

// ── Determinism primitives ───────────────────────────────────────────────

final class FakeClock implements Clock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime.utc(2026);

  DateTime _now;

  void advance(Duration by) => _now = _now.add(by);

  @override
  DateTime now() => _now;
}

final class SequenceIds implements IdGenerator {
  int _n = 0;

  @override
  String newEntityId() => 'e${(++_n).toString().padLeft(3, '0')}';

  @override
  String newBlobId() => 'b${(++_n).toString().padLeft(3, '0')}';
}

final class SeededRandom implements RandomSource {
  int _seed = 7;

  @override
  void fillBytes(List<int> out) {
    for (var i = 0; i < out.length; i++) {
      out[i] = nextInt(256);
    }
  }

  @override
  int nextInt(int max) =>
      (_seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF) % max;
}

// ── CloudProvider ────────────────────────────────────────────────────────

/// An in-memory cloud with injectable failure modes. Objects live in a
/// flat map keyed by remote id; `put` is idempotent by name (§9.3).
final class FakeCloudProvider implements CloudProvider {
  final Map<String, ({String name, List<int> bytes})> objects = {};
  final List<List<int>> putPayloads = [];
  int _nextId = 0;

  /// Failures consumed one per cloud call, in order.
  final List<VaultFailure> script = [];

  /// When non-null, every `list` returns this.
  VaultFailure? listFailure;

  /// Byte corruption applied to every `get` payload (T12 simulation).
  bool corruptDownloads = false;

  VaultFailure? _nextFailure() =>
      script.isEmpty ? null : script.removeAt(0);

  @override
  String get providerId => 'fake';

  @override
  Future<Result<CloudAuthState, VaultFailure>> authState() async =>
      const Ok(CloudAuthState.signedIn);

  @override
  Future<Result<void, VaultFailure>> ensureAuthorized() async =>
      const Ok(null);

  @override
  Future<Result<RemoteObject, VaultFailure>> put(
    String opaqueName,
    Stream<List<int>> ciphertext, {
    required int totalBytes,
    Map<String, String> routingProps = const {},
    String? resumeToken,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final failure = _nextFailure();
    if (failure != null) {
      return Err(failure);
    }
    final bytes = <int>[];
    await for (final chunk in ciphertext) {
      cancel?.throwIfCancelled();
      bytes.addAll(chunk);
    }
    putPayloads.add(bytes);
    final existing = objects.entries
        .where((e) => e.value.name == opaqueName)
        .firstOrNull;
    if (existing != null) {
      // Idempotent by name (§9.3): identical re-upload is a no-op.
      return Ok(
        RemoteObject(
          remoteId: existing.key,
          name: opaqueName,
          sizeBytes: bytes.length,
        ),
      );
    }
    final id = 'remote-${++_nextId}';
    objects[id] = (name: opaqueName, bytes: bytes);
    return Ok(RemoteObject(remoteId: id, name: opaqueName, sizeBytes: bytes.length));
  }

  @override
  Future<Result<Stream<List<int>>, VaultFailure>> get(
    String remoteId, {
    ByteRange? range,
  }) async {
    final failure = _nextFailure();
    if (failure != null) {
      return Err(failure);
    }
    final object = objects[remoteId];
    if (object == null) {
      return Err(RemoteObjectMissing(remoteId));
    }
    var bytes = object.bytes;
    if (corruptDownloads && bytes.isNotEmpty) {
      bytes = [...bytes]..[bytes.length ~/ 2] = bytes[bytes.length ~/ 2] ^ 0xFF;
    }
    return Ok(Stream.value(bytes));
  }

  @override
  Future<Result<List<RemoteObject>, VaultFailure>> list({
    String? namePrefix,
    String? pageToken,
  }) async {
    final failure = listFailure;
    if (failure != null) {
      return Err(failure);
    }
    return Ok([
      for (final entry in objects.entries)
        if (namePrefix == null || entry.value.name.startsWith(namePrefix))
          RemoteObject(
            remoteId: entry.key,
            name: entry.value.name,
            sizeBytes: entry.value.bytes.length,
          ),
    ]);
  }

  @override
  Future<Result<void, VaultFailure>> delete(String remoteId) async {
    final failure = _nextFailure();
    if (failure != null) {
      return Err(failure);
    }
    if (objects.remove(remoteId) == null) {
      return Err(RemoteObjectMissing(remoteId));
    }
    return const Ok(null);
  }

  @override
  Future<Result<CloudQuota, VaultFailure>> quota() async =>
      const Ok(CloudQuota());
}

// ── SyncStateRepository ──────────────────────────────────────────────────

final class FakeQueueRow {
  FakeQueueRow({
    required this.id,
    required this.opType,
    required this.targetId,
    required this.idempotencyKey,
    required this.priority,
    required this.nextAttemptAt,
    required this.createdAt,
  });

  final int id;
  final SyncQueueOpType opType;
  final String targetId;
  final String idempotencyKey;
  final int priority;
  DateTime nextAttemptAt;
  final DateTime createdAt;
  int attempts = 0;
  bool done = false;
  String? leaseOwner;
  String? lastErrorCode;
  String? resumeToken;
}

/// In-memory `SyncStateRepository`: queue rows, cloud objects, segments,
/// ops, cursors, conflicts, tombstones, devices.
final class InMemorySyncState implements SyncStateRepository {
  final List<FakeQueueRow> queue = [];
  final Map<String, CloudObjectRecord> cloudObjects = {};
  final Map<(String, int), LogSegmentRecord> segments = {};
  final Map<(String, int), List<SyncOp>> segmentOpsStore = {};
  final Map<String, int> cursors = {};
  final Map<String, Conflict> conflicts = {};
  final Map<(String, String), Tombstone> tombstones = {};
  final Map<String, DeviceRecord> devices = {};
  int _nextQueueId = 1;

  // ── Devices ──
  @override
  Future<Result<void, VaultFailure>> ensureSelfDevice({
    required DeviceId id,
    required String label,
    required DateTime now,
  }) async {
    devices[id] = DeviceRecord(
      id: id,
      label: label,
      isSelf: true,
      createdAt: now,
    );
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> upsertPeerDevice({
    required DeviceId id,
    required String label,
    required DateTime now,
  }) async {
    devices.putIfAbsent(
      id,
      () => DeviceRecord(
        id: id,
        label: label,
        isSelf: false,
        createdAt: now,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<List<DeviceRecord>, VaultFailure>> listDevices() async =>
      Ok(devices.values.toList());

  @override
  Future<Result<void, VaultFailure>> updateDeviceCursor({
    required DeviceId id,
    required Hlc? lastSeenHlc,
    required DateTime? lastSyncedAt,
  }) async => const Ok(null);

  // ── Queue ──
  @override
  Future<Result<SyncQueueItem?, VaultFailure>> claimNext({
    required String workerId,
    required DateTime now,
    required Duration lease,
  }) async {
    final ready = queue
        .where(
          (r) =>
              !r.done &&
              r.leaseOwner == null &&
              !r.nextAttemptAt.isAfter(now),
        )
        .toList()
      ..sort((a, b) {
        final byPriority = a.priority.compareTo(b.priority);
        return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
      });
    if (ready.isEmpty) {
      return const Ok(null);
    }
    final row = ready.first..leaseOwner = workerId;
    return Ok(_item(row));
  }

  SyncQueueItem _item(FakeQueueRow r) => SyncQueueItem(
    id: r.id,
    opType: r.opType,
    targetKind: 'BLOB',
    targetId: r.targetId,
    idempotencyKey: r.idempotencyKey,
    priority: r.priority,
    state: SyncQueueState.pending,
    attempts: r.attempts,
    nextAttemptAt: r.nextAttemptAt,
    createdAt: r.createdAt,
    lastErrorCode: r.lastErrorCode,
    resumeToken: r.resumeToken,
  );

  @override
  Future<Result<void, VaultFailure>> completeOp(int opId) async {
    queue.firstWhere((r) => r.id == opId).done = true;
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> failOp(
    int opId, {
    required String errorCode,
    required DateTime retryAt,
    String? resumeToken,
  }) async {
    queue.firstWhere((r) => r.id == opId)
      ..nextAttemptAt = retryAt
      ..lastErrorCode = errorCode
      ..resumeToken = resumeToken
      ..leaseOwner = null
      ..attempts += 1;
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> updateOpProgress(
    int opId, {
    required int bytesDone,
    int? bytesTotal,
    String? resumeToken,
  }) async => const Ok(null);

  @override
  Future<Result<List<SyncQueueItem>, VaultFailure>> pendingOps() async =>
      Ok([for (final r in queue.where((r) => !r.done)) _item(r)]);

  @override
  Future<Result<void, VaultFailure>> enqueueUploadBlob({
    required BlobId blobId,
    required String remoteName,
    required String idempotencyKey,
    required int priority,
    required DateTime now,
  }) async {
    if (queue.any((r) => r.idempotencyKey == idempotencyKey)) {
      return const Ok(null); // unique idempotency key (§6.4)
    }
    queue.add(
      FakeQueueRow(
        id: _nextQueueId++,
        opType: SyncQueueOpType.uploadBlob,
        targetId: blobId,
        idempotencyKey: idempotencyKey,
        priority: priority,
        nextAttemptAt: now,
        createdAt: now,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> enqueueDownloadBlob({
    required BlobId blobId,
    required String remoteName,
    required String idempotencyKey,
    required int priority,
    required DateTime now,
  }) async {
    if (queue.any((r) => r.idempotencyKey == idempotencyKey)) {
      return const Ok(null);
    }
    queue.add(
      FakeQueueRow(
        id: _nextQueueId++,
        opType: SyncQueueOpType.downloadBlob,
        targetId: blobId,
        idempotencyKey: idempotencyKey,
        priority: priority,
        nextAttemptAt: now,
        createdAt: now,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> enqueueDeleteRemote({
    required String remoteId,
    required String idempotencyKey,
    required DateTime now,
  }) async {
    queue.add(
      FakeQueueRow(
        id: _nextQueueId++,
        opType: SyncQueueOpType.deleteRemote,
        targetId: remoteId,
        idempotencyKey: idempotencyKey,
        priority: 100,
        nextAttemptAt: now,
        createdAt: now,
      ),
    );
    return const Ok(null);
  }

  // ── Cloud objects ──
  @override
  Future<Result<CloudObjectRecord?, VaultFailure>> findCloudObject(
    BlobId blobId,
  ) async => Ok(cloudObjects[blobId]);

  @override
  Future<Result<void, VaultFailure>> upsertCloudObject(
    CloudObjectRecord record,
  ) async {
    cloudObjects[record.blobId] = record;
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> markCloudObjectState(
    BlobId blobId,
    CloudObjectState state, {
    String? remoteId,
    DateTime? uploadedAt,
    DateTime? verifiedAt,
  }) async {
    final existing = cloudObjects[blobId];
    if (existing != null) {
      cloudObjects[blobId] = CloudObjectRecord(
        blobId: blobId,
        remoteName: existing.remoteName,
        ciphertextSha256: existing.ciphertextSha256,
        keyEpoch: existing.keyEpoch,
        state: state,
        remoteId: remoteId ?? existing.remoteId,
        uploadedAt: uploadedAt ?? existing.uploadedAt,
        verifiedAt: verifiedAt ?? existing.verifiedAt,
      );
    }
    return const Ok(null);
  }

  // ── Segments ──
  @override
  Future<Result<void, VaultFailure>> appendLogOp(
    SyncOp op, {
    required DateTime now,
  }) async {
    final key = (op.origin, _openSeq(op.origin));
    segmentOpsStore.putIfAbsent(key, () => []).add(op);
    final existing = segments[key];
    final short = op.origin.length <= 8
        ? op.origin
        : op.origin.substring(0, 8);
    if (existing == null) {
      segments[key] = LogSegmentRecord(
        deviceId: op.origin,
        seq: key.$2,
        remoteName: 'l_${short}_${key.$2.toString().padLeft(7, '0')}.bin',
        opCount: 1,
        hlcLow: op.hlc.toSortableString(),
        hlcHigh: op.hlc.toSortableString(),
      );
    } else {
      segments[key] = LogSegmentRecord(
        deviceId: op.origin,
        seq: key.$2,
        remoteName: existing.remoteName,
        opCount: existing.opCount + 1,
        hlcLow: existing.hlcLow,
        hlcHigh: op.hlc.toSortableString(),
      );
    }
    return const Ok(null);
  }

  int _openSeq(DeviceId deviceId) {
    var max = 0;
    for (final key in segments.keys) {
      if (key.$1 == deviceId && key.$2 > max) {
        final record = segments[key]!;
        if (record.sealedAt == null) {
          max = key.$2;
        } else if (key.$2 >= max) {
          max = key.$2 + 1;
        }
      }
    }
    return max == 0 ? 1 : max;
  }

  @override
  Future<Result<LogSegmentRecord?, VaultFailure>> openSegment(
    DeviceId deviceId,
  ) async {
    for (final entry in segments.entries) {
      if (entry.key.$1 == deviceId && entry.value.sealedAt == null) {
        return Ok(entry.value);
      }
    }
    return const Ok(null);
  }

  @override
  Future<Result<LogSegmentRecord, VaultFailure>> sealSegment({
    required DeviceId deviceId,
    required BlobRef blob,
    required int opCount,
    required String hlcLow,
    required String hlcHigh,
    required DateTime now,
  }) async {
    final open = (await openSegment(deviceId)).okOrNull!;
    final key = (deviceId, open.seq);
    segments[key] = LogSegmentRecord(
      deviceId: deviceId,
      seq: open.seq,
      remoteName: open.remoteName,
      remoteId: open.remoteId,
      blobId: blob.id,
      opCount: opCount,
      hlcLow: hlcLow,
      hlcHigh: hlcHigh,
      sealedAt: now,
    );
    return Ok(segments[key]!);
  }

  @override
  Future<Result<List<LogSegmentRecord>, VaultFailure>>
  unuploadedSegments() async => Ok([
    for (final record in segments.values)
      if (record.sealedAt != null && record.uploadedAt == null) record,
  ]);

  @override
  Future<Result<void, VaultFailure>> markSegmentUploaded(
    int deviceSeq, {
    required DeviceId deviceId,
    required String remoteId,
    required DateTime now,
  }) async {
    final key = (deviceId, deviceSeq);
    final existing = segments[key]!;
    segments[key] = LogSegmentRecord(
      deviceId: deviceId,
      seq: deviceSeq,
      remoteName: existing.remoteName,
      remoteId: remoteId,
      blobId: existing.blobId,
      opCount: existing.opCount,
      hlcLow: existing.hlcLow,
      hlcHigh: existing.hlcHigh,
      sealedAt: existing.sealedAt,
      uploadedAt: now,
    );
    return const Ok(null);
  }

  @override
  Future<Result<List<LogSegmentRecord>, VaultFailure>>
  unappliedSegments() async {
    final list = [
      for (final record in segments.values)
        if (record.blobId != null && record.appliedAt == null) record,
    ]..sort((a, b) {
      final byDevice = a.deviceId.compareTo(b.deviceId);
      return byDevice != 0 ? byDevice : a.seq.compareTo(b.seq);
    });
    return Ok(list);
  }

  @override
  Future<Result<List<SyncOp>, VaultFailure>> segmentOps(
    LogSegmentRecord segment,
  ) async => Ok(segmentOpsStore[(segment.deviceId, segment.seq)] ?? []);

  @override
  Future<Result<void, VaultFailure>> markSegmentApplied(
    LogSegmentRecord segment, {
    required DateTime now,
  }) async {
    final key = (segment.deviceId, segment.seq);
    final existing = segments[key]!;
    segments[key] = LogSegmentRecord(
      deviceId: existing.deviceId,
      seq: existing.seq,
      remoteName: existing.remoteName,
      remoteId: existing.remoteId,
      blobId: existing.blobId,
      opCount: existing.opCount,
      hlcLow: existing.hlcLow,
      hlcHigh: existing.hlcHigh,
      sealedAt: existing.sealedAt,
      uploadedAt: existing.uploadedAt,
      appliedAt: now,
    );
    return const Ok(null);
  }

  @override
  Future<Result<List<SyncOp>, VaultFailure>> openSegmentOps(
    DeviceId deviceId,
  ) async {
    final open = (await openSegment(deviceId)).okOrNull;
    if (open == null) {
      return const Ok([]);
    }
    return Ok(segmentOpsStore[(deviceId, open.seq)] ?? []);
  }

  // ── Cursors ──
  @override
  Future<Result<int, VaultFailure>> lastAppliedSeq(DeviceId deviceId) async =>
      Ok(cursors[deviceId] ?? 0);

  @override
  Future<Result<void, VaultFailure>> setLastAppliedSeq(
    DeviceId deviceId,
    int seq, {
    required Hlc hlc,
  }) async {
    cursors[deviceId] = seq;
    return const Ok(null);
  }

  // ── Conflicts ──
  @override
  Future<Result<void, VaultFailure>> recordConflict(Conflict conflict) async {
    conflicts.putIfAbsent(conflict.id, () => conflict);
    return const Ok(null);
  }

  @override
  Future<Result<List<Conflict>, VaultFailure>> openConflicts() async =>
      Ok([for (final c in conflicts.values) if (c.isOpen) c]);

  @override
  Future<Result<List<Conflict>, VaultFailure>> conflictsFor(
    String entityId, {
    ConflictKind? kind,
  }) async => Ok([
    for (final c in conflicts.values)
      if (c.entityId == entityId && (kind == null || c.kind == kind)) c,
  ]);

  @override
  Future<Result<void, VaultFailure>> resolveConflict(
    ConflictId id, {
    required ConflictResolution resolution,
    required DateTime at,
    required DeviceId byDevice,
  }) async {
    final existing = conflicts[id];
    if (existing != null && existing.isOpen) {
      conflicts[id] = existing.resolve(resolution, at: at, byDevice: byDevice);
    }
    return const Ok(null);
  }

  // ── Tombstones ──
  @override
  Future<Result<void, VaultFailure>> recordTombstone(Tombstone tombstone) async {
    tombstones[(tombstone.entityKind.dbValue, tombstone.entityId)] = tombstone;
    return const Ok(null);
  }

  @override
  Future<Result<Tombstone?, VaultFailure>> findTombstone(
    TombstoneEntityKind kind,
    String entityId,
  ) async => Ok(tombstones[(kind.dbValue, entityId)]);

  @override
  Future<Result<List<Tombstone>, VaultFailure>> expiredTombstones(
    DateTime now,
  ) async => Ok([
    for (final t in tombstones.values)
      if (!t.purgeAfter.isAfter(now)) t,
  ]);

  @override
  Future<Result<void, VaultFailure>> purgeTombstone(
    TombstoneEntityKind kind,
    String entityId,
  ) async {
    tombstones.remove((kind.dbValue, entityId));
    return const Ok(null);
  }

  // ── Remote segment registration ──
  @override
  Future<Result<void, VaultFailure>> upsertRemoteSegment(
    LogSegmentRecord segment,
  ) async {
    segments[(segment.deviceId, segment.seq)] = segment;
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> markBlobPresent(BlobId blobId) async =>
      const Ok(null);
}

// ── SyncApplyPort ────────────────────────────────────────────────────────

final class FakeEntryRow {
  FakeEntryRow({
    required this.type,
    this.sealedTitle,
    this.sealedNote,
    this.sealedTags,
    required this.createdAt,
    this.deletedAt,
    required this.hlc,
    required this.originDevice,
  });

  final String type;
  List<int>? sealedTitle;
  List<int>? sealedNote;
  List<int>? sealedTags;
  final DateTime createdAt;
  DateTime? deletedAt;
  Hlc hlc;
  final String originDevice;
}

final class FakeAssetRow {
  FakeAssetRow({
    required this.entryId,
    required this.role,
    required this.ordinal,
    required this.hlc,
  });

  final String entryId;
  final String role;
  int ordinal;
  Hlc hlc;
  String? currentVersionId;
  DateTime? deletedAt;
}

final class FakeVersionRow {
  FakeVersionRow({
    required this.assetId,
    required this.parentVersionId,
    required this.kind,
    required this.blobId,
  });

  final String assetId;
  final String? parentVersionId;
  final String kind;
  String? blobId;
  bool evicted = false;
}

/// In-memory `SyncApplyPort`: the state a reducer replays against.
final class InMemoryApplyPort implements SyncApplyPort {
  final Map<String, FakeEntryRow> entries = {};
  final Map<String, FakeAssetRow> assets = {};
  final Map<String, FakeVersionRow> versions = {};
  final Set<String> remoteOnlyBlobs = {};
  final Set<(String, String, String)> pins = {};

  @override
  Future<Result<Hlc?, VaultFailure>> entryHlc(EntryId id) async =>
      Ok(entries[id]?.hlc);

  @override
  Future<Result<PointerState?, VaultFailure>> currentPointer(
    AssetId id,
  ) async {
    final row = assets[id];
    final versionId = row?.currentVersionId;
    if (row == null || versionId == null) {
      return const Ok(null);
    }
    return Ok(PointerState(versionId: versionId, hlc: row.hlc));
  }

  @override
  Future<Result<bool, VaultFailure>> versionExists(VersionId id) async =>
      Ok(versions.containsKey(id));

  @override
  Future<Result<List<VersionId>, VaultFailure>> versionLineage(
    VersionId id,
  ) async {
    final lineage = <VersionId>[];
    var current = id;
    for (var hops = 0; hops < 64 && versions.containsKey(current); hops++) {
      lineage.add(current);
      final parent = versions[current]!.parentVersionId;
      if (parent == null) {
        break;
      }
      current = parent;
    }
    return Ok(lineage);
  }

  @override
  Future<Result<bool, VaultFailure>> assetExists(AssetId id) async =>
      Ok(assets.containsKey(id));

  @override
  Future<Result<bool, VaultFailure>> upsertEntryRemote({
    required EntryId id,
    required String type,
    required List<int>? sealedTitle,
    required List<int>? sealedNote,
    required List<int>? sealedTags,
    required DateTime createdAt,
    required DateTime? deletedAt,
    required Hlc updatedHlc,
    required DeviceId originDevice,
  }) async {
    final existing = entries[id];
    if (existing == null) {
      entries[id] = FakeEntryRow(
        type: type,
        sealedTitle: sealedTitle,
        sealedNote: sealedNote,
        sealedTags: sealedTags,
        createdAt: createdAt,
        deletedAt: deletedAt,
        hlc: updatedHlc,
        originDevice: originDevice,
      );
      return const Ok(true);
    }
    if (!updatedHlc.isAfter(existing.hlc)) {
      return const Ok(false);
    }
    existing
      ..sealedTitle = sealedTitle ?? existing.sealedTitle
      ..sealedNote = sealedNote ?? existing.sealedNote
      ..sealedTags = sealedTags ?? existing.sealedTags
      ..deletedAt = deletedAt
      ..hlc = updatedHlc;
    return const Ok(true);
  }

  @override
  Future<Result<bool, VaultFailure>> upsertAssetRemote({
    required AssetId id,
    required EntryId entryId,
    required String role,
    required int ordinal,
    required DateTime createdAt,
    required DateTime? deletedAt,
    required Hlc updatedHlc,
    required DeviceId originDevice,
  }) async {
    final existing = assets[id];
    if (existing == null) {
      assets[id] = FakeAssetRow(
        entryId: entryId,
        role: role,
        ordinal: ordinal,
        hlc: updatedHlc,
      )..deletedAt = deletedAt;
      return const Ok(true);
    }
    if (!updatedHlc.isAfter(existing.hlc)) {
      return const Ok(false);
    }
    existing
      ..ordinal = ordinal
      ..deletedAt = deletedAt
      ..hlc = updatedHlc;
    return const Ok(true);
  }

  @override
  Future<Result<void, VaultFailure>> addVersionRemote({
    required VersionId id,
    required AssetId assetId,
    required VersionId? parentVersionId,
    required String kind,
    required int seq,
    required String? blobId,
    required String? recipeJson,
    required bool recipeDeterministic,
    required int width,
    required int height,
    required String mime,
    required String plaintextSha256,
    required int plaintextSize,
    required DateTime createdAt,
    required Hlc createdHlc,
    required DeviceId originDevice,
    required DateTime? evictedAt,
  }) async {
    versions.putIfAbsent(
      id,
      () => FakeVersionRow(
        assetId: assetId,
        parentVersionId: parentVersionId,
        kind: kind,
        blobId: blobId,
      )..evicted = evictedAt != null,
    );
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> setCurrentRemote({
    required AssetId assetId,
    required VersionId versionId,
    required Hlc hlc,
  }) async {
    assets[assetId]!
      ..currentVersionId = versionId
      ..hlc = hlc;
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> reorderPagesRemote({
    required EntryId entryId,
    required List<AssetId> order,
    required Hlc hlc,
  }) async {
    for (var i = 0; i < order.length; i++) {
      assets[order[i]]?.ordinal = i;
    }
    entries[entryId]?.hlc = hlc;
    return const Ok(null);
  }

  @override
  Future<Result<bool, VaultFailure>> evictVersionRemote(
    VersionId id, {
    required DateTime evictedAt,
  }) async {
    final row = versions[id];
    if (row == null || row.evicted) {
      return const Ok(false);
    }
    row
      ..evicted = true
      ..blobId = null;
    return const Ok(true);
  }

  @override
  Future<Result<void, VaultFailure>> applyTombstoneRemote({
    required TombstoneEntityKind entityKind,
    required String entityId,
    required Hlc deletedHlc,
    required DeviceId originDevice,
    required DateTime purgeAfter,
  }) async {
    switch (entityKind) {
      case TombstoneEntityKind.entry:
        entries[entityId]?.deletedAt = deletedHlc.toDateTime();
      case TombstoneEntityKind.asset:
        assets[entityId]?.deletedAt = deletedHlc.toDateTime();
      case TombstoneEntityKind.version ||
          TombstoneEntityKind.export:
        break;
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> pinVersion({
    required VersionId versionId,
    required String reason,
    required String refId,
  }) async {
    pins.add((versionId, reason, refId));
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> markBlobRemoteOnly({
    required BlobId blobId,
    required int keyEpoch,
    required int plaintextSize,
    required String plaintextSha256,
    required String ciphertextSha256,
    required DateTime now,
  }) async {
    remoteOnlyBlobs.add(blobId);
    return const Ok(null);
  }
}

extension on Hlc {
  DateTime toDateTime() =>
      DateTime.fromMillisecondsSinceEpoch(physicalMillis, isUtc: true);
}

/// Convenience: mint an op HLC for tests.
Hlc hlcAt(int millis, int counter, String device) =>
    Hlc(millis, counter, device);

/// Convenience: JSON of a sealed field.
String sealedField(String text) => base64Encode(utf8.encode(text));
