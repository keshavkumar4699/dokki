/// `SyncApplyPort` implementation over Drift: the write surface the merge
/// reducer replays remote ops against (§9.5).
///
/// Every method is idempotent — replaying the same op twice is a no-op
/// (P6). LWW decisions compare the stored `updated_hlc` against the op's
/// HLC inside one transaction, so a replay racing a local edit cannot
/// interleave.
library;

import 'package:convert/convert.dart' show hex;
import 'package:drift/drift.dart';
import 'package:vault_domain/vault_domain.dart';

import '../daos/entries_dao.dart';
import '../daos/sync_dao.dart';
import '../daos/versions_dao.dart';
import '../database/app_database.dart';
import '../error_boundary.dart';

/// Two-pass reorder parking offset, matching `EntryRepositoryImpl` (kept
/// identical so a local reorder and a replayed one interleave safely).
const _reorderParkingOffset = 1 << 20;

final class SyncApplyRepositoryImpl implements SyncApplyPort {
  SyncApplyRepositoryImpl(this._db);

  final AppDatabase _db;

  EntriesDao get _entries => _db.entriesDao;
  VersionsDao get _versions => _db.versionsDao;
  SyncDao get _sync => _db.syncDao;

  // ── Reads ────────────────────────────────────────────────────────────

  @override
  Future<Result<Hlc?, VaultFailure>> entryHlc(EntryId id) =>
      guardDb('entryHlc', () async {
        final row = await _entries.entryById(id);
        return row == null ? null : Hlc.parse(row.updatedHlc);
      });

  @override
  Future<Result<PointerState?, VaultFailure>> currentPointer(AssetId id) =>
      guardDb('currentPointer', () async {
        final row = await _entries.assetById(id);
        final versionId = row?.currentVersionId;
        if (row == null || versionId == null) {
          return null;
        }
        return PointerState(
          versionId: versionId,
          hlc: Hlc.parse(row.updatedHlc),
        );
      });

  @override
  Future<Result<bool, VaultFailure>> versionExists(VersionId id) =>
      guardDb('versionExists', () async => await _versions.versionById(id) != null);

  @override
  Future<Result<List<VersionId>, VaultFailure>> versionLineage(
    VersionId id,
  ) => guardDb('versionLineage', () async {
    final lineage = <VersionId>[];
    var current = id;
    for (var hops = 0; hops < 64; hops++) {
      final row = await _versions.versionById(current);
      if (row == null) {
        break;
      }
      lineage.add(row.id);
      final parent = row.parentVersionId;
      if (parent == null) {
        break;
      }
      current = parent;
    }
    return lineage;
  });

  @override
  Future<Result<bool, VaultFailure>> assetExists(AssetId id) =>
      guardDb('assetExists', () async => await _entries.assetById(id) != null);

