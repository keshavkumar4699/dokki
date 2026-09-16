/// The vault Drift database.
// DDL statements are naturally multi-line; adjacent string literals keep
// them readable without `+` noise.
// ignore_for_file: no_adjacent_strings_in_list
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../daos/devices_dao.dart';
import '../daos/entries_dao.dart';
import '../daos/epochs_dao.dart';
import '../daos/exports_dao.dart';
import '../daos/sync_dao.dart';
import '../daos/versions_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Raw DDL for indexes that the drift table DSL cannot express (§6.1–§6.4).
///
/// Non-partial unique constraints live in the table DSL (`uniqueKeys`); the
/// partial unique indexes enforcing invariants I1/I6, the single-self-device
/// rule and the single-active-key-epoch rule are created here.
const List<String> vaultIndexDdl = [
  'CREATE UNIQUE INDEX ux_devices_self ON devices(is_self) WHERE is_self = 1',
  'CREATE UNIQUE INDEX ux_key_epoch_active ON key_epochs(retired_at) '
      'WHERE retired_at IS NULL',
  'CREATE UNIQUE INDEX ux_assets_slot ON assets(entry_id, role, ordinal) '
      'WHERE deleted_at IS NULL',
  'CREATE UNIQUE INDEX ux_assets_singleton ON assets(entry_id, role) '
      "WHERE deleted_at IS NULL AND role IN ('PRIMARY','ID_FRONT','ID_BACK')",
  'CREATE UNIQUE INDEX ux_version_original ON asset_versions(asset_id) '
      "WHERE kind = 'ORIGINAL'",
  'CREATE UNIQUE INDEX ux_cloud_remote ON cloud_objects(remote_id) '
      'WHERE remote_id IS NOT NULL',
  'CREATE INDEX ix_entries_type_live ON vault_entries(type) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX ix_entries_updated ON vault_entries(updated_at DESC) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX ix_entries_hlc ON vault_entries(updated_hlc)',
  'CREATE INDEX ix_assets_entry ON assets(entry_id, ordinal) '
      'WHERE deleted_at IS NULL',
  'CREATE INDEX ix_versions_asset ON asset_versions(asset_id, created_at DESC)',
  'CREATE INDEX ix_versions_blob ON asset_versions(blob_id)',
  'CREATE INDEX ix_versions_live ON asset_versions(asset_id) '
      'WHERE evicted_at IS NULL',
  'CREATE INDEX ix_pins_version ON version_pins(version_id)',
  'CREATE INDEX ix_blobs_state ON blobs(local_state, storage_class)',
  'CREATE INDEX ix_thumb_lru ON thumbnails(last_accessed_at)',
  'CREATE INDEX ix_exports_entry ON export_records(entry_id, created_at DESC)',
  'CREATE INDEX ix_exports_recent ON export_records(created_at DESC)',
  'CREATE INDEX ix_exports_expiry ON export_records(artifact_expires_at) '
      'WHERE artifact_blob_id IS NOT NULL',
  'CREATE INDEX ix_export_src_version ON export_record_sources(version_id)',
  'CREATE INDEX ix_sync_ready ON sync_queue(state, next_attempt_at, priority)',
  'CREATE INDEX ix_sync_lease ON sync_queue(lease_expires_at) '
      "WHERE state = 'INFLIGHT'",
  'CREATE INDEX ix_segments_unapplied ON sync_log_segments(applied_at) '
      'WHERE applied_at IS NULL',
  'CREATE INDEX ix_conflicts_open ON conflicts(entity_kind, entity_id) '
      'WHERE resolved_at IS NULL',
  'CREATE INDEX ix_tombstones_purge ON tombstones(purge_after)',
  'CREATE INDEX ix_log_ops_segment ON sync_log_ops(device_id, seq)',
];

/// Triggers standing in for the `assets.current_version_id` foreign key
/// (see the `Assets` table doc). Together they enforce invariant I3: the
/// pointer always names a materialized version of the same asset, and the
/// version it names cannot be deleted while it is current.
const List<String> vaultTriggerDdl = [
  '''
CREATE TRIGGER trg_assets_current_update
BEFORE UPDATE OF current_version_id ON assets
WHEN NEW.current_version_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM asset_versions v
    WHERE v.id = NEW.current_version_id
      AND v.asset_id = NEW.id
      AND v.blob_id IS NOT NULL
  )
BEGIN
  SELECT RAISE(ABORT, 'I3: current_version_id must name a materialized version of the same asset');
END''',
  '''
CREATE TRIGGER trg_assets_current_insert
BEFORE INSERT ON assets
WHEN NEW.current_version_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM asset_versions v
    WHERE v.id = NEW.current_version_id
      AND v.asset_id = NEW.id
      AND v.blob_id IS NOT NULL
  )
BEGIN
  SELECT RAISE(ABORT, 'I3: current_version_id must name a materialized version of the same asset');
END''',
  '''
CREATE TRIGGER trg_versions_current_delete
BEFORE DELETE ON asset_versions
WHEN EXISTS (
  SELECT 1 FROM assets a WHERE a.current_version_id = OLD.id
)
BEGIN
  SELECT RAISE(ABORT, 'I3: cannot delete a version that is current');
END''',
  '''
CREATE TRIGGER trg_versions_current_evict
BEFORE UPDATE OF blob_id ON asset_versions
WHEN NEW.blob_id IS NULL
  AND EXISTS (
    SELECT 1 FROM assets a WHERE a.current_version_id = OLD.id
  )
BEGIN
  SELECT RAISE(ABORT, 'I3: cannot evict the current version');
END''',
];

@DriftDatabase(
  tables: [
    Devices,
    AppMeta,
    KeyEpochs,
    VaultEntries,
    Blobs,
    Assets,
    AssetVersions,
    VersionPins,
    Thumbnails,
    ExportRecords,
    ExportRecordSources,
    SyncQueue,
    CloudObjects,
    SyncLogSegments,
    SyncLogOps,
    SyncCursor,
    Conflicts,
    Tombstones,
  ],
  daos: [DevicesDao, EntriesDao, EpochsDao, ExportsDao, SyncDao, VersionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// An in-memory database for tests. On Windows, package:sqlite3 falls
  /// back to `winsqlite3.dll` when `sqlite3.dll` is not on the path.
  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // A file whose schema already exists but whose user_version was lost
      // (e.g. copied through sqlcipher_export) must not be re-created.
      final present = await customSelect(
        'SELECT count(*) AS n FROM sqlite_master '
        "WHERE type = 'table' AND name = 'vault_entries'",
      ).getSingle();
      if (present.read<int>('n') > 0) {
        return;
      }
      await m.createAll();
      for (final statement in vaultIndexDdl) {
        await customStatement(statement);
      }
      for (final statement in vaultTriggerDdl) {
        await customStatement(statement);
      }
    },
    onUpgrade: (m, from, to) async {
      throw StateError('No migration path from v$from to v$to yet (§6.6).');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );
}
