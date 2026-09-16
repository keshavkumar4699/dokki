// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'versions_dao.dart';

// ignore_for_file: type=lint
mixin _$VersionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DevicesTable get devices => attachedDatabase.devices;
  $VaultEntriesTable get vaultEntries => attachedDatabase.vaultEntries;
  $AssetsTable get assets => attachedDatabase.assets;
  $KeyEpochsTable get keyEpochs => attachedDatabase.keyEpochs;
  $BlobsTable get blobs => attachedDatabase.blobs;
  $AssetVersionsTable get assetVersions => attachedDatabase.assetVersions;
  $VersionPinsTable get versionPins => attachedDatabase.versionPins;
  $ThumbnailsTable get thumbnails => attachedDatabase.thumbnails;
  VersionsDaoManager get managers => VersionsDaoManager(this);
}

class VersionsDaoManager {
  final _$VersionsDaoMixin _db;
  VersionsDaoManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$VaultEntriesTableTableManager get vaultEntries =>
      $$VaultEntriesTableTableManager(_db.attachedDatabase, _db.vaultEntries);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$KeyEpochsTableTableManager get keyEpochs =>
      $$KeyEpochsTableTableManager(_db.attachedDatabase, _db.keyEpochs);
  $$BlobsTableTableManager get blobs =>
      $$BlobsTableTableManager(_db.attachedDatabase, _db.blobs);
  $$AssetVersionsTableTableManager get assetVersions =>
      $$AssetVersionsTableTableManager(_db.attachedDatabase, _db.assetVersions);
  $$VersionPinsTableTableManager get versionPins =>
      $$VersionPinsTableTableManager(_db.attachedDatabase, _db.versionPins);
  $$ThumbnailsTableTableManager get thumbnails =>
      $$ThumbnailsTableTableManager(_db.attachedDatabase, _db.thumbnails);
}
