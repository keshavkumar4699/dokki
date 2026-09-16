/// `KeyEpochRepository` implementation over Drift (§6.1).
library;

import 'package:drift/drift.dart';
import 'package:vault_domain/vault_domain.dart';

import '../daos/epochs_dao.dart';
import '../database/app_database.dart';
import '../error_boundary.dart';

/// Drift-backed [KeyEpochRepository].
final class KeyEpochRepositoryImpl implements KeyEpochRepository {
  KeyEpochRepositoryImpl(this._db);

  final AppDatabase _db;

  EpochsDao get _epochs => _db.epochsDao;

  @override
  Future<Result<List<KeyEpoch>, VaultFailure>> loadEpochs() =>
      guardDb('loadEpochs', () async {
        final rows = await _epochs.allEpochRows();
        return rows.map(_epochFrom).toList(growable: false);
      });

  @override
  Future<Result<KeyEpoch?, VaultFailure>> activeEpoch() =>
      guardDb('activeEpoch', () async {
        final row = await _epochs.activeEpochRow();
        return row == null ? null : _epochFrom(row);
      });

  @override
  Future<Result<void, VaultFailure>> insertEpoch(KeyEpoch epoch) =>
      guardDb('insertEpoch', () async {
        await _epochs.insertEpochRow(
          KeyEpochsCompanion.insert(
            epoch: Value(epoch.epoch),
            createdAt: epoch.createdAt,
            retiredAt: Value(epoch.retiredAt),
            wrapAlg: epoch.wrapAlgorithm,
            wrappedMkDevice: Uint8List.fromList(epoch.wrappedMkDevice),
            wrappedMkRecovery: Value(
              epoch.wrappedMkRecovery == null
                  ? null
                  : Uint8List.fromList(epoch.wrappedMkRecovery!),
            ),
            kdfParamsJson: Value(epoch.kdfParamsJson),
            keystoreAlias: epoch.keystoreAlias,
            strongbox: Value(epoch.strongbox),
          ),
        );
      });

  @override
  Future<Result<void, VaultFailure>> retireEpoch(
    int epoch,
    DateTime retiredAt,
  ) => guardDb('retireEpoch', () => _epochs.retireEpochRow(epoch, retiredAt));

  KeyEpoch _epochFrom(KeyEpochData row) => KeyEpoch(
    epoch: row.epoch,
    createdAt: row.createdAt,
    retiredAt: row.retiredAt,
    wrapAlgorithm: row.wrapAlg,
    wrappedMkDevice: row.wrappedMkDevice,
    wrappedMkRecovery: row.wrappedMkRecovery,
    kdfParamsJson: row.kdfParamsJson,
    keystoreAlias: row.keystoreAlias,
    strongbox: row.strongbox,
  );
}
