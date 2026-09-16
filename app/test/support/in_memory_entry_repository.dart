/// In-memory `EntryRepository` with the same invariant checks the SQLite
/// schema enforces (I1–I7), so use-case tests exercise the real rules
/// without a database.
library;

import 'dart:async';

import 'package:vault_domain/vault_domain.dart';

final class InMemoryEntryRepository implements EntryRepository {
  final Map<EntryId, VaultEntry> _entries = {};
  final Map<AssetId, Asset> _assets = {};
  final Map<VersionId, AssetVersion> _versions = {};
  final Map<BlobId, BlobRef> blobs = {};
  final List<Pin> _pins = [];
  final List<Tombstone> tombstones = [];
  final Map<ExportId, ExportRecord> _exports = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Set to make the next mutation fail, to test rollback/cleanup paths.
  VaultFailure? failNextWrite;

  void _touch() => _changes.add(null);

  Result<T, VaultFailure>? _maybeFail<T>() {
    final failure = failNextWrite;
    if (failure == null) {
      return null;
    }
    failNextWrite = null;
    return Err(failure);
  }

  // ── Entries ────────────────────────────────────────────────────────────

  @override
  Future<Result<VaultEntry, VaultFailure>> createEntry(NewEntry entry) async {
    final failed = _maybeFail<VaultEntry>();
    if (failed != null) {
      return failed;
    }
    final assetResult = _insertAsset(entry.asset);
    if (assetResult.isErr) {
      return Err(assetResult.errOrNull!);
    }
    _entries[entry.id] = VaultEntry(
      id: entry.id,
      type: entry.type,
      title: entry.title,
      note: entry.note,
      tags: entry.tags,
      createdAt: entry.createdAt,
      updatedAt: entry.createdAt,
      updatedHlc: entry.hlc,
      originDevice: entry.originDevice,
      assets: const [],
    );
    _touch();
    return findEntry(entry.id);
  }

  @override
  Future<Result<VaultEntry, VaultFailure>> findEntry(EntryId id) async {
    final entry = _load(id);
    return entry == null ? Err(InvalidAsset('no entry $id')) : Ok(entry);
  }

  @override
  Future<Result<VaultEntry?, VaultFailure>> findEntryOrNull(EntryId id) async =>
      Ok(_load(id));

  VaultEntry? _load(EntryId id) {
    final entry = _entries[id];
    if (entry == null) {
      return null;
    }
    final assets =
        _assets.values.where((a) => a.entryId == id).map(_withVersions).toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    return entry.copyWith(assets: assets);
  }

  VersionId? _coverOf(EntryId id) {
    final live =
        _assets.values.where((a) => a.entryId == id && a.isLive).toList()
          ..sort((a, b) => a.ordinal.compareTo(b.ordinal));
    return live.firstOrNull?.currentVersionId;
  }

  Asset _withVersions(Asset asset) {
    final versions =
        _versions.values
            .where((v) => v.assetId == asset.id)
            .map(
              (v) =>
                  v.copyWith(isPinned: _pins.any((p) => p.versionId == v.id)),
            )
            .toList()
          ..sort((a, b) => a.seq.compareTo(b.seq));
    return asset.copyWith(versions: versions);
  }

  @override
  Future<Result<List<VaultEntrySummary>, VaultFailure>> listEntries({
    EntryType? type,
    bool includeDeleted = false,
  }) async => Ok(_summaries(type: type, includeDeleted: includeDeleted));

