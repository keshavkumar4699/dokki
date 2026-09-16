/// The merge reducer (§9.3, §9.5): replays remote ops against local state.
///
/// Determinism is the whole point: two devices that have seen the same
/// set of segments arrive at the same state. The rules:
///
/// - **Upserts** are last-writer-wins by HLC (the persistence layer
///   compares), idempotent by construction.
/// - **SetCurrent** distinguishes a fast-forward from a fork by walking
///   the incoming version's lineage: if our current pointer is an
///   ancestor of the remote version, the remote writer saw our state and
///   went ahead of it (apply, no conflict). Otherwise both devices moved
///   the pointer from the same parent in different directions — that is a
///   conflict, with a deterministic provisional winner (higher HLC) and
///   both versions pinned (§9.5).
/// - **Tombstones** lose to a causally-newer local edit: deleting
///   someone's unseen edit silently is worse than an unexpected undelete
///   (§9.5 `TOMBSTONE_VS_EDIT`).
/// - **Unknown ops** are skipped, preserved in the stored segment (§9.6).
///
/// Replay is idempotent (P6): every rule converges to a no-op when the
/// same op arrives twice.
library;

import 'dart:convert';

import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';

/// What replay did with one batch of ops.
final class ReplayReport {
  const ReplayReport({
    required this.applied,
    required this.skipped,
    required this.conflictsRaised,
  });

  final int applied;
  final int skipped;
  final int conflictsRaised;
}

final class MergeReducer {
  const MergeReducer({
    required this.apply,
    required this.syncState,
    required this.ids,
    required this.clock,
  });

  final SyncApplyPort apply;
  final SyncStateRepository syncState;
  final IdGenerator ids;
  final Clock clock;

  /// Replays [ops] in HLC order. Idempotent: a second pass is all no-ops.
  Future<Result<ReplayReport, VaultFailure>> replay(
    List<SyncOp> ops,
  ) => guardSync('replay', () async {
    final sorted = [...ops]..sort((a, b) => a.hlc.compareTo(b.hlc));
    var applied = 0;
    var skipped = 0;
    var conflicts = 0;
    for (final op in sorted) {
      final outcome = await _applyOp(op);
      switch (outcome) {
        case _Outcome.applied:
          applied++;
        case _Outcome.skipped:
          skipped++;
        case _Outcome.conflict:
          applied++;
          conflicts++;
      }
    }
    return ReplayReport(
      applied: applied,
      skipped: skipped,
      conflictsRaised: conflicts,
    );
  });

  Future<_Outcome> _applyOp(SyncOp op) => switch (op) {
    UnknownSyncOp() => Future.value(_Outcome.skipped),
    UpsertEntryOp() => _upsertEntry(op),
    UpsertAssetOp() => _upsertAsset(op),
    AddVersionOp() => _addVersion(op),
    SetCurrentOp() => _setCurrent(op),
    ReorderPagesOp() => _reorderPages(op),
    EvictVersionOp() => _evictVersion(op),
    TombstoneOp() => _tombstone(op),
    ResolveConflictOp() => _resolveConflict(op),
    DeviceJoinedOp() => _deviceJoined(op),
  };

  Future<_Outcome> _upsertEntry(UpsertEntryOp op) async {
    final changed = unwrapSync(
      await apply.upsertEntryRemote(
        id: op.id,
        type: op.type,
        sealedTitle: _b64(op.sealedTitleBase64),
        sealedNote: _b64(op.sealedNoteBase64),
        sealedTags: _b64(op.sealedTagsBase64),
        createdAt: _at(op.createdAtMillis),
        deletedAt: op.deletedAtMillis == null
            ? null
            : _at(op.deletedAtMillis!),
        updatedHlc: op.hlc,
        originDevice: op.origin,
      ),
    );
    return changed ? _Outcome.applied : _Outcome.skipped;
  }

  Future<_Outcome> _upsertAsset(UpsertAssetOp op) async {
    final changed = unwrapSync(
      await apply.upsertAssetRemote(
        id: op.id,
        entryId: op.entryId,
        role: op.role,
        ordinal: op.ordinal,
        createdAt: _at(op.createdAtMillis),
        deletedAt: op.deletedAtMillis == null
            ? null
            : _at(op.deletedAtMillis!),
        updatedHlc: op.hlc,
        originDevice: op.origin,
      ),
    );
    return changed ? _Outcome.applied : _Outcome.skipped;
  }

