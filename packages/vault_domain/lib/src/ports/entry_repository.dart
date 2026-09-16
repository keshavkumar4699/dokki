/// `EntryRepository` port: all vault state access the application layer
/// needs. Implemented by `vault_persistence` over Drift.
library;

import '../assets/asset.dart';
import '../assets/asset_role.dart';
import '../entries/entry_type.dart';
import '../entries/vault_entry.dart';
import '../export/export_request.dart';
import '../failures/vault_failure.dart';
import '../ids.dart';
import '../imaging/image_meta.dart';
import '../result.dart';
import '../sync/hlc.dart';
import '../sync/tombstone.dart';
import '../versions/asset_version.dart';
import '../versions/edit_recipe.dart';
import '../versions/pin_set.dart';
import '../versions/version_kind.dart';
import 'blob_store.dart';

/// Everything needed to create an entry + its first asset + its ORIGINAL
/// version in one transaction.
final class NewEntry {
  const NewEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.note,
    required this.tags,
    required this.hlc,
    required this.originDevice,
    required this.createdAt,
    required this.asset,
  });

  final EntryId id;
  final EntryType type;
  final String? title;
  final String? note;
  final List<String> tags;
  final Hlc hlc;
  final DeviceId originDevice;
  final DateTime createdAt;

  /// The first asset with its ORIGINAL version attached.
  final NewAsset asset;
}

/// A new asset plus its ORIGINAL version.
final class NewAsset {
  const NewAsset({
    required this.id,
    required this.entryId,
    required this.role,
    required this.ordinal,
    required this.hlc,
    required this.originDevice,
    required this.createdAt,
    required this.originalVersion,
    required this.blob,
  });

  final AssetId id;
  final EntryId entryId;
  final AssetRole role;
  final int ordinal;
  final Hlc hlc;
  final DeviceId originDevice;
  final DateTime createdAt;
  final AssetVersion originalVersion;

  /// The sealed blob backing [originalVersion]; its metadata becomes the
  /// `blobs` row written in the same transaction (§7.3 step 5).
  final BlobRef blob;
}

/// Field-level update to an entry's plaintext metadata.
final class EntryDetailsUpdate {
  const EntryDetailsUpdate({
    required this.hlc,
    required this.updatedAt,
    this.title,
    this.note,
    this.tags,
  });

  final Hlc hlc;
  final DateTime updatedAt;
  final String? title;
  final String? note;
  final List<String>? tags;
}

/// The record of one export (§6.3).
final class ExportRecord {
  const ExportRecord({
    required this.id,
    required this.entryId,
    required this.request,
    required this.format,
    required this.status,
    required this.createdAt,
    required this.originDevice,
    this.layout,
    this.paperSize,
    this.outWidth,
    this.outHeight,
    this.dpi,
    this.quality,
    this.targetBytes,
    this.maxBytes,
    this.actualBytes,
    this.pageCount,
    this.failureCode,
    this.warningsJson,
    this.durationMs,
    this.artifactBlobId,
    this.retainArtifact = false,
    this.artifactExpiresAt,
    this.sources = const [],
  });

  final ExportId id;
  final EntryId entryId;

  /// Full request — the replayable source of truth.
  final ExportRequest request;

  /// Denormalised for list/filter without parsing JSON (§6.7).
  final String format;
  final String? layout;
  final String? paperSize;
  final int? outWidth;
  final int? outHeight;
  final int? dpi;
  final int? quality;
  final int? targetBytes;
  final int? maxBytes;
  final int? actualBytes;
  final int? pageCount;
  final String status;
  final String? failureCode;
  final String? warningsJson;
  final int? durationMs;
  final BlobId? artifactBlobId;
  final bool retainArtifact;
  final DateTime? artifactExpiresAt;
  final DateTime createdAt;
  final DeviceId originDevice;

  /// `(versionId, ordinal)` pairs — the join table (§6.3 deviation).
  final List<({String versionId, int ordinal})> sources;
}

/// A lightweight projection for the export-history list.
final class ExportRecordSummary {
  const ExportRecordSummary({
    required this.id,
    required this.format,
    required this.status,
    required this.createdAt,
    required this.actualBytes,
    required this.pageCount,
    this.artifactBlobId,
  });

  final ExportId id;
  final String format;
  final String status;
  final DateTime createdAt;
  final int? actualBytes;
  final int? pageCount;
  final BlobId? artifactBlobId;
}

/// How a commit should be applied — all of §10.5 in one call.
final class VersionCommit {
  const VersionCommit({
    required this.assetId,
    required this.version,
    required this.hlc,
    required this.now,
    required this.pinsToAdd,
    required this.pinsToRemove,
    required this.evictable,
    this.blob,
  });

  final AssetId assetId;

  /// The new DERIVED version (already materialized as a blob).
  final AssetVersion version;

  /// The sealed blob backing [version]. Required when `version.blobId` is
  /// non-null; its metadata becomes the `blobs` row.
  final BlobRef? blob;

  final Hlc hlc;
  final DateTime now;
  final List<Pin> pinsToAdd;
  final List<Pin> pinsToRemove;

  /// Versions whose binaries may be soft-evicted in the same transaction.
  final Set<VersionId> evictable;
}

