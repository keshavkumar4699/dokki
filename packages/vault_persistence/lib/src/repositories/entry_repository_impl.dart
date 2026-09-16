/// `EntryRepository` implementation over Drift (§10).
library;

import 'dart:convert';

import 'package:convert/convert.dart' show hex;
import 'package:drift/drift.dart';
import 'package:vault_domain/vault_domain.dart';

import '../daos/entries_dao.dart';
import '../daos/exports_dao.dart';
import '../daos/sync_dao.dart';
import '../daos/versions_dao.dart';
import '../database/app_database.dart';
import '../error_boundary.dart';
import '../export_request_codec.dart';

/// Drift-backed [EntryRepository].
///
/// `title`/`note`/`tags` are sealed under `K_meta` via [CryptoEngine] when
/// one is supplied (§6). Without one — the Phase 1 debug configuration —
/// the `*_enc` columns hold plaintext UTF-8 bytes.
final class EntryRepositoryImpl implements EntryRepository {
  EntryRepositoryImpl(
    this._db, {
    required int Function() activeKeyEpoch,
    CryptoEngine? crypto,
  }) : _activeKeyEpoch = activeKeyEpoch,
       _crypto = crypto;

  final AppDatabase _db;
  final int Function() _activeKeyEpoch;
  final CryptoEngine? _crypto;

  EntriesDao get _entries => _db.entriesDao;
  VersionsDao get _versions => _db.versionsDao;
  SyncDao get _sync => _db.syncDao;
  ExportsDao get _exports => _db.exportsDao;

  // ── Entries ────────────────────────────────────────────────────────────

  @override
  Future<Result<VaultEntry, VaultFailure>> createEntry(NewEntry entry) =>
      guardDb('createEntry', () async {
        final titleEnc = await _sealText(entry.title);
        final noteEnc = await _sealText(entry.note);
        final tagsEnc = await _sealText(
          entry.tags.isEmpty ? null : jsonEncode(entry.tags),
        );
        await _db.transaction(() async {
          await _entries.insertEntry(
            VaultEntriesCompanion.insert(
              id: entry.id,
              type: entry.type.dbValue,
              titleEnc: Value(titleEnc),
              noteEnc: Value(noteEnc),
              tagsEnc: Value(tagsEnc),
              createdAt: entry.createdAt,
              updatedAt: entry.createdAt,
              updatedHlc: entry.hlc.toSortableString(),
              originDevice: entry.originDevice,
            ),
          );
          await _insertNewAsset(entry.asset);
        });
        return _requireEntry(entry.id);
      });

  @override
  Future<Result<VaultEntry, VaultFailure>> findEntry(EntryId id) =>
      guardDb('findEntry', () => _requireEntry(id));

  @override
  Future<Result<VaultEntry?, VaultFailure>> findEntryOrNull(EntryId id) =>
      guardDb('findEntryOrNull', () => _loadEntry(id));

  @override
  Future<Result<List<VaultEntrySummary>, VaultFailure>> listEntries({
    EntryType? type,
    bool includeDeleted = false,
  }) => guardDb('listEntries', () async {
    final rows = await _entries.entrySummaries(
      type: type?.dbValue,
      includeDeleted: includeDeleted,
    );
    return _summariesFrom(rows);
  });

  @override
  Stream<Result<List<VaultEntrySummary>, VaultFailure>> watchEntries({
    EntryType? type,
  }) => _entries
      .watchEntrySummaries(type: type?.dbValue)
      .asyncMap((rows) => guardDb('watchEntries', () => _summariesFrom(rows)));

  @override
  Stream<Result<VaultEntry?, VaultFailure>> watchEntry(EntryId id) => _entries
      .watchEntryTouch(id)
      .asyncMap((_) => guardDb('watchEntry', () => _loadEntry(id)));

  @override
  Future<Result<void, VaultFailure>> updateEntryDetails(
    EntryId id,
    EntryDetailsUpdate update,
  ) => guardDb('updateEntryDetails', () async {
    final sealedTitle = update.title == null
        ? null
        : await _sealText(update.title);
    final sealedNote = update.note == null
        ? null
        : await _sealText(update.note);
    final sealedTags = update.tags == null
        ? null
        : await _sealText(jsonEncode(update.tags));
    await _db.transaction(() async {
      await _requireEntryRow(id);
      await _entries.updateEntryRow(
        id,
        VaultEntriesCompanion(
          titleEnc: update.title == null
              ? const Value.absent()
              : Value(sealedTitle),
          noteEnc: update.note == null
              ? const Value.absent()
              : Value(sealedNote),
          tagsEnc: update.tags == null
              ? const Value.absent()
              : Value(sealedTags),
          updatedAt: Value(update.updatedAt),
          updatedHlc: Value(update.hlc.toSortableString()),
        ),
      );
    });
  });