  Future<_Outcome> _addVersion(AddVersionOp op) async {
    if (unwrapSync(await apply.versionExists(op.id))) {
      return _Outcome.skipped;
    }
    // The blob stays remote until the download pass fetches it (§9.9
    // step 7): register the REMOTE_ONLY row FIRST — the version row's
    // `blob_id` foreign key demands it exists.
    final blobId = op.blobId;
    if (blobId != null && op.evictedAtMillis == null) {
      unwrapSync(
        await apply.markBlobRemoteOnly(
          blobId: blobId,
          keyEpoch: op.blobKeyEpoch ?? 1,
          plaintextSize: op.meta.byteSize,
          plaintextSha256: op.meta.plaintextSha256,
          ciphertextSha256: op.blobCiphertextSha256 ?? '',
          now: clock.now(),
        ),
      );
    }
    unwrapSync(
      await apply.addVersionRemote(
        id: op.id,
        assetId: op.assetId,
        parentVersionId: op.parentVersionId,
        kind: op.kind,
        seq: op.seq,
        blobId: op.blobId,
        recipeJson: op.recipeJson,
        recipeDeterministic: op.recipeDeterministic,
        width: op.meta.width,
        height: op.meta.height,
        mime: op.meta.mime,
        plaintextSha256: op.meta.plaintextSha256,
        plaintextSize: op.meta.byteSize,
        createdAt: _at(op.createdAtMillis),
        createdHlc: op.hlc,
        originDevice: op.origin,
        evictedAt: op.evictedAtMillis == null
            ? null
            : _at(op.evictedAtMillis!),
      ),
    );
    return _Outcome.applied;
  }

  /// The §9.5 pointer arbitration, lineage-aware:
  ///
  /// - our pointer is inside the remote version's ancestry → the remote
  ///   writer saw our state: fast-forward, no conflict;
  /// - same version → agreement, no-op;
  /// - anything else → a fork: conflict row, both versions pinned,
  ///   deterministic provisional winner = higher HLC (both devices pick
  ///   the same winner with zero round trips).
  Future<_Outcome> _setCurrent(SetCurrentOp op) async {
    if (!unwrapSync(await apply.assetExists(op.assetId))) {
      // The asset row has not arrived yet (its UpsertAssetOp is in a
      // segment we have not replayed). Moving the pointer would dangle;
      // the op is effectively parked and the next cycle converges it.
      return _Outcome.skipped;
    }
    final pointer = unwrapSync(await apply.currentPointer(op.assetId));
    if (pointer == null) {
      // A known asset's first pointer move: nothing to conflict with.
      unwrapSync(
        await apply.setCurrentRemote(
          assetId: op.assetId,
          versionId: op.versionId,
          hlc: op.hlc,
        ),
      );
      return _Outcome.applied;
    }
    if (pointer.versionId == op.versionId) {
      return _Outcome.skipped;
    }
    final lineage = unwrapSync(await apply.versionLineage(op.versionId));
    final fastForward = lineage.contains(pointer.versionId);
    if (fastForward && op.hlc.isAfter(pointer.hlc)) {
      unwrapSync(
        await apply.setCurrentRemote(
          assetId: op.assetId,
          versionId: op.versionId,
          hlc: op.hlc,
        ),
      );
      return _Outcome.applied;
    }
    if (fastForward) {
      // Our pointer is inside the remote ancestry AND newer in total
      // order: a stale echo of a state we already passed.
      return _Outcome.skipped;
    }
    // A fork. The deterministic winner is the higher HLC; BOTH versions
    // are pinned so eviction cannot eat a side of the conflict.
    final remoteWins = op.hlc.isAfter(pointer.hlc);
    unwrapSync(
      await _recordConflict(
        kind: ConflictKind.assetCurrent,
        entityId: op.assetId,
        localStateJson: jsonEncode({
          'versionId': pointer.versionId,
          'hlc': pointer.hlc.toSortableString(),
        }),
        remoteStateJson: jsonEncode({
          'versionId': op.versionId,
          'hlc': op.hlc.toSortableString(),
        }),
        remoteWins: remoteWins,
        detectedHlc: op.hlc,
      ),
    );
    unwrapSync(
      await apply.pinVersion(
        versionId: pointer.versionId,
        reason: 'CONFLICT',
        refId: op.assetId,
      ),
    );
    unwrapSync(
      await apply.pinVersion(
        versionId: op.versionId,
        reason: 'CONFLICT',
        refId: op.assetId,
      ),
    );
    if (remoteWins) {
      unwrapSync(
        await apply.setCurrentRemote(
          assetId: op.assetId,
          versionId: op.versionId,
          hlc: op.hlc,
        ),
      );
    }
    return _Outcome.conflict;
  }

