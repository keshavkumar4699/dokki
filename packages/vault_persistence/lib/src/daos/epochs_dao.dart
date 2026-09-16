/// DAO for `key_epochs`.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'epochs_dao.g.dart';

@DriftAccessor(tables: [KeyEpochs])
class EpochsDao extends DatabaseAccessor<AppDatabase> with _$EpochsDaoMixin {
  EpochsDao(super.db);

  /// Upsert WITHOUT the delete that `INSERT OR REPLACE` implies: the row
  /// may already be referenced by `blobs.key_epoch` (ON DELETE RESTRICT).
  Future<void> insertEpochRow(KeyEpochsCompanion companion) =>
      into(keyEpochs).insert(
        companion,
        onConflict: DoUpdate(
          (_) => companion.copyWith(epoch: const Value.absent()),
          target: [keyEpochs.epoch],
        ),
      );

  Future<List<KeyEpochData>> allEpochRows() {
    final query = select(keyEpochs)
      ..orderBy([(t) => OrderingTerm.asc(t.epoch)]);
    return query.get();
  }

  Future<KeyEpochData?> activeEpochRow() =>
      (select(keyEpochs)..where((t) => t.retiredAt.isNull())).getSingleOrNull();

  Future<void> retireEpochRow(int epoch, DateTime retiredAt) =>
      (update(keyEpochs)
            ..where((t) => t.epoch.equals(epoch) & t.retiredAt.isNull()))
          .write(KeyEpochsCompanion(retiredAt: Value(retiredAt)));

  Future<int> maxEpoch() async {
    final max = keyEpochs.epoch.max();
    final query = selectOnly(keyEpochs)..addColumns([max]);
    final row = await query.getSingleOrNull();
    return row?.read(max) ?? 0;
  }
}