  @override
  Future<Result<void, VaultFailure>> deleteEntry(
    EntryId id,
    Tombstone tombstone, {
    required DateTime now,
  }) => guardDb(
    'deleteEntry',
    () => _db.transaction(() async {
      await _requireEntryRow(id);
      await _entries.updateEntryRow(
        id,
        VaultEntriesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          updatedHlc: Value(tombstone.deletedHlc.toSortableString()),
        ),
      );
      await _insertTombstone(tombstone);
    }),
  );

  // ── Assets ─────────────────────────────────────────────────────────────

  @override
  Future<Result<Asset, VaultFailure>> addAsset(NewAsset asset) =>
      guardDb('addAsset', () async {
        await _db.transaction(() async {
          await _insertNewAsset(asset);
          await _touchEntry(asset.entryId, asset.hlc, asset.createdAt);
        });
        return _requireAsset(asset.id);
      });

  @override
  Future<Result<Asset, VaultFailure>> findAsset(AssetId id) =>
      guardDb('findAsset', () => _requireAsset(id));

  @override
  Future<Result<List<Asset>, VaultFailure>> listAssets(EntryId entryId) =>
      guardDb('listAssets', () => _loadAssetsFor(entryId));

  @override
  Future<Result<void, VaultFailure>> deleteAsset(
    AssetId id,
    Tombstone tombstone, {
    required DateTime now,
  }) => guardDb(
    'deleteAsset',
    () => _db.transaction(() async {
      final row = await _entries.assetById(id);
      if (row == null) {
        throw PersistenceException(InvalidAsset('no asset with id $id'));
      }
      await _entries.markAssetDeleted(id, now);
      await _touchEntry(row.entryId, tombstone.deletedHlc, now);
      await _insertTombstone(tombstone);
    }),
  );

  @override
  Future<Result<void, VaultFailure>> reorderPages(
    EntryId entryId,
    List<AssetId> orderedAssetIds, {
    required Hlc hlc,
    required DateTime now,
  }) => guardDb(
    'reorderPages',
    () => _db.transaction(() async {
      final live = await _entries.assetsForEntry(entryId);
      final remaining = live.map((a) => a.id).toSet();
      for (final id in orderedAssetIds) {
        if (!remaining.remove(id)) {
          throw PersistenceException(
            EntryInvariantViolated(
              'reorder names unknown or duplicate page $id (I7)',
            ),
          );
        }
      }
      if (remaining.isNotEmpty) {
        throw const PersistenceException(
          EntryInvariantViolated(
            'reorder must name every page exactly once (I7)',
          ),
        );
      }
      // Two passes keep the partial unique index ux_assets_slot satisfied
      // at every step: park every page far above any real ordinal first
      // (the CHECK forbids negatives), then assign the final 0..n-1.
      for (var i = 0; i < orderedAssetIds.length; i++) {
        await _entries.setAssetOrdinal(
          orderedAssetIds[i],
          _reorderParkingOffset + i,
        );
      }
      for (var i = 0; i < orderedAssetIds.length; i++) {
        await _entries.setAssetOrdinal(orderedAssetIds[i], i);
      }
      await _touchEntry(entryId, hlc, now);
    }),
  );

  // ── Versions ───────────────────────────────────────────────────────────

  @override
  Future<Result<CommitOutcome, VaultFailure>> commitVersion(
    VersionCommit commit,
  ) => guardDb('commitVersion', () async {
    final purgableBlobIds = <String>[];
    await _db.transaction(() async {
      final assetRow = await _entries.assetById(commit.assetId);
      if (assetRow == null) {
        throw PersistenceException(
          InvalidAsset('no asset with id ${commit.assetId}'),
        );
      }
      final version = commit.version;
      if (version.assetId != commit.assetId) {
        throw PersistenceException(
          EntryInvariantViolated(
            'version ${version.id} belongs to ${version.assetId}, '
            'not ${commit.assetId}',
          ),
        );
      }
      final blob = commit.blob;
      if (version.blobId != null) {
        if (blob == null || blob.id != version.blobId) {
          throw PersistenceException(
            InvalidAsset(
              'commit of ${version.id} must carry the BlobRef for '
              '${version.blobId}',
            ),
          );
        }
        await _versions.insertBlob(_blobCompanion(blob, commit.now));
      }
      await _versions.insertVersion(_versionCompanion(version));
      await _entries.updateAsset(
        commit.assetId,
        AssetsCompanion(
          currentVersionId: Value(version.id),
          updatedAt: Value(commit.now),
          updatedHlc: Value(commit.hlc.toSortableString()),
        ),
      );
      if (blob != null) {
        await _enqueueUpload(blob.id, commit.now);
      }
      for (final pin in commit.pinsToAdd) {
        await _versions.insertPin(_pinCompanion(pin, commit.now));
      }
      for (final pin in commit.pinsToRemove) {
        await _versions.deletePin(pin.versionId, pin.reason.dbValue, pin.refId);
      }
      if (commit.evictable.isNotEmpty) {
        final ids = commit.evictable.toList(growable: false);
        final evictedBlobs = await _versions.blobIdsOf(ids);
        purgableBlobIds.addAll(evictedBlobs);
        await _versions.evictVersionBlobs(ids, commit.now);
        await _versions.markBlobsEvicted(evictedBlobs);
      }
      await _touchEntry(assetRow.entryId, commit.hlc, commit.now);
    });
    return CommitOutcome(
      asset: await _requireAsset(commit.assetId),
      purgableBlobIds: purgableBlobIds,
    );
  });

  @override
  Future<Result<Asset, VaultFailure>> setCurrentVersion(
    AssetId assetId,
    VersionId versionId, {
    required Hlc hlc,
    required DateTime now,
  }) => guardDb('setCurrentVersion', () async {
    await _db.transaction(() async {
      final version = await _versions.versionById(versionId);
      if (version == null) {
        throw PersistenceException(MissingVersion(versionId));
      }
      if (version.assetId != assetId) {
        throw PersistenceException(
          EntryInvariantViolated(
            'version $versionId belongs to ${version.assetId}, '
            'not $assetId',
          ),
        );
      }
      if (version.blobId == null) {
        throw PersistenceException(
          EntryInvariantViolated(
            'cannot point at evicted version $versionId (I3)',
          ),
        );
      }
      final assetRow = await _entries.assetById(assetId);
      if (assetRow == null) {
        throw PersistenceException(InvalidAsset('no asset with id $assetId'));
      }
      await _entries.updateAsset(
        assetId,
        AssetsCompanion(
          currentVersionId: Value(versionId),
          updatedAt: Value(now),
          updatedHlc: Value(hlc.toSortableString()),
        ),
      );
      await _touchEntry(assetRow.entryId, hlc, now);
    });
    return _requireAsset(assetId);
  });

  @override
  Future<Result<AssetVersion?, VaultFailure>> findVersion(VersionId id) =>
      guardDb('findVersion', () async {
        final row = await _versions.versionById(id);
        if (row == null) {
          return null;
        }
        final pins = await _versions.pinsForVersion(id);
        return _versionFrom(row, pins.isNotEmpty);
      });

  @override
  Future<Result<List<AssetVersion>, VaultFailure>> listVersions(
    AssetId assetId,
  ) => guardDb('listVersions', () => _loadVersions(assetId));

  @override
  Future<Result<AssetVersion, VaultFailure>> rematerializeVersion(
    VersionId id,
    BlobRef blob, {
    required DateTime now,
  }) => guardDb('rematerializeVersion', () async {
    await _db.transaction(() async {
      final row = await _versions.versionById(id);
      if (row == null) {
        throw PersistenceException(MissingVersion(id));
      }
      if (row.blobId != null) {
        throw PersistenceException(
          InvalidAsset('version $id is already materialized'),
        );
      }
      await _versions.insertBlob(_blobCompanion(blob, now));
      await _versions.rematerializeVersionRow(id, blob.id);
      await _enqueueUpload(blob.id, now);
    });
    final pins = await _versions.pinsForVersion(id);
    final row = await _versions.versionById(id);
    return _versionFrom(row!, pins.isNotEmpty);
  });

  @override
  Future<Result<List<BlobId>, VaultFailure>> evictVersions(
    List<VersionId> versionIds, {
    required Hlc hlc,
    required DateTime at,
  }) => guardDb(
    'evictVersions',
    () => _db.transaction(() async {
      final purgable = await _versions.blobIdsOf(versionIds);
      await _versions.evictVersionBlobs(versionIds, at);
      await _versions.markBlobsEvicted(purgable);
      return purgable;
    }),
  );

  // ── Pins ───────────────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> addPin(Pin pin, {required DateTime now}) =>
      guardDb('addPin', () => _versions.insertPin(_pinCompanion(pin, now)));

  @override
  Future<Result<void, VaultFailure>> removePin(Pin pin) => guardDb(
    'removePin',
    () => _versions.deletePin(pin.versionId, pin.reason.dbValue, pin.refId),
  );

  @override
  Future<Result<PinSet, VaultFailure>> loadPins(AssetId assetId) =>
      guardDb('loadPins', () async {
        final rows = await _versions.pinsForAsset(assetId);
        return PinSet(
          rows
              .map(
                (row) => Pin(
                  versionId: row.versionId,
                  reason: PinReason.fromDbValue(row.reason) ?? PinReason.user,
                  refId: row.refId,
                ),
              )
              .toList(growable: false),
        );
      });

  // ── Exports ────────────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> recordExport(ExportRecord record) =>
      guardDb(
        'recordExport',
        () => _db.transaction(() async {
          final artifact = record.artifactBlob;
          if (record.artifactBlobId != null) {
            if (artifact == null || artifact.id != record.artifactBlobId) {
              throw PersistenceException(
                InvalidAsset(
                  'export ${record.id} names artifact '
                  '${record.artifactBlobId} without its BlobRef',
                ),
              );
            }
            // Artifacts are local: sealed, recorded, never enqueued for
            // upload (§7.1).
            await _versions.insertBlob(
              _blobCompanion(artifact, record.createdAt),
            );
          }
          await _exports.insertExportRow(
            ExportRecordsCompanion.insert(
              id: record.id,
              entryId: record.entryId,
              requestJson: encodeExportRequest(record.request),
              requestSchemaVersion: record.request.requestSchemaVersion,
              format: record.format,
              layout: Value(record.layout),
              paperSize: Value(record.paperSize),
              outWidth: Value(record.outWidth),
              outHeight: Value(record.outHeight),
              dpi: Value(record.dpi),
              quality: Value(record.quality),
              targetBytes: Value(record.targetBytes),
              maxBytes: Value(record.maxBytes),
              actualBytes: Value(record.actualBytes),
              pageCount: Value(record.pageCount),
              status: record.status,
              failureCode: Value(record.failureCode),
              warningsJson: Value(record.warningsJson),
              durationMs: Value(record.durationMs),
              artifactBlobId: Value(record.artifactBlobId),
              retainArtifact: Value(record.retainArtifact),
              artifactExpiresAt: Value(record.artifactExpiresAt),
              createdAt: record.createdAt,
              originDevice: record.originDevice,
            ),
          );
          for (final source in record.sources) {
            await _exports.insertExportSourceRow(
              ExportRecordSourcesCompanion.insert(
                exportId: record.id,
                ordinal: source.ordinal,
                versionId: source.versionId,
              ),
            );
            // A retained artifact keeps its sources rebuildable (§11.7).
            if (record.retainArtifact && record.artifactBlobId != null) {
              await _versions.insertPin(
                _pinCompanion(
                  Pin(
                    versionId: source.versionId,
                    reason: PinReason.exportRetained,
                    refId: record.id,
                  ),
                  record.createdAt,
                ),
              );
            }
          }
        }),
      );

  @override
  Future<Result<List<BlobId>, VaultFailure>> releaseExportArtifacts({
    required DateTime now,
  }) => guardDb(
    'releaseExportArtifacts',
    () => _db.transaction(() async {
      final rows = await _exports.releasableExportRows(now);
      final purgable = <BlobId>[];
      for (final row in rows) {
        final blobId = row.artifactBlobId!;
        await _exports.detachArtifact(row.id);
        await _versions.deletePinsByRef(PinReason.exportRetained.dbValue, row.id);
        await _versions.deleteBlobRow(blobId);
        purgable.add(blobId);
      }
      return purgable;
    }),
  );

  @override
  Future<Result<ExportRecord?, VaultFailure>> findExportRecord(ExportId id) =>
      guardDb('findExportRecord', () async {
        final row = await _exports.exportRowById(id);
        if (row == null) {
          return null;
        }
        final sourceRows = await _exports.sourcesForExport(id);
        return ExportRecord(
          id: row.id,
          entryId: row.entryId,
          request: decodeExportRequest(row.requestJson),
          format: row.format,
          layout: row.layout,
          paperSize: row.paperSize,
          outWidth: row.outWidth,
          outHeight: row.outHeight,
          dpi: row.dpi,
          quality: row.quality,
          targetBytes: row.targetBytes,
          maxBytes: row.maxBytes,
          actualBytes: row.actualBytes,
          pageCount: row.pageCount,
          status: row.status,
          failureCode: row.failureCode,
          warningsJson: row.warningsJson,
          durationMs: row.durationMs,
          artifactBlobId: row.artifactBlobId,
          retainArtifact: row.retainArtifact,
          artifactExpiresAt: row.artifactExpiresAt,
          createdAt: row.createdAt,
          originDevice: row.originDevice,
          sources: sourceRows
              .map((s) => (versionId: s.versionId, ordinal: s.ordinal))
              .toList(growable: false),
        );
      });

  @override
  Future<Result<List<ExportRecordSummary>, VaultFailure>> listExportRecords(
    EntryId entryId,
  ) => guardDb('listExportRecords', () async {
    final rows = await _exports.exportSummariesFor(entryId);
    return rows
        .map(
          (row) => ExportRecordSummary(
            id: row.id,
            format: row.format,
            status: row.status,
            createdAt: row.createdAt,
            actualBytes: row.actualBytes,
            pageCount: row.pageCount,
            artifactBlobId: row.artifactBlobId,
          ),
        )
        .toList(growable: false);
  });

  // ── Sealing of metadata columns ────────────────────────────────────────

  Future<Uint8List?> _sealText(String? plaintext) async {
    if (plaintext == null) {
      return null;
    }
    final crypto = _crypto;
    if (crypto == null) {
      return utf8.encode(plaintext);
    }
    final sealed = await crypto.sealSmall(
      utf8.encode(plaintext),
      keyEpoch: _activeKeyEpoch(),
      purpose: EnvelopePurpose.meta,
    );
    return sealed.fold(
      Uint8List.fromList,
      (failure) => throw PersistenceException(failure),
    );
  }

  Future<String?> _openText(Uint8List? stored) async {
    if (stored == null) {
      return null;
    }
    final crypto = _crypto;
    if (crypto == null) {
      return utf8.decode(stored);
    }
    final opened = await crypto.openSmall(
      stored,
      expectedPurpose: EnvelopePurpose.meta,
    );
    return opened.fold(
      utf8.decode,
      (failure) => throw PersistenceException(failure),
    );
  }

  Future<List<String>> _openTags(Uint8List? stored) async {
    final text = await _openText(stored);
    if (text == null) {
      return const [];
    }
    return (jsonDecode(text) as List).cast<String>();
  }

  // ── Row ↔ entity mapping ───────────────────────────────────────────────

  Future<List<VaultEntrySummary>> _summariesFrom(
    List<EntrySummaryRow> rows,
  ) async {
    final summaries = <VaultEntrySummary>[];
    for (final row in rows) {
      summaries.add(
        VaultEntrySummary(
          id: row.id,
          type: EntryType.fromDbValue(row.type) ?? _badType(row.type),
          title: await _openText(row.titleEnc),
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
          assetCount: row.assetCount,
          hasOpenConflict: row.hasOpenConflict,
          coverVersionId: row.coverVersionId,
        ),
      );
    }
    return summaries;
  }

  Future<void> _insertNewAsset(NewAsset asset) async {
    final version = asset.originalVersion;
    final blobId = version.blobId;
    if (blobId == null) {
      throw PersistenceException(
        EntryInvariantViolated('ORIGINAL ${version.id} has no blob (I2)'),
      );
    }
    if (asset.blob.id != blobId) {
      throw PersistenceException(
        InvalidAsset('NewAsset.blob ${asset.blob.id} does not back $blobId'),
      );
    }
    if (version.assetId != asset.id) {
      throw PersistenceException(
        EntryInvariantViolated(
          'ORIGINAL ${version.id} belongs to ${version.assetId}, '
          'not ${asset.id}',
        ),
      );
    }
    await _versions.insertBlob(_blobCompanion(asset.blob, asset.createdAt));
    await _entries.insertAsset(
      AssetsCompanion.insert(
        id: asset.id,
        entryId: asset.entryId,
        role: asset.role.dbValue,
        ordinal: Value(asset.ordinal),
        createdAt: asset.createdAt,
        updatedAt: asset.createdAt,
        updatedHlc: asset.hlc.toSortableString(),
        originDevice: asset.originDevice,
      ),
    );
    await _versions.insertVersion(_versionCompanion(version));
    await _entries.updateAsset(
      asset.id,
      AssetsCompanion(currentVersionId: Value(version.id)),
    );
    await _enqueueUpload(blobId, asset.createdAt);
  }

  Future<void> _enqueueUpload(String blobId, DateTime now) =>
      _sync.insertQueueRow(
        SyncQueueCompanion.insert(
          opType: SyncQueueOpType.uploadBlob.dbValue,
          targetKind: 'BLOB',
          targetId: blobId,
          idempotencyKey: 'blob:$blobId',
          nextAttemptAt: now,
          createdAt: now,
        ),
      );

  Future<void> _touchEntry(String entryId, Hlc hlc, DateTime now) =>
      _entries.updateEntryRow(
        entryId,
        VaultEntriesCompanion(
          updatedAt: Value(now),
          updatedHlc: Value(hlc.toSortableString()),
        ),
      );

  BlobsCompanion _blobCompanion(BlobRef blob, DateTime now) =>
      BlobsCompanion.insert(
        id: blob.id,
        storageClass: blob.storageClass.dbValue,
        relPath: blob.relPath,
        envelopeVersion: Value(blob.envelopeVersion),
        keyEpoch: blob.keyEpoch,
        wrappedDek: Uint8List.fromList(blob.wrappedDek),
        ciphertextSize: blob.ciphertextSize,
        plaintextSize: blob.plaintextSize,
        ciphertextSha256: _hexToBytes(blob.ciphertextSha256),
        localState: 'PRESENT',
        createdAt: now,
      );

  VersionPinsCompanion _pinCompanion(Pin pin, DateTime now) =>
      VersionPinsCompanion.insert(
        versionId: pin.versionId,
        reason: pin.reason.dbValue,
        refId: Value(pin.refId),
        createdAt: now,
      );

  AssetVersionsCompanion _versionCompanion(AssetVersion version) =>
      AssetVersionsCompanion.insert(
        id: version.id,
        assetId: version.assetId,
        parentVersionId: Value(version.parentVersionId),
        kind: version.kind.dbValue,
        seq: version.seq,
        blobId: Value(version.blobId),
        recipeJson: Value(version.recipe?.toJson()),
        recipeDeterministic: Value(version.recipeDeterministic),
        width: version.meta.width,
        height: version.meta.height,
        mime: version.meta.mime,
        plaintextSha256: _hexToBytes(version.meta.plaintextSha256),
        plaintextSize: version.meta.byteSize,
        createdAt: version.createdAt,
        createdHlc: version.createdHlc.toSortableString(),
        originDevice: version.originDevice,
        evictedAt: Value(version.evictedAt),
      );

  AssetVersion _versionFrom(AssetVersionData row, bool isPinned) =>
      AssetVersion(
        id: row.id,
        assetId: row.assetId,
        parentVersionId: row.parentVersionId,
        kind: VersionKind.fromDbValue(row.kind) ?? VersionKind.derived,
        seq: row.seq,
        blobId: row.blobId,
        recipe: row.recipeJson == null
            ? null
            : EditRecipe.fromJson(row.recipeJson!),
        recipeDeterministic: row.recipeDeterministic,
        meta: ImageMeta(
          width: row.width,
          height: row.height,
          mime: row.mime,
          plaintextSha256: hex.encode(row.plaintextSha256),
          byteSize: row.plaintextSize,
        ),
        createdAt: row.createdAt,
        createdHlc: Hlc.parse(row.createdHlc),
        originDevice: row.originDevice,
        evictedAt: row.evictedAt,
        isPinned: isPinned,
      );

  Future<VaultEntryData> _requireEntryRow(String id) async {
    final row = await _entries.entryById(id);
    if (row == null) {
      throw PersistenceException(InvalidAsset('no entry with id $id'));
    }
    return row;
  }

  Future<VaultEntry> _requireEntry(String id) async {
    final entry = await _loadEntry(id);
    if (entry == null) {
      throw PersistenceException(InvalidAsset('no entry with id $id'));
    }
    return entry;
  }

  Future<Asset> _requireAsset(String id) async {
    final asset = await _loadAsset(id);
    if (asset == null) {
      throw PersistenceException(InvalidAsset('no asset with id $id'));
    }
    return asset;
  }

  Future<VaultEntry?> _loadEntry(String id) async {
    final entryRow = await _entries.entryById(id);
    if (entryRow == null) {
      return null;
    }
    final assets = await _loadAssetsFor(id, includeDeleted: true);
    return VaultEntry(
      id: entryRow.id,
      type: EntryType.fromDbValue(entryRow.type) ?? _badType(entryRow.type),
      title: await _openText(entryRow.titleEnc),
      note: await _openText(entryRow.noteEnc),
      tags: await _openTags(entryRow.tagsEnc),
      createdAt: entryRow.createdAt,
      updatedAt: entryRow.updatedAt,
      updatedHlc: Hlc.parse(entryRow.updatedHlc),
      originDevice: entryRow.originDevice,
      deletedAt: entryRow.deletedAt,
      hasOpenConflict: await _sync.hasOpenConflict(id),
      assets: assets,
    );
  }

  Future<List<Asset>> _loadAssetsFor(
    String entryId, {
    bool includeDeleted = false,
  }) async {
    final rows = await _entries.assetsForEntry(
      entryId,
      includeDeleted: includeDeleted,
    );
    final assets = <Asset>[];
    for (final row in rows) {
      assets.add(await _assetFrom(row));
    }
    return assets;
  }

  Future<Asset?> _loadAsset(String id) async {
    final row = await _entries.assetById(id);
    return row == null ? null : _assetFrom(row);
  }

  Future<List<AssetVersion>> _loadVersions(String assetId) async {
    final rows = await _versions.versionsForAsset(assetId);
    final pins = await _versions.pinsForAsset(assetId);
    final pinnedIds = pins.map((p) => p.versionId).toSet();
    return rows
        .map((row) => _versionFrom(row, pinnedIds.contains(row.id)))
        .toList(growable: false);
  }

  Future<Asset> _assetFrom(AssetData row) async {
    final currentVersionId = row.currentVersionId;
    if (currentVersionId == null) {
      throw PersistenceException(
        EntryInvariantViolated('asset ${row.id} has no current version (I3)'),
      );
    }
    return Asset(
      id: row.id,
      entryId: row.entryId,
      role: AssetRole.fromDbValue(row.role) ?? AssetRole.primary,
      ordinal: row.ordinal,
      currentVersionId: currentVersionId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      updatedHlc: Hlc.parse(row.updatedHlc),
      originDevice: row.originDevice,
      versions: await _loadVersions(row.id),
      deletedAt: row.deletedAt,
      hasOpenConflict: await _sync.hasOpenConflict(
        row.id,
        kind: ConflictKind.assetCurrent.dbValue,
      ),
    );
  }

  Future<void> _insertTombstone(Tombstone tombstone) =>
      _sync.insertTombstoneRow(
        TombstonesCompanion.insert(
          entityKind: tombstone.entityKind.dbValue,
          entityId: tombstone.entityId,
          deletedHlc: tombstone.deletedHlc.toSortableString(),
          originDevice: tombstone.originDevice,
          purgeAfter: tombstone.purgeAfter,
        ),
      );

  /// Ordinals are parked here mid-reorder; no document has this many pages.
  static const _reorderParkingOffset = 1 << 20;

  /// Digests are hex strings in the domain and raw 32-byte BLOBs in the
  /// schema (§6.1). An empty or malformed string stores as an empty blob
  /// rather than failing the whole write.
  static Uint8List _hexToBytes(String hexString) {
    if (hexString.isEmpty || hexString.length.isOdd) {
      return Uint8List(0);
    }
    return Uint8List.fromList(hex.decode(hexString));
  }

  static EntryType _badType(String value) =>
      throw FormatException('Unknown entry type: $value');
}
