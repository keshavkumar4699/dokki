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
    required this.securitySignals,
    required this.openVault,
    required this.closeVault,
    required this.restoreFromDrive,
  });

  final UnlockSession session;
  final KeyManager keyManager;

  /// Secure randomness for pre-unlock UI needs (the recovery passphrase).
  final RandomSource random;

  final CryptoBackend cryptoBackend;

  /// Advisory root/emulator/test-key signals (§8.7 T4, Phase 9): the app
  /// warns, it does not refuse. Empty on a clean device or a non-Android
  /// host.
  final Future<List<String>> securitySignals;

  /// Derives `K_db`, opens the SQLCipher database and builds the graph.
  /// Only valid while [session] is unlocked.
  final Future<Result<AppGraph, VaultFailure>> Function() openVault;

  /// Closes the database and drops the graph (on lock).
  final Future<void> Function() closeVault;

  /// §9.9 bootstrap: sign in, download the keyring, unwrap MK with the
  /// recovery passphrase and rewrap it under this device's keys. After
  /// this succeeds, [openVault] opens the restored vault and the first
  /// sync cycle replays the log.
  final Future<Result<void, VaultFailure>> Function({
    required String pin,
    required String recoveryPassphrase,
  })
  restoreFromDrive;
}