  Future<_Outcome> _reorderPages(ReorderPagesOp op) async {
    final entryHlc = unwrapSync(await apply.entryHlc(op.entryId));
    if (entryHlc != null && !op.hlc.isAfter(entryHlc)) {
      return _Outcome.skipped;
    }
    unwrapSync(
      await apply.reorderPagesRemote(
        entryId: op.entryId,
        order: op.assetIds,
        hlc: op.hlc,
      ),
    );
    return _Outcome.applied;
  }

  Future<_Outcome> _evictVersion(EvictVersionOp op) async {
    if (!unwrapSync(await apply.versionExists(op.versionId))) {
      return _Outcome.skipped;
    }
    final changed = unwrapSync(
      await apply.evictVersionRemote(op.versionId, evictedAt: clock.now()),
    );
    return changed ? _Outcome.applied : _Outcome.skipped;
  }

  /// `TOMBSTONE_VS_EDIT` (§9.5): an edit the tombstone could not have
  /// seen wins; the delete becomes a conflict instead of a silent
  /// deletion. Otherwise the tombstone applies (stage one, §6.5).
  Future<_Outcome> _tombstone(TombstoneOp op) async {
    if (op.entityKind == TombstoneEntityKind.entry) {
      final entryHlc = unwrapSync(await apply.entryHlc(op.entityId));
      if (entryHlc != null && entryHlc.isAfter(op.hlc)) {
        unwrapSync(
          await _recordConflict(
            kind: ConflictKind.tombstoneVsEdit,
            entityId: op.entityId,
            localStateJson: jsonEncode({
              'editedHlc': entryHlc.toSortableString(),
            }),
            remoteStateJson: jsonEncode({
              'tombstoneHlc': op.hlc.toSortableString(),
            }),
            remoteWins: false,
            detectedHlc: op.hlc,
          ),
        );
        return _Outcome.conflict;
      }
    }
    unwrapSync(
      await apply.applyTombstoneRemote(
        entityKind: op.entityKind,
        entityId: op.entityId,
        deletedHlc: op.hlc,
        originDevice: op.origin,
        purgeAfter: _defaultPurgeAfter(),
      ),
    );
    return _Outcome.applied;
  }

  Future<_Outcome> _resolveConflict(ResolveConflictOp op) async {
    unwrapSync(
      await syncState.resolveConflict(
        op.conflictId,
        resolution: op.resolution,
        at: clock.now(),
        byDevice: op.origin,
      ),
    );
    return _Outcome.applied;
  }

  Future<_Outcome> _deviceJoined(DeviceJoinedOp op) async {
    unwrapSync(
      await syncState.upsertPeerDevice(
        id: op.deviceId,
        label: op.label,
        now: clock.now(),
      ),
    );
    return _Outcome.applied;
  }

  /// Conflict ids are deterministic (`<kind>:<entityId>`), so replaying
  /// the same fork twice cannot mint a second row (P6), and both devices
  /// name the same conflict.
  Future<Result<void, VaultFailure>> _recordConflict({
    required ConflictKind kind,
    required String entityId,
    required String localStateJson,
    required String remoteStateJson,
    required bool remoteWins,
    required Hlc detectedHlc,
  }) => syncState.recordConflict(
    Conflict(
      id: '${kind.dbValue}:$entityId',
      kind: kind,
      entityId: entityId,
      localStateJson: localStateJson,
      remoteStateJson: remoteStateJson,
      provisionalWinner: remoteWins
          ? ConflictWinner.remote
          : ConflictWinner.local,
      detectedAt: clock.now(),
      detectedHlc: detectedHlc,
    ),
  );

  DateTime _defaultPurgeAfter() =>
      clock.now().add(const Duration(days: 180));

  DateTime _at(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

  List<int>? _b64(String? value) =>
      value == null ? null : base64Decode(value);
}

enum _Outcome { applied, skipped, conflict }
