// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'epochs_dao.dart';

// ignore_for_file: type=lint
mixin _$EpochsDaoMixin on DatabaseAccessor<AppDatabase> {
  $KeyEpochsTable get keyEpochs => attachedDatabase.keyEpochs;
  EpochsDaoManager get managers => EpochsDaoManager(this);
}

class EpochsDaoManager {
  final _$EpochsDaoMixin _db;
  EpochsDaoManager(this._db);
  $$KeyEpochsTableTableManager get keyEpochs =>
      $$KeyEpochsTableTableManager(_db.attachedDatabase, _db.keyEpochs);
}