  List<VaultEntrySummary> _summaries({
    EntryType? type,
    bool includeDeleted = false,
  }) {
    final rows =
        _entries.values
            .where((e) => includeDeleted || e.isLive)
            .where((e) => type == null || e.type == type)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return rows
        .map(
          (e) => VaultEntrySummary(
            id: e.id,
            type: e.type,
            title: e.title,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
            assetCount: _assets.values
                .where((a) => a.entryId == e.id && a.isLive)
                .length,
            hasOpenConflict: false,
            coverVersionId: _coverOf(e.id),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<Result<List<VaultEntrySummary>, VaultFailure>> watchEntries({
    EntryType? type,
  }) async* {
    yield Ok(_summaries(type: type));
    await for (final _ in _changes.stream) {
      yield Ok(_summaries(type: type));
    }
  }

  @override
  Stream<Result<VaultEntry?, VaultFailure>> watchEntry(EntryId id) async* {
    yield Ok(_load(id));
    await for (final _ in _changes.stream) {
      yield Ok(_load(id));
    }
  }

  @override
  Future<Result<void, VaultFailure>> updateEntryDetails(
    EntryId id,
    EntryDetailsUpdate update,
  ) async {
    final entry = _entries[id];
    if (entry == null) {
      return Err(InvalidAsset('no entry $id'));
    }
    _entries[id] = VaultEntry(
      id: entry.id,
      type: entry.type,
      title: update.title ?? entry.title,
      note: update.note ?? entry.note,
      tags: update.tags ?? entry.tags,
      createdAt: entry.createdAt,
      updatedAt: update.updatedAt,
      updatedHlc: update.hlc,
      originDevice: entry.originDevice,
      deletedAt: entry.deletedAt,
      assets: const [],
    );
    _touch();
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> deleteEntry(
    EntryId id,
    Tombstone tombstone, {
    required DateTime now,
  }) async {
    final entry = _entries[id];
    if (entry == null) {
      return Err(InvalidAsset('no entry $id'));
    }
    _entries[id] = entry.copyWith(
      deletedAt: now,
      updatedAt: now,
      updatedHlc: tombstone.deletedHlc,
    );
    tombstones.add(tombstone);
    _touch();
    return const Ok(null);
  }

  // ── Assets ─────────────────────────────────────────────────────────────

  Result<Asset, VaultFailure> _insertAsset(NewAsset asset) {
    final clash = _assets.values.any(
      (a) =>
          a.entryId == asset.entryId &&
          a.isLive &&
          a.role == asset.role &&
          (a.ordinal == asset.ordinal || a.role != AssetRole.page),
    );
    if (clash) {
      return const Err(EntryInvariantViolated('duplicate slot (I6)'));
    }
    if (asset.originalVersion.blobId == null) {
      return const Err(EntryInvariantViolated('ORIGINAL without blob (I2)'));
    }
    blobs[asset.blob.id] = asset.blob;
    _versions[asset.originalVersion.id] = asset.originalVersion;
    final stored = Asset(
      id: asset.id,
      entryId: asset.entryId,
      role: asset.role,
      ordinal: asset.ordinal,
      currentVersionId: asset.originalVersion.id,
      createdAt: asset.createdAt,
      updatedAt: asset.createdAt,
      updatedHlc: asset.hlc,
      originDevice: asset.originDevice,
      versions: const [],
    );
    _assets[asset.id] = stored;
    return Ok(_withVersions(stored));
  }

  @override
  Future<Result<Asset, VaultFailure>> addAsset(NewAsset asset) async {
    final failed = _maybeFail<Asset>();
    if (failed != null) {
      return failed;
    }
    if (!_entries.containsKey(asset.entryId)) {
      return Err(InvalidAsset('no entry ${asset.entryId}'));
    }
    final result = _insertAsset(asset);
    _touch();
    return result;
  }

  @override
  Future<Result<Asset, VaultFailure>> findAsset(AssetId id) async {
    final asset = _assets[id];
    return asset == null
        ? Err(InvalidAsset('no asset $id'))
        : Ok(_withVersions(asset));
  }

  @override
  Future<Result<List<Asset>, VaultFailure>> listAssets(EntryId entryId) async =>
      Ok(_load(entryId)?.liveAssets.toList() ?? const []);

  @override
  Future<Result<void, VaultFailure>> deleteAsset(
    AssetId id,
    Tombstone tombstone, {
    required DateTime now,
  }) async {
    final asset = _assets[id];
    if (asset == null) {
      return Err(InvalidAsset('no asset $id'));
    }
    _assets[id] = asset.copyWith(
      deletedAt: now,
      updatedHlc: tombstone.deletedHlc,
    );
    tombstones.add(tombstone);
    _touch();
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> reorderPages(
    EntryId entryId,
    List<AssetId> orderedAssetIds, {
    required Hlc hlc,
    required DateTime now,
  }) async {
    final live = _assets.values
        .where((a) => a.entryId == entryId && a.isLive)
        .toList();
    final remaining = live.map((a) => a.id).toSet();
    for (final id in orderedAssetIds) {
      if (!remaining.remove(id)) {
        return const Err(EntryInvariantViolated('unknown/duplicate page (I7)'));
      }
    }
    if (remaining.isNotEmpty) {
      return const Err(EntryInvariantViolated('missing page (I7)'));
    }
    for (var i = 0; i < orderedAssetIds.length; i++) {
      final id = orderedAssetIds[i];
      _assets[id] = _assets[id]!.copyWith(ordinal: i, updatedHlc: hlc);
    }
    _touch();
    return const Ok(null);
  }

  // ── Versions ───────────────────────────────────────────────────────────

  @override
  Future<Result<CommitOutcome, VaultFailure>> commitVersion(
    VersionCommit commit,
  ) async {
    final failed = _maybeFail<CommitOutcome>();
    if (failed != null) {
      return failed;
    }
    final asset = _assets[commit.assetId];
    if (asset == null) {
      return Err(InvalidAsset('no asset ${commit.assetId}'));
    }
    final version = commit.version;
    if (version.blobId != null) {
      final blob = commit.blob;
      if (blob == null || blob.id != version.blobId) {
        return const Err(InvalidAsset('commit without BlobRef'));
      }
      blobs[blob.id] = blob;
    }
    _versions[version.id] = version;
    final purgable = <BlobId>[];
    for (final id in commit.evictable) {
      final v = _versions[id];
      if (v == null || v.isOriginal || id == version.id) {
        return const Err(EntryInvariantViolated('bad eviction (I2/I3)'));
      }
      if (v.blobId != null) {
        purgable.add(v.blobId!);
        _versions[id] = v.copyWith(blobId: null, evictedAt: commit.now);
      }
    }
    for (final pin in commit.pinsToAdd) {
      if (!_pins.contains(pin)) {
        _pins.add(pin);
      }
    }
    _pins.removeWhere(commit.pinsToRemove.contains);
    _assets[asset.id] = asset.copyWith(
      currentVersionId: version.id,
      updatedAt: commit.now,
      updatedHlc: commit.hlc,
    );
    _touch();
    return Ok(
      CommitOutcome(
        asset: _withVersions(_assets[asset.id]!),
        purgableBlobIds: purgable,
      ),
    );
  }

  @override
  Future<Result<Asset, VaultFailure>> setCurrentVersion(
    AssetId assetId,
    VersionId versionId, {
    required Hlc hlc,
    required DateTime now,
  }) async {
    final asset = _assets[assetId];
    final version = _versions[versionId];
    if (asset == null) {
      return Err(InvalidAsset('no asset $assetId'));
    }
    if (version == null) {
      return Err(MissingVersion(versionId));
    }
    if (version.assetId != assetId || version.blobId == null) {
      return const Err(EntryInvariantViolated('I3'));
    }
    _assets[assetId] = asset.copyWith(
      currentVersionId: versionId,
      updatedAt: now,
      updatedHlc: hlc,
    );
    _touch();
    return Ok(_withVersions(_assets[assetId]!));
  }

  @override
  Future<Result<AssetVersion?, VaultFailure>> findVersion(VersionId id) async =>
      Ok(_versions[id]);

  @override
  Future<Result<List<AssetVersion>, VaultFailure>> listVersions(
    AssetId assetId,
  ) async => Ok(_withVersions(_assets[assetId]!).versions);

  @override
  Future<Result<AssetVersion, VaultFailure>> rematerializeVersion(
    VersionId id,
    BlobRef blob, {
    required DateTime now,
  }) async {
    final version = _versions[id];
    if (version == null) {
      return Err(MissingVersion(id));
    }
    if (version.blobId != null) {
      return Err(InvalidAsset('$id already materialized'));
    }
    blobs[blob.id] = blob;
    _versions[id] = version.copyWith(blobId: blob.id, evictedAt: null);
    _touch();
    return Ok(_versions[id]!);
  }

  @override
  Future<Result<List<BlobId>, VaultFailure>> evictVersions(
    List<VersionId> versionIds, {
    required Hlc hlc,
    required DateTime at,
  }) async {
    final purgable = <BlobId>[];
    for (final id in versionIds) {
      final v = _versions[id];
      if (v == null || v.isOriginal) {
        return const Err(EntryInvariantViolated('I2'));
      }
      if (v.blobId != null) {
        purgable.add(v.blobId!);
        _versions[id] = v.copyWith(blobId: null, evictedAt: at);
      }
    }
    _touch();
    return Ok(purgable);
  }

  // ── Pins ───────────────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> addPin(
    Pin pin, {
    required DateTime now,
  }) async {
    if (!_pins.contains(pin)) {
      _pins.add(pin);
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> removePin(Pin pin) async {
    _pins.remove(pin);
    return const Ok(null);
  }

  @override
  Future<Result<PinSet, VaultFailure>> loadPins(AssetId assetId) async {
    final ids = _versions.values
        .where((v) => v.assetId == assetId)
        .map((v) => v.id)
        .toSet();
    return Ok(PinSet(_pins.where((p) => ids.contains(p.versionId)).toList()));
  }

  // ── Exports ────────────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> recordExport(ExportRecord record) async {
    final failed = _maybeFail<void>();
    if (failed != null) {
      return failed;
    }
    if (record.artifactBlobId != null &&
        record.artifactBlob?.id != record.artifactBlobId) {
      return Err(InvalidAsset('export ${record.id} artifact without BlobRef'));
    }
    _exports[record.id] = record;
    if (record.retainArtifact && record.artifactBlobId != null) {
      for (final source in record.sources) {
        _pins.add(
          Pin(
            versionId: source.versionId,
            reason: PinReason.exportRetained,
            refId: record.id,
          ),
        );
      }
    }
    _touch();
    return const Ok(null);
  }

  @override
  Future<Result<List<BlobId>, VaultFailure>> releaseExportArtifacts({
    required DateTime now,
  }) async {
    final purgable = <BlobId>[];
    for (final record in _exports.values.toList()) {
      final blobId = record.artifactBlobId;
      if (blobId == null) {
        continue;
      }
      final expiry = record.artifactExpiresAt;
      if (record.retainArtifact && expiry != null && expiry.isAfter(now)) {
        continue;
      }
      purgable.add(blobId);
      _pins.removeWhere(
        (p) => p.reason == PinReason.exportRetained && p.refId == record.id,
      );
      _exports[record.id] = ExportRecord(
        id: record.id,
        entryId: record.entryId,
        request: record.request,
        format: record.format,
        status: record.status,
        createdAt: record.createdAt,
        originDevice: record.originDevice,
        layout: record.layout,
        paperSize: record.paperSize,
        outWidth: record.outWidth,
        outHeight: record.outHeight,
        dpi: record.dpi,
        quality: record.quality,
        targetBytes: record.targetBytes,
        maxBytes: record.maxBytes,
        actualBytes: record.actualBytes,
        pageCount: record.pageCount,
        failureCode: record.failureCode,
        warningsJson: record.warningsJson,
        durationMs: record.durationMs,
        sources: record.sources,
      );
    }
    _touch();
    return Ok(purgable);
  }

  @override
  Future<Result<ExportRecord?, VaultFailure>> findExportRecord(
    ExportId id,
  ) async => Ok(_exports[id]);

  @override
  Future<Result<List<ExportRecordSummary>, VaultFailure>> listExportRecords(
    EntryId entryId,
  ) async => Ok(
    _exports.values
        .where((e) => e.entryId == entryId)
        .map(
          (e) => ExportRecordSummary(
            id: e.id,
            format: e.format,
            status: e.status,
            createdAt: e.createdAt,
            actualBytes: e.actualBytes,
            pageCount: e.pageCount,
            artifactBlobId: e.artifactBlobId,
          ),
        )
        .toList(growable: false),
  );

  Future<void> dispose() => _changes.close();
}