  // ── Application ──────────────────────────────────────────────────────

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
  }) => guardDb('upsertEntryRemote', () => _db.transaction(() async {
    final existing = await _entries.entryById(id);
    if (existing == null) {
      await _entries.insertEntry(
        VaultEntriesCompanion.insert(
          id: id,
          type: type,
          titleEnc: Value(_blobOrNull(sealedTitle)),
          noteEnc: Value(_blobOrNull(sealedNote)),
          tagsEnc: Value(_blobOrNull(sealedTags)),
          createdAt: createdAt,
          updatedAt: createdAt,
          updatedHlc: updatedHlc.toSortableString(),
          originDevice: originDevice,
          deletedAt: Value(deletedAt),
        ),
      );
      return true;
    }
    final localHlc = Hlc.parse(existing.updatedHlc);
    if (!updatedHlc.isAfter(localHlc)) {
      return false; // stale or replayed (P6)
    }
    await _entries.updateEntryRow(
      id,
      VaultEntriesCompanion(
        titleEnc: sealedTitle == null
            ? const Value.absent()
            : Value(_blobOrNull(sealedTitle)),
        noteEnc: sealedNote == null
            ? const Value.absent()
            : Value(_blobOrNull(sealedNote)),
        tagsEnc: sealedTags == null
            ? const Value.absent()
            : Value(_blobOrNull(sealedTags)),
        updatedAt: Value(createdAt),
        updatedHlc: Value(updatedHlc.toSortableString()),
        deletedAt: Value(deletedAt),
      ),
    );
    return true;
  }));

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
  }) => guardDb('upsertAssetRemote', () => _db.transaction(() async {
    final existing = await _entries.assetById(id);
    if (existing == null) {
      await _entries.insertAsset(
        AssetsCompanion.insert(
          id: id,
          entryId: entryId,
          role: role,
          ordinal: Value(ordinal),
          createdAt: createdAt,
          updatedAt: createdAt,
          updatedHlc: updatedHlc.toSortableString(),
          originDevice: originDevice,
          deletedAt: Value(deletedAt),
        ),
      );
      return true;
    }
    final localHlc = Hlc.parse(existing.updatedHlc);
    if (!updatedHlc.isAfter(localHlc)) {
      return false;
    }
    await _entries.updateAsset(
      id,
      AssetsCompanion(
        ordinal: Value(ordinal),
        updatedAt: Value(createdAt),
        updatedHlc: Value(updatedHlc.toSortableString()),
        deletedAt: Value(deletedAt),
      ),
    );
    return true;
  }));

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
  }) => guardDb(
    'addVersionRemote',
    () => _versions.insertVersionOrIgnore(
      AssetVersionsCompanion.insert(
        id: id,
        assetId: assetId,
        parentVersionId: Value(parentVersionId),
        kind: kind,
        seq: seq,
        blobId: Value(blobId),
        recipeJson: Value(recipeJson),
        recipeDeterministic: Value(recipeDeterministic),
        width: width,
        height: height,
        mime: mime,
        plaintextSha256: _hexToBytes(plaintextSha256),
        plaintextSize: plaintextSize,
        createdAt: createdAt,
        createdHlc: createdHlc.toSortableString(),
        originDevice: originDevice,
        evictedAt: Value(evictedAt),
      ),
    ),
  );

  @override
  Future<Result<void, VaultFailure>> setCurrentRemote({
    required AssetId assetId,
    required VersionId versionId,
    required Hlc hlc,
  }) => guardDb('setCurrentRemote', () async {
    await _entries.updateAsset(
      assetId,
      AssetsCompanion(
        currentVersionId: Value(versionId),
        updatedAt: Value(hlc.toDateTime()),
        updatedHlc: Value(hlc.toSortableString()),
      ),
    );
  });

  @override
  Future<Result<void, VaultFailure>> reorderPagesRemote({
    required EntryId entryId,
    required List<AssetId> order,
    required Hlc hlc,
  }) => guardDb('reorderPagesRemote', () => _db.transaction(() async {
    // Same two-pass dance as the local reorder (ux_assets_slot).
    for (var i = 0; i < order.length; i++) {
      await _entries.setAssetOrdinal(order[i], _reorderParkingOffset + i);
    }
    for (var i = 0; i < order.length; i++) {
      await _entries.setAssetOrdinal(order[i], i);
    }
    await _entries.updateEntryRow(
      entryId,
      VaultEntriesCompanion(
        updatedAt: Value(hlc.toDateTime()),
        updatedHlc: Value(hlc.toSortableString()),
      ),
    );
  }));

  @override
  Future<Result<bool, VaultFailure>> evictVersionRemote(
    VersionId id, {
    required DateTime evictedAt,
  }) => guardDb('evictVersionRemote', () => _db.transaction(() async {
    final row = await _versions.versionById(id);
    if (row == null || row.evictedAt != null) {
      return false; // unknown or already evicted (P6)
    }
    await _versions.evictVersionBlobs([id], evictedAt);
    final blobId = row.blobId;
    if (blobId != null) {
      await _versions.markBlobsEvicted([blobId]);
    }
    return true;
  }));

  @override
  Future<Result<void, VaultFailure>> applyTombstoneRemote({
    required TombstoneEntityKind entityKind,
    required String entityId,
    required Hlc deletedHlc,
    required DeviceId originDevice,
    required DateTime purgeAfter,
  }) => guardDb('applyTombstoneRemote', () => _db.transaction(() async {
    await _sync.insertTombstoneRow(
      TombstonesCompanion.insert(
        entityKind: entityKind.dbValue,
        entityId: entityId,
        deletedHlc: deletedHlc.toSortableString(),
        originDevice: originDevice,
        purgeAfter: purgeAfter,
      ),
    );
    final deletedAt = deletedHlc.toDateTime();
    switch (entityKind) {
      case TombstoneEntityKind.entry:
        final row = await _entries.entryById(entityId);
        if (row != null && row.deletedAt == null) {
          await _entries.updateEntryRow(
            entityId,
            VaultEntriesCompanion(
              deletedAt: Value(deletedAt),
              updatedAt: Value(deletedAt),
              updatedHlc: Value(deletedHlc.toSortableString()),
            ),
          );
        }
      case TombstoneEntityKind.asset:
        await _entries.markAssetDeleted(entityId, deletedAt);
      case TombstoneEntityKind.version ||
          TombstoneEntityKind.export:
        break; // covered by eviction / artifact expiry
    }
  }));

  @override
  Future<Result<void, VaultFailure>> pinVersion({
    required VersionId versionId,
    required String reason,
    required String refId,
  }) => guardDb(
    'pinVersion',
    () => _versions.insertPin(
      VersionPinsCompanion.insert(
        versionId: versionId,
        reason: reason,
        refId: Value(refId),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    ),
  );

  @override
  Future<Result<void, VaultFailure>> markBlobRemoteOnly({
    required BlobId blobId,
    required int keyEpoch,
    required int plaintextSize,
    required String plaintextSha256,
    required String ciphertextSha256,
    required DateTime now,
  }) => guardDb(
    'markBlobRemoteOnly',
    () => _versions.insertBlobOrIgnore(
      BlobsCompanion.insert(
        id: blobId,
        storageClass: StorageClass.asset.dbValue,
        relPath: 'blobs/${_fanOut(blobId)}/$blobId',
        keyEpoch: keyEpoch,
        wrappedDek: Uint8List(0), // re-read from the file header on download
        ciphertextSize: 0,
        plaintextSize: plaintextSize,
        ciphertextSha256: _hexToBytes(ciphertextSha256),
        localState: 'REMOTE_ONLY',
        createdAt: now,
      ),
    ),
  );

  // ── Internals ────────────────────────────────────────────────────────

  Uint8List? _blobOrNull(List<int>? bytes) =>
      bytes == null ? null : Uint8List.fromList(bytes);

  Uint8List _hexToBytes(String value) =>
      value.isEmpty ? Uint8List(0) : Uint8List.fromList(hex.decode(value));

  String _fanOut(BlobId id) =>
      id.length >= 2 ? id.substring(0, 2).toLowerCase() : '00';
}

extension on Hlc {
  DateTime toDateTime() =>
      DateTime.fromMillisecondsSinceEpoch(physicalMillis, isUtc: true);
}
