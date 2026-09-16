/// `ThumbnailIndex` implementation over the `thumbnails` + `blobs` tables.
library;

import 'package:convert/convert.dart' show hex;
import 'package:drift/drift.dart';
import 'package:vault_domain/vault_domain.dart';

import '../database/app_database.dart';
import '../error_boundary.dart';

final class ThumbnailIndexImpl implements ThumbnailIndex {
  ThumbnailIndexImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<ThumbnailRecord?, VaultFailure>> find(
    VersionId versionId,
    ThumbnailSizeClass sizeClass,
  ) => guardDb('thumbnail.find', () async {
    final row = await _slot(versionId, sizeClass).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final blob = await _db.versionsDao.blobById(row.blobId);
    return _from(row, blob?.ciphertextSize ?? 0);
  });

  @override
  Future<Result<ThumbnailRecord, VaultFailure>> record({
    required String id,
    required VersionId versionId,
    required ThumbnailSizeClass sizeClass,
    required BlobRef blob,
    required int width,
    required int height,
    required DateTime now,
  }) => guardDb('thumbnail.record', () async {
    await _db.transaction(() async {
      // Replace a stale entry for the same slot, blob row included.
      final stale = await _slot(versionId, sizeClass).getSingleOrNull();
      if (stale != null) {
        await (_db.delete(
          _db.thumbnails,
        )..where((t) => t.id.equals(stale.id))).go();
        await _deleteBlobRow(stale.blobId);
      }
      await _db.versionsDao.insertBlob(
        BlobsCompanion.insert(
          id: blob.id,
          storageClass: StorageClass.thumbnail.dbValue,
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
      await _db
          .into(_db.thumbnails)
          .insert(
            ThumbnailsCompanion.insert(
              id: id,
              versionId: versionId,
              sizeClass: sizeClass.dbValue,
              blobId: blob.id,
              width: width,
              height: height,
              createdAt: now,
              lastAccessedAt: now,
            ),
          );
    });
    return ThumbnailRecord(
      id: id,
      versionId: versionId,
      sizeClass: sizeClass,
      blobId: blob.id,
      width: width,
      height: height,
      byteSize: blob.ciphertextSize,
      createdAt: now,
      lastAccessedAt: now,
    );
  });

  @override
  Future<Result<void, VaultFailure>> touch(String id, DateTime at) => guardDb(
    'thumbnail.touch',
    () => (_db.update(_db.thumbnails)..where((t) => t.id.equals(id))).write(
      ThumbnailsCompanion(lastAccessedAt: Value(at)),
    ),
  );

  @override
  Future<Result<List<BlobId>, VaultFailure>> removeForAsset(AssetId assetId) =>
      guardDb(
        'thumbnail.removeForAsset',
        () => _db.transaction(() async {
          final versionIds = _db.selectOnly(_db.assetVersions)
            ..addColumns([_db.assetVersions.id])
            ..where(_db.assetVersions.assetId.equals(assetId));
          final rows = await (_db.select(
            _db.thumbnails,
          )..where((t) => t.versionId.isInQuery(versionIds))).get();
          for (final row in rows) {
            await (_db.delete(
              _db.thumbnails,
            )..where((t) => t.id.equals(row.id))).go();
            await _deleteBlobRow(row.blobId);
          }
          return rows.map((r) => r.blobId).toList(growable: false);
        }),
      );

  @override
  Future<Result<BlobId?, VaultFailure>> remove(String id) => guardDb(
    'thumbnail.remove',
    () => _db.transaction(() async {
      final row = await (_db.select(
        _db.thumbnails,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) {
        return null;
      }
      await (_db.delete(_db.thumbnails)..where((t) => t.id.equals(id))).go();
      await _deleteBlobRow(row.blobId);
      return row.blobId;
    }),
  );

  @override
  Future<Result<List<ThumbnailRecord>, VaultFailure>> leastRecentlyUsed({
    int limit = 100,
  }) => guardDb('thumbnail.lru', () async {
    final query =
        _db.select(_db.thumbnails).join([
            innerJoin(_db.blobs, _db.blobs.id.equalsExp(_db.thumbnails.blobId)),
          ])
          ..orderBy([OrderingTerm.asc(_db.thumbnails.lastAccessedAt)])
          ..limit(limit);
    final rows = await query.get();
    return rows
        .map(
          (r) => _from(
            r.readTable(_db.thumbnails),
            r.readTable(_db.blobs).ciphertextSize,
          ),
        )
        .toList(growable: false);
  });

  @override
  Future<Result<int, VaultFailure>> totalBytes() => guardDb(
    'thumbnail.totalBytes',
    () async {
      final sum = _db.blobs.ciphertextSize.sum();
      final query = _db.selectOnly(_db.blobs)
        ..addColumns([sum])
        ..where(_db.blobs.storageClass.equals(StorageClass.thumbnail.dbValue));
      final row = await query.getSingleOrNull();
      return row?.read(sum) ?? 0;
    },
  );

  SimpleSelectStatement<$ThumbnailsTable, ThumbnailData> _slot(
    VersionId versionId,
    ThumbnailSizeClass sizeClass,
  ) => _db.select(_db.thumbnails)
    ..where(
      (t) =>
          t.versionId.equals(versionId) & t.sizeClass.equals(sizeClass.dbValue),
    );

  Future<void> _deleteBlobRow(String blobId) =>
      (_db.delete(_db.blobs)..where((t) => t.id.equals(blobId))).go();

  static ThumbnailRecord _from(ThumbnailData row, int byteSize) =>
      ThumbnailRecord(
        id: row.id,
        versionId: row.versionId,
        sizeClass:
            ThumbnailSizeClass.fromDbValue(row.sizeClass) ??
            ThumbnailSizeClass.s,
        blobId: row.blobId,
        width: row.width,
        height: row.height,
        byteSize: byteSize,
        createdAt: row.createdAt,
        lastAccessedAt: row.lastAccessedAt,
      );
}
