/// DAO for `devices` and `app_meta`.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'devices_dao.g.dart';

@DriftAccessor(tables: [Devices, AppMeta])
class DevicesDao extends DatabaseAccessor<AppDatabase> with _$DevicesDaoMixin {
  DevicesDao(super.db);

  /// Inserts or refreshes a device row. [promoteToSelf] sets `is_self = 1`
  /// (guarded by the partial unique index `ux_devices_self`).
  Future<void> upsertDeviceRow(
    DevicesCompanion companion, {
    required bool promoteToSelf,
  }) => into(devices).insert(
    companion,
    onConflict: DoUpdate(
      (old) => DevicesCompanion(
        label: companion.label,
        // A peer upsert never demotes the self row; only a promotion
        // touches `is_self`.
        isSelf: promoteToSelf ? const Value(true) : const Value.absent(),
      ),
      target: [devices.id],
    ),
  );

  Future<DeviceData?> deviceById(String id) =>
      (select(devices)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<DeviceData>> allDevices() {
    final query = select(devices)
      ..orderBy([
        (t) => OrderingTerm.desc(t.isSelf),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);
    return query.get();
  }

  /// Write-through of the peer-cursor fields on the device row.
  Future<void> updateDeviceCursorRow(
    String id, {
    required String? lastSeenHlc,
    required DateTime? lastSyncedAt,
  }) => (update(devices)..where((t) => t.id.equals(id))).write(
    DevicesCompanion(
      lastSeenHlc: Value(lastSeenHlc),
      lastSyncedAt: Value(lastSyncedAt),
    ),
  );

  Future<AppMetaData?> appMetaGet(String key) =>
      (select(appMeta)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<void> appMetaSet(String key, Uint8List value) => into(appMeta).insert(
    AppMetaCompanion(key: Value(key), value: Value(value)),
    mode: InsertMode.insertOrReplace,
  );

  Future<List<AppMetaData>> appMetaAll() => select(appMeta).get();

  Future<void> appMetaDelete(String key) =>
      (delete(appMeta)..where((t) => t.key.equals(key))).go();
}
