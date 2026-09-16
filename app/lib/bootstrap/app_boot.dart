/// What exists BEFORE the vault is unlocked: the keyring, the key manager,
/// the lock session, and a way to open the encrypted vault once keys are
/// available. Features depend on this file; nothing here names concrete
/// infrastructure.
library;

import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'app_graph.dart';

final class AppBoot {
  const AppBoot({
    required this.session,
    required this.keyManager,
    required this.random,
    required this.cryptoBackend,
    required this.openVault,
    required this.closeVault,
  });

  final UnlockSession session;
  final KeyManager keyManager;

  /// Secure randomness for pre-unlock UI needs (the recovery passphrase).
  final RandomSource random;

  final CryptoBackend cryptoBackend;

  /// Derives `K_db`, opens the SQLCipher database and builds the graph.
  /// Only valid while [session] is unlocked.
  final Future<Result<AppGraph, VaultFailure>> Function() openVault;

  /// Closes the database and drops the graph (on lock).
  final Future<void> Function() closeVault;
}
