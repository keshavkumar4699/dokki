/// `KeyManager` port (§8).
///
/// The master key NEVER leaves the native side. This interface exposes
/// `unlock()`, `lock()`, `isUnlocked`, `rotate()` — and nothing that
/// returns bytes.
library;

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';
import '../security/key_epoch.dart';
import '../security/lock_state.dart';

abstract interface class KeyManager {
  bool get isUnlocked;

  LockState get lockState;

  /// The active key epoch, or `null` before the vault exists.
  int? get activeKeyEpoch;

  /// Creates a fresh vault: generates MK, wraps it under the device KEK
  /// (Keystore) and under the recovery passphrase (Argon2id), stores
  /// epoch 1, and unlocks.
  Future<Result<void, VaultFailure>> createVault({
    required String pin,
    required String recoveryPassphrase,
  });

  /// Unlocks with PIN + Keystore, or via biometric if allowed.
  Future<Result<void, VaultFailure>> unlock({
    String? pin,
    bool biometric = false,
  });

  /// Verifies a PIN without changing lock state (enrolment flow).
  Future<Result<bool, VaultFailure>> verifyPin(String pin);

  /// Locks immediately: the native session zeroes the MK.
  Future<Result<void, VaultFailure>> lock();

  /// Verifies the recovery passphrase against the stored recovery blob.
  Future<Result<bool, VaultFailure>> verifyRecoveryPassphrase(
    String passphrase,
  );

  /// Rewraps the recovery blob with a NEW passphrase (requires unlocked).
  Future<Result<void, VaultFailure>> changeRecoveryPassphrase(
    String newPassphrase,
  );

  /// §8.6 steps 1–3: a new master key under a new epoch. Every older
  /// epoch stays readable until the rewrap job finishes (it rewrites
  /// DEKs, not bodies, so rotation is a metadata pass, not a re-encrypt).
  ///
  /// Both factors are required: the PIN wraps MK' under the fresh device
  /// KEK and the passphrase wraps it under a fresh recovery salt. A wrong
  /// PIN fails BEFORE anything is stored, or the new epoch would lock the
  /// user out of their own vault.
  Future<Result<void, VaultFailure>> rotate({
    required String pin,
    required String recoveryPassphrase,
  });

  /// §8.6 step 4: rewrap a blob DEK from [fromEpoch] to [toEpoch] under
  /// the same purpose key. Used only by the rotation job; the DEK never
  /// leaves the key backend.
  Future<Result<List<int>, VaultFailure>> rewrapDek({
    required List<int> wrappedDek,
    required int fromEpoch,
    required int toEpoch,
    required int purpose,
  });

  /// The keyring blob for cloud backup / new-device bootstrap (§9.9).
  Future<Result<RecoveryKeyringBlob, VaultFailure>> exportKeyring({
    required DeviceId deviceId,
  });

  /// Imports a keyring from another device using the recovery passphrase
  /// (bootstrap step 3), rewrapping MK under this device's Keystore and
  /// the new [pin].
  Future<Result<void, VaultFailure>> importKeyring({
    required RecoveryKeyringBlob keyring,
    required String recoveryPassphrase,
    required String pin,
  });

  /// `K_db = HKDF(MK, 'dokki/vault/kdb/v1')` for SQLCipher (§8.1).
  ///
  /// The ONE deliberate exception to "no key crosses the boundary":
  /// SQLCipher's key API takes raw bytes. The caller passes them straight
  /// to `PRAGMA key` and drops the reference (§8.4). Requires unlocked.
  Future<Result<List<int>, VaultFailure>> deriveDbKey();
}
