// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncQueueTable get syncQueue => attachedDatabase.syncQueue;
  $KeyEpochsTable get keyEpochs => attachedDatabase.keyEpochs;
  $BlobsTable get blobs => attachedDatabase.blobs;
  $CloudObjectsTable get cloudObjects => attachedDatabase.cloudObjects;
  $DevicesTable get devices => attachedDatabase.devices;
  $SyncLogSegmentsTable get syncLogSegments => attachedDatabase.syncLogSegments;
  $SyncLogOpsTable get syncLogOps => attachedDatabase.syncLogOps;
  $SyncCursorTable get syncCursor => attachedDatabase.syncCursor;
  $ConflictsTable get conflicts => attachedDatabase.conflicts;
  $TombstonesTable get tombstones => attachedDatabase.tombstones;
  SyncDaoManager get managers => SyncDaoManager(this);
}

class SyncDaoManager {
  final _$SyncDaoMixin _db;
  SyncDaoManager(this._db);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db.attachedDatabase, _db.syncQueue);
  $$KeyEpochsTableTableManager get keyEpochs =>
      $$KeyEpochsTableTableManager(_db.attachedDatabase, _db.keyEpochs);
  $$BlobsTableTableManager get blobs =>
      $$BlobsTableTableManager(_db.attachedDatabase, _db.blobs);
  $$CloudObjectsTableTableManager get cloudObjects =>
      $$CloudObjectsTableTableManager(_db.attachedDatabase, _db.cloudObjects);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$SyncLogSegmentsTableTableManager get syncLogSegments =>
      $$SyncLogSegmentsTableTableManager(
        _db.attachedDatabase,
        _db.syncLogSegments,
      );
  $$SyncLogOpsTableTableManager get syncLogOps =>
      $$SyncLogOpsTableTableManager(_db.attachedDatabase, _db.syncLogOps);
  $$SyncCursorTableTableManager get syncCursor =>
      $$SyncCursorTableTableManager(_db.attachedDatabase, _db.syncCursor);
  $$ConflictsTableTableManager get conflicts =>
      $$ConflictsTableTableManager(_db.attachedDatabase, _db.conflicts);
  $$TombstonesTableTableManager get tombstones =>
      $$TombstonesTableTableManager(_db.attachedDatabase, _db.tombstones);
}
