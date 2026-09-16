/// DAO for `vault_entries` and `assets` rows.
library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'entries_dao.g.dart';

/// Lightweight projection used to build a [VaultEntrySummary]; the title
/// bytes travel raw so the repository can decrypt them.
final class EntrySummaryRow {
  const EntrySummaryRow({
    required this.id,
    required this.type,
    required this.titleEnc,
    required this.createdAt,
    required this.updatedAt,
    required this.assetCount,
    required this.hasOpenConflict,
    required this.coverVersionId,
  });

  final String id;
  final String type;
  final Uint8List? titleEnc;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int assetCount;
  final bool hasOpenConflict;
  final String? coverVersionId;
}

@DriftAccessor(tables: [VaultEntries, Assets])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.db);

  Future<void> insertEntry(VaultEntriesCompanion companion) =>
      into(vaultEntries).insert(companion);

  Future<VaultEntryData?> entryById(String id) =>
      (select(vaultEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateEntryRow(String id, VaultEntriesCompanion companion) =>
      (update(vaultEntries)..where((t) => t.id.equals(id))).write(companion);

  /// [type] is a DB value (`PHOTO`, `DOCUMENT`, …).
  Future<List<EntrySummaryRow>> entrySummaries({
    String? type,
    required bool includeDeleted,
  }) {
    final query = selectOnly(vaultEntries)
      ..addColumns([
        vaultEntries.id,
        vaultEntries.type,
        vaultEntries.titleEnc,
        vaultEntries.createdAt,
        vaultEntries.updatedAt,
      ])
      ..addColumns([_liveAssetCount(), _hasOpenConflict(), _coverVersion()])
      ..orderBy([OrderingTerm.desc(vaultEntries.updatedAt)]);
    if (type != null) {
      query.where(vaultEntries.type.equals(type));
    }
    if (!includeDeleted) {
      query.where(vaultEntries.deletedAt.isNull());
    }
    return query
        .map(
          (row) => EntrySummaryRow(
            id: row.read(vaultEntries.id)!,
            type: row.read(vaultEntries.type)!,
            titleEnc: row.read(vaultEntries.titleEnc),
            createdAt: row.readWithConverter(vaultEntries.createdAt)!,
            updatedAt: row.readWithConverter(vaultEntries.updatedAt)!,
            assetCount: row.read(_liveAssetCount())!,
            hasOpenConflict: row.read(_hasOpenConflict())!,
            coverVersionId: row.read(_coverVersion()),
          ),
        )
        .get();
  }

  /// Re-runs [entrySummaries] on every change to the tables it reads.
  ///
  /// The sub-selects for asset counts and open conflicts are opaque to
  /// drift's stream tracking, so this listens for updates on all three
  /// tables explicitly instead of using `.watch()`.
  Stream<List<EntrySummaryRow>> watchEntrySummaries({String? type}) =>
      _initialThen(
        db.tableUpdates(
          TableUpdateQuery.onAllTables([
            db.vaultEntries,
            db.assets,
            db.conflicts,
          ]),
        ),
      ).asyncMap((_) => entrySummaries(type: type, includeDeleted: false));

  /// Emits once immediately and again whenever anything that feeds an
  /// entry's aggregate (entry, assets, versions, pins, conflicts) changes.
  /// Callers reload the aggregate on each event.
  Stream<void> watchEntryTouch(String id) => _initialThen(
    db.tableUpdates(
      TableUpdateQuery.onAllTables([
        db.vaultEntries,
        db.assets,
        db.assetVersions,
        db.versionPins,
        db.conflicts,
      ]),
    ),
  );

  /// One synthetic event, then every event of [updates]. Built from plain
  /// stream combinators rather than `async*` so that cancelling the outer
  /// subscription cancels drift's update stream promptly instead of
  /// waiting on a suspended generator.
  static Stream<void> _initialThen(Stream<Object?> updates) {
    late StreamController<void> controller;
    StreamSubscription<Object?>? inner;
    controller = StreamController<void>(
      onListen: () {
        controller.add(null);
        inner = updates.listen(
          (_) => controller.add(null),
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onPause: () => inner?.pause(),
      onResume: () => inner?.resume(),
      onCancel: () => inner?.cancel(),
    );
    return controller.stream;
  }

  Expression<int> _liveAssetCount() => const CustomExpression(
    '(SELECT COUNT(*) FROM assets a '
    'WHERE a.entry_id = vault_entries.id AND a.deleted_at IS NULL)',
  );

  Expression<bool> _hasOpenConflict() => const CustomExpression(
    '(EXISTS (SELECT 1 FROM conflicts c '
    'WHERE c.entity_id = vault_entries.id AND c.resolved_at IS NULL))',
  );

  /// Same ordering as [assetsForEntry], so the cover is `liveAssets.first`.
  Expression<String> _coverVersion() => const CustomExpression(
    '(SELECT a.current_version_id FROM assets a '
    'WHERE a.entry_id = vault_entries.id AND a.deleted_at IS NULL '
    'ORDER BY a.ordinal ASC, a.created_at ASC LIMIT 1)',
  );

  Future<void> insertAsset(AssetsCompanion companion) =>
      into(assets).insert(companion);

  Future<AssetData?> assetById(String id) =>
      (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<AssetData>> assetsForEntry(
    String entryId, {
    bool includeDeleted = false,
  }) {
    final query = select(assets)..where((t) => t.entryId.equals(entryId));
    if (!includeDeleted) {
      query.where((t) => t.deletedAt.isNull());
    }
    query.orderBy([
      (t) => OrderingTerm.asc(t.ordinal),
      (t) => OrderingTerm.asc(t.createdAt),
    ]);
    return query.get();
  }

  Future<void> updateAsset(String id, AssetsCompanion companion) =>
      (update(assets)..where((t) => t.id.equals(id))).write(companion);

  Future<void> setAssetOrdinal(String id, int ordinal) =>
      (update(assets)..where((t) => t.id.equals(id))).write(
        AssetsCompanion(ordinal: Value(ordinal)),
      );

  Future<void> markAssetDeleted(String id, DateTime at) =>
      (update(assets)..where((t) => t.id.equals(id))).write(
        AssetsCompanion(deletedAt: Value(at)),
      );
}