/// What a successful commit returns: the updated asset plus the blob ids
/// that must be purged AFTER the transaction (§10.5).
final class CommitOutcome {
  const CommitOutcome({required this.asset, required this.purgableBlobIds});

  final Asset asset;
  final List<BlobId> purgableBlobIds;
}

abstract interface class EntryRepository {
  // ── Entries ────────────────────────────────────────────────────────────

  Future<Result<VaultEntry, VaultFailure>> createEntry(NewEntry entry);

  Future<Result<VaultEntry, VaultFailure>> findEntry(EntryId id);

  Future<Result<VaultEntry?, VaultFailure>> findEntryOrNull(EntryId id);

  Future<Result<List<VaultEntrySummary>, VaultFailure>> listEntries({
    EntryType? type,
    bool includeDeleted = false,
  });

  /// Reactive variant of [listEntries]: re-emits whenever any entry, asset
  /// or conflict row changes. Drives the vault grid (§2, "watches streams").
  Stream<Result<List<VaultEntrySummary>, VaultFailure>> watchEntries({
    EntryType? type,
  });

  /// Reactive variant of [findEntry]; emits `Ok(null)` once the entry is
  /// gone.
  Stream<Result<VaultEntry?, VaultFailure>> watchEntry(EntryId id);

  Future<Result<void, VaultFailure>> updateEntryDetails(
    EntryId id,
    EntryDetailsUpdate update,
  );

  Future<Result<void, VaultFailure>> deleteEntry(
    EntryId id,
    Tombstone tombstone, {
    required DateTime now,
  });

  // ── Assets ─────────────────────────────────────────────────────────────

  Future<Result<Asset, VaultFailure>> addAsset(NewAsset asset);

  Future<Result<Asset, VaultFailure>> findAsset(AssetId id);

  Future<Result<List<Asset>, VaultFailure>> listAssets(EntryId entryId);

  Future<Result<void, VaultFailure>> deleteAsset(
    AssetId id,
    Tombstone tombstone, {
    required DateTime now,
  });

  Future<Result<void, VaultFailure>> reorderPages(
    EntryId entryId,
    List<AssetId> orderedAssetIds, {
    required Hlc hlc,
    required DateTime now,
  });

  // ── Versions ───────────────────────────────────────────────────────────

  Future<Result<CommitOutcome, VaultFailure>> commitVersion(
    VersionCommit commit,
  );

  Future<Result<Asset, VaultFailure>> setCurrentVersion(
    AssetId assetId,
    VersionId versionId, {
    required Hlc hlc,
    required DateTime now,
  });

  Future<Result<AssetVersion?, VaultFailure>> findVersion(VersionId id);

  Future<Result<List<AssetVersion>, VaultFailure>> listVersions(
    AssetId assetId,
  );

  /// Re-attaches a freshly rebuilt blob to an evicted version row (§10.3
  /// re-materialization). Rejects versions that are not evicted.
  Future<Result<AssetVersion, VaultFailure>> rematerializeVersion(
    VersionId id,
    BlobRef blob, {
    required DateTime now,
  });

  /// Soft-evicts binaries; rows survive (§10.3). Returns the blob ids to
  /// purge after commit.
  Future<Result<List<BlobId>, VaultFailure>> evictVersions(
    List<VersionId> versionIds, {
    required Hlc hlc,
    required DateTime at,
  });

  // ── Pins ───────────────────────────────────────────────────────────────

  Future<Result<void, VaultFailure>> addPin(Pin pin, {required DateTime now});

  Future<Result<void, VaultFailure>> removePin(Pin pin);

  Future<Result<PinSet, VaultFailure>> loadPins(AssetId assetId);

  // ── Exports ────────────────────────────────────────────────────────────

  Future<Result<void, VaultFailure>> recordExport(ExportRecord record);

  Future<Result<ExportRecord?, VaultFailure>> findExportRecord(ExportId id);

  Future<Result<List<ExportRecordSummary>, VaultFailure>> listExportRecords(
    EntryId entryId,
  );
}

/// Convenience builder for an ORIGINAL version from a stored blob.
AssetVersion originalVersion({
  required VersionId id,
  required AssetId assetId,
  required int seq,
  required BlobId blobId,
  required ImageMeta meta,
  required Hlc hlc,
  required DeviceId originDevice,
  required DateTime createdAt,
}) => AssetVersion(
  id: id,
  assetId: assetId,
  parentVersionId: null,
  kind: VersionKind.original,
  seq: seq,
  blobId: blobId,
  recipe: null,
  recipeDeterministic: true,
  meta: meta,
  createdAt: createdAt,
  createdHlc: hlc,
  originDevice: originDevice,
);

/// Convenience builder for a DERIVED version.
AssetVersion derivedVersion({
  required VersionId id,
  required AssetId assetId,
  required VersionId parentVersionId,
  required int seq,
  required BlobId? blobId,
  required EditRecipe recipe,
  required ImageMeta meta,
  required Hlc hlc,
  required DeviceId originDevice,
  required DateTime createdAt,
}) => AssetVersion(
  id: id,
  assetId: assetId,
  parentVersionId: parentVersionId,
  kind: VersionKind.derived,
  seq: seq,
  blobId: blobId,
  recipe: recipe,
  recipeDeterministic: recipe.isDeterministic,
  meta: meta,
  createdAt: createdAt,
  createdHlc: hlc,
  originDevice: originDevice,
);
