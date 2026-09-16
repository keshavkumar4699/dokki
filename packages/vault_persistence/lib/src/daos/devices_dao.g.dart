// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devices_dao.dart';

// ignore_for_file: type=lint
mixin _$DevicesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DevicesTable get devices => attachedDatabase.devices;
  $AppMetaTable get appMeta => attachedDatabase.appMeta;
  DevicesDaoManager get managers => DevicesDaoManager(this);
}

class DevicesDaoManager {
  final _$DevicesDaoMixin _db;
  DevicesDaoManager(this._db);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db.attachedDatabase, _db.appMeta);
}
