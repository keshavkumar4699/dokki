/// DAO for `asset_versions`, `version_pins`, `blobs` and `thumbnails`.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'versions_dao.g.dart';

@DriftAccessor(tables: [AssetVersions, VersionPins, Blobs, Thumbnails])
class VersionsDao extends DatabaseAccessor<AppDatabase>
    with _$VersionsDaoMixin {
  VersionsDao(super.db);

  Future<void> insertVersion(AssetVersionsCompanion companion) =>
      into(assetVersions).insert(companion);

  /// Replay inserts are insert-or-ignore: a second pass is a no-op (P6).
  Future<void> insertVersionOrIgnore(AssetVersionsCompanion companion) =>
      into(assetVersions).insert(companion, mode: InsertMode.insertOrIgnore);

  Future<AssetVersionData?> versionById(String id) =>
      (select(assetVersions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// All versions of one asset, oldest `seq` first.
  Future<List<AssetVersionData>> versionsForAsset(String assetId) {
    final query = select(assetVersions)
      ..where((t) => t.assetId.equals(assetId))
      ..orderBy([(t) => OrderingTerm.asc(t.seq)]);
    return query.get();
  }

  Future<int> maxSeqForAsset(String assetId) async {
    final seq = assetVersions.seq.max();
    final query = selectOnly(assetVersions)
      ..addColumns([seq])
      ..where(assetVersions.assetId.equals(assetId));
    final row = await query.getSingleOrNull();
    return row?.read(seq) ?? 0;
  }

  /// Materialized blob ids of the given versions (before eviction).
  Future<List<String>> blobIdsOf(List<String> versionIds) {
    final query = selectOnly(assetVersions)
      ..addColumns([assetVersions.blobId])
      ..where(
        assetVersions.id.isIn(versionIds) & assetVersions.blobId.isNotNull(),
      );
    return query.map((row) => row.read(assetVersions.blobId)!).get();
  }

  /// Re-attaches a blob to an evicted row (§10.3 re-materialization).
  Future<void> rematerializeVersionRow(String versionId, String blobId) =>
      (update(assetVersions)..where((t) => t.id.equals(versionId))).write(
        AssetVersionsCompanion(
          blobId: Value(blobId),
          evictedAt: const Value(null),
        ),
      );

  /// Marks blob rows whose file is about to be purged (§6.2 `local_state`).
  Future<void> markBlobsEvicted(List<String> blobIds) =>
      (update(blobs)..where((t) => t.id.isIn(blobIds))).write(
        const BlobsCompanion(localState: Value('EVICTED')),
      );

  /// Flips a REMOTE_ONLY blob to PRESENT after a verified download (§9.8).
  Future<void> markBlobPresentRow(String blobId) =>
      (update(blobs)..where((t) => t.id.equals(blobId))).write(
        const BlobsCompanion(localState: Value('PRESENT')),
      );

  /// Soft-evicts rows; the CHECK constraint rejects ORIGINAL versions (I2).
  Future<void> evictVersionBlobs(List<String> versionIds, DateTime at) =>
      (update(assetVersions)..where((t) => t.id.isIn(versionIds))).write(
        AssetVersionsCompanion(blobId: const Value(null), evictedAt: Value(at)),
      );

  Future<void> insertBlob(BlobsCompanion companion) =>
      into(blobs).insert(companion);

  /// Replay inserts are insert-or-ignore: a second pass is a no-op (P6).
  Future<void> insertBlobOrIgnore(BlobsCompanion companion) =>
      into(blobs).insert(companion, mode: InsertMode.insertOrIgnore);

  Future<BlobData?> blobById(String id) =>
      (select(blobs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertPin(VersionPinsCompanion companion) =>
      into(versionPins).insert(companion, mode: InsertMode.insertOrIgnore);

  Future<void> deletePin(String versionId, String reason, String refId) =>
      (delete(versionPins)..where(
            (t) =>
                t.versionId.equals(versionId) &
                t.reason.equals(reason) &
                t.refId.equals(refId),
          ))
          .go();

  /// Drops every pin a reference holder (an export, a conflict) placed.
  Future<void> deletePinsByRef(String reason, String refId) =>
      (delete(versionPins)
            ..where((t) => t.reason.equals(reason) & t.refId.equals(refId)))
          .go();

  Future<void> deleteBlobRow(String id) =>
      (delete(blobs)..where((t) => t.id.equals(id))).go();

  Future<List<VersionPinData>> pinsForVersion(String versionId) =>
      (select(versionPins)..where((t) => t.versionId.equals(versionId))).get();

  Future<List<VersionPinData>> pinsForAsset(String assetId) {
    final query = select(versionPins).join([
      innerJoin(
        assetVersions,
        assetVersions.id.equalsExp(versionPins.versionId),
      ),
    ])..where(assetVersions.assetId.equals(assetId));
    return query.map((row) => row.readTable(versionPins)).get();
  }
}
