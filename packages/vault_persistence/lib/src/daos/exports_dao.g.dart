// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exports_dao.dart';

// ignore_for_file: type=lint
mixin _$ExportsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DevicesTable get devices => attachedDatabase.devices;
  $VaultEntriesTable get vaultEntries => attachedDatabase.vaultEntries;
  $KeyEpochsTable get keyEpochs => attachedDatabase.keyEpochs;
  $BlobsTable get blobs => attachedDatabase.blobs;
  $ExportRecordsTable get exportRecords => attachedDatabase.exportRecords;
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetVersionsTable get assetVersions => attachedDatabase.assetVersions;
  $ExportRecordSourcesTable get exportRecordSources =>
      attachedDatabase.exportRecordSources;
  ExportsDaoManager get managers => ExportsDaoManager(this);
}

class ExportsDaoManager {
  final _$ExportsDaoMixin _db;
  ExportsDaoManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$VaultEntriesTableTableManager get vaultEntries =>
      $$VaultEntriesTableTableManager(_db.attachedDatabase, _db.vaultEntries);
  $$KeyEpochsTableTableManager get keyEpochs =>
      $$KeyEpochsTableTableManager(_db.attachedDatabase, _db.keyEpochs);
  $$BlobsTableTableManager get blobs =>
      $$BlobsTableTableManager(_db.attachedDatabase, _db.blobs);
  $$ExportRecordsTableTableManager get exportRecords =>
      $$ExportRecordsTableTableManager(_db.attachedDatabase, _db.exportRecords);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetVersionsTableTableManager get assetVersions =>
      $$AssetVersionsTableTableManager(_db.attachedDatabase, _db.assetVersions);
  $$ExportRecordSourcesTableTableManager get exportRecordSources =>
      $$ExportRecordSourcesTableTableManager(
        _db.attachedDatabase,
        _db.exportRecordSources,
      );
}
