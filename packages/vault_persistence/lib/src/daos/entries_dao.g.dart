// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entries_dao.dart';

// ignore_for_file: type=lint
mixin _$EntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DevicesTable get devices => attachedDatabase.devices;
  $VaultEntriesTable get vaultEntries => attachedDatabase.vaultEntries;
  $AssetsTable get assets => attachedDatabase.assets;
  EntriesDaoManager get managers => EntriesDaoManager(this);
}

class EntriesDaoManager {
  final _$EntriesDaoMixin _db;
  EntriesDaoManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$VaultEntriesTableTableManager get vaultEntries =>
      $$VaultEntriesTableTableManager(_db.attachedDatabase, _db.vaultEntries);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
}
