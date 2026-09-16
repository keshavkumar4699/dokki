/// `SyncApplyPort`: the write surface the sync merge reducer replays
/// remote ops against (§9.3, §9.5).
///
/// Unlike `EntryRepository`, these methods take the REMOTE op's own HLC
/// and origin device verbatim — replay never mints new timestamps. All
/// methods are idempotent: replaying the same op twice is a no-op (P6).
library;

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';
import '../sync/hlc.dart';
import '../sync/tombstone.dart';

/// What an asset's current pointer looks like before a remote
/// `SetCurrentOp` is considered.
final class PointerState {
  const PointerState({required this.versionId, required this.hlc});

  final VersionId versionId;
  final Hlc hlc;
}

abstract interface class SyncApplyPort {
  // ── Reads for conflict detection ─────────────────────────────────────

  /// The entry's last-write HLC, or null if it does not exist locally.
  Future<Result<Hlc?, VaultFailure>> entryHlc(EntryId id);

  /// The asset's current pointer (version + when it was set), or null if
  /// the asset does not exist locally.
  Future<Result<PointerState?, VaultFailure>> currentPointer(AssetId id);

  /// Whether a version row exists (any state: materialized or evicted).
  Future<Result<bool, VaultFailure>> versionExists(VersionId id);

  /// The lineage of [id] from itself to the root original, bounded at 64
  /// hops. Used to tell a fast-forward (our pointer is inside the remote
  /// version's ancestry) from a genuine fork (§9.5). Empty when the
  /// version is unknown.
  Future<Result<List<VersionId>, VaultFailure>> versionLineage(VersionId id);

  /// Whether an asset row exists (live or tombstoned).
  Future<Result<bool, VaultFailure>> assetExists(AssetId id);

  // ── Idempotent remote application ────────────────────────────────────

  /// Insert or LWW-update an entry from a remote `UpsertEntryOp`. The
  /// sealed fields travel opaque (§6 column encryption). Returns true if
  /// the local row changed.
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
  });

  /// Insert (or no-op update) an asset row from a remote `UpsertAssetOp`.
  Future<Result<bool, VaultFailure>> upsertAssetRemote({
    required AssetId id,
    required EntryId entryId,
    required String role,
    required int ordinal,
    required DateTime createdAt,
    required DateTime? deletedAt,
    required Hlc updatedHlc,
    required DeviceId originDevice,
  });

  /// Insert a version row from a remote `AddVersionOp`; no-op when the
  /// version already exists (P6).
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
  });

  /// Move the current pointer after the reducer decided the remote op
  /// wins (fast-forward or provisional conflict winner).
  Future<Result<void, VaultFailure>> setCurrentRemote({
    required AssetId assetId,
    required VersionId versionId,
    required Hlc hlc,
  });

  /// Apply a remote page order (the reducer checked it is newer).
  Future<Result<void, VaultFailure>> reorderPagesRemote({
    required EntryId entryId,
    required List<AssetId> order,
    required Hlc hlc,
  });

  /// Soft-evict a version's binary (§10.3); returns false when the row
  /// was already evicted (P6 idempotence reporting).
  Future<Result<bool, VaultFailure>> evictVersionRemote(
    VersionId id, {
    required DateTime evictedAt,
  });

  /// Record a remote tombstone and mark the entity deleted (stage one of
  /// two-stage deletion, §6.5). No-op when an equal-or-newer tombstone
  /// exists.
  Future<Result<void, VaultFailure>> applyTombstoneRemote({
    required TombstoneEntityKind entityKind,
    required String entityId,
    required Hlc deletedHlc,
    required DeviceId originDevice,
    required DateTime purgeAfter,
  });

  /// Pin a version (e.g. both sides of an `ASSET_CURRENT` conflict,
  /// §9.5). Idempotent by (versionId, reason, refId).
  Future<Result<void, VaultFailure>> pinVersion({
    required VersionId versionId,
    required String reason,
    required String refId,
  });

  /// Register a blob the remote references but we have not downloaded:
  /// `blobs.local_state = REMOTE_ONLY`, no file on disk (§9.9 step 7).
  Future<Result<void, VaultFailure>> markBlobRemoteOnly({
    required BlobId blobId,
    required int keyEpoch,
    required int plaintextSize,
    required String plaintextSha256,
    required String ciphertextSha256,
    required DateTime now,
  });
}
