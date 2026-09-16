/// Persistence for `key_epochs` rows (§6.1). Implemented by
/// `vault_persistence`; consumed by `vault_crypto`'s `KeyManager`.
library;

import '../failures/vault_failure.dart';
import '../result.dart';
import '../security/key_epoch.dart';

abstract interface class KeyEpochRepository {
  Future<Result<List<KeyEpoch>, VaultFailure>> loadEpochs();

  Future<Result<KeyEpoch?, VaultFailure>> activeEpoch();

  Future<Result<void, VaultFailure>> insertEpoch(KeyEpoch epoch);

  Future<Result<void, VaultFailure>> retireEpoch(int epoch, DateTime retiredAt);
}
