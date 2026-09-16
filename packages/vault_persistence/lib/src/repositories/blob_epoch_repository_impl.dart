/// `BlobEpochRepository` over Drift (§8.6 step 4): the rotation job's
/// view of the `blobs` table.
library;

import 'package:drift/drift.dart';
import 'package:vault_domain/vault_domain.dart';

import '../database/app_database.dart';
import '../error_boundary.dart';

final class BlobEpochRepositoryImpl implements BlobEpochRepository {
  BlobEpochRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Result<int, VaultFailure>> countBelowEpoch(int epoch) =>
      guardDb('countBelowEpoch', () async {
        final count = _db.blobs.id.count();
        final query = _db.selectOnly(_db.blobs)
          ..addColumns([count])
          ..where(_db.blobs.keyEpoch.isSmallerThanValue(epoch));
        final row = await query.getSingle();
        return row.read(count) ?? 0;
      });

  @override
  Future<Result<List<BlobEpochRef>, VaultFailure>> listBelowEpoch(
    int epoch, {
    int limit = 200,
  }) => guardDb('listBelowEpoch', () async {
    final query = _db.select(_db.blobs)
      ..where((t) => t.keyEpoch.isSmallerThanValue(epoch))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(limit);
    final rows = await query.get();
    return [
      for (final row in rows)
        BlobEpochRef(
          id: row.id,
          purpose: _purposeFor(row.storageClass),
          keyEpoch: row.keyEpoch,
        ),
    ];
  });

  @override
  Future<Result<void, VaultFailure>> updateBlobEpoch(
    BlobId blobId, {
    required int toEpoch,
    required List<int> wrappedDek,
  }) => guardDb(
    'updateBlobEpoch',
    () => (_db.update(
      _db.blobs,
    )..where((t) => t.id.equals(blobId))).write(
      BlobsCompanion(
        keyEpoch: Value(toEpoch),
        wrappedDek: Value(Uint8List.fromList(wrappedDek)),
      ),
    ),
  );

  EnvelopePurpose _purposeFor(String storageClass) =>
      switch (StorageClass.fromDbValue(storageClass)) {
        StorageClass.asset => EnvelopePurpose.asset,
        StorageClass.thumbnail => EnvelopePurpose.thumbnail,
        StorageClass.exportArtifact => EnvelopePurpose.exportArtifact,
        StorageClass.syncLog => EnvelopePurpose.logSegment,
        null => EnvelopePurpose.asset,
      };
}
