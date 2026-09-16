/// `KeyManager` implementation over the Kotlin Keystore bridge (§8).
///
/// The master key never leaves Kotlin. This class owns the *bookkeeping*:
/// it persists wrapped blobs and KDF parameters through `KeyEpochRepository`
/// (the keyring file), hands them back to the bridge for every unwrap, and
/// tracks lock state. `wrap_alg` is `KEYSTORE_AES_GCM_V1` (§6.1).
library;

import 'dart:typed_data';

import 'package:platform_android/platform_android.dart'
    show EpochMaterial, NativeKeyManagerBridge;
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';

final class KeyManagerImpl implements KeyManager {
  KeyManagerImpl({
    required this.bridge,
    required this.epochs,
    required this.clock,
  });

  static const wrapAlgorithm = 'KEYSTORE_AES_GCM_V1';

  final NativeKeyManagerBridge bridge;
  final KeyEpochRepository epochs;
  final Clock clock;

  List<KeyEpoch> _epochs = const [];
  bool _unlocked = false;
  bool _restored = false;

  @override
  bool get isUnlocked => _unlocked;

  @override
  LockState get lockState => _unlocked ? LockState.unlocked : LockState.locked;

  @override
  int? get activeKeyEpoch =>
      _epochs.where((e) => e.isActive).map((e) => e.epoch).firstOrNull;

  /// Loads the keyring and asks the native session whether it still holds
  /// keys (it does not after process death; the rows survive).
  Future<Result<void, VaultFailure>> restoreState() =>
      guardCrypto('restoreKeyState', () async {
        await _reload();
        _unlocked = await bridge.isUnlocked();
        _restored = true;
      });

  @override
  Future<Result<void, VaultFailure>> createVault({
    required String pin,
    required String recoveryPassphrase,
  }) => guardCrypto('createVault', () async {
    await _ensureRestored();
    if (_epochs.isNotEmpty) {
      throw const PersistenceException(
        InvalidAsset('a vault already exists on this device'),
      );
    }
    final created = await bridge.createVault(
      pin: pin,
      recoveryPassphrase: recoveryPassphrase,
      epoch: 1,
    );
    await _store(
      KeyEpoch(
        epoch: 1,
        createdAt: clock.now(),
        wrapAlgorithm: wrapAlgorithm,
        wrappedMkDevice: created.wrappedMkDevice,
        wrappedMkRecovery: created.wrappedMkRecovery,
        kdfParamsJson: created.kdfParamsJson,
        keystoreAlias: created.keystoreAlias,
        strongbox: created.strongbox,
      ),
    );
    _unlocked = true;
  });

  @override
  Future<Result<void, VaultFailure>> unlock({
    String? pin,
    bool biometric = false,
  }) => guardCrypto('unlock', () async {
    await _ensureRestored();
    if (_epochs.isEmpty) {
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.keystoreInvalidated),
      );
    }
    if (pin == null) {
      // The PIN is the HKDF salt (§8.2): biometrics alone can satisfy the
      // Keystore's user-auth gate but never replace the second factor.
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.hardwareFailure),
      );
    }
    await bridge.unlock(pin: pin, epochs: _epochs.map(_material).toList());
    _unlocked = true;
  });

  @override
  Future<Result<bool, VaultFailure>> verifyPin(String pin) =>
      guardCrypto('verifyPin', () async {
        await _ensureRestored();
        return bridge.verifyPin(pin, _material(_activeOrThrow()));
      });

  @override
  Future<Result<void, VaultFailure>> lock() => guardCrypto('lock', () async {
    await bridge.lock();
    _unlocked = false;
  });

  @override
  Future<Result<bool, VaultFailure>> verifyRecoveryPassphrase(
    String passphrase,
  ) => guardCrypto('verifyRecoveryPassphrase', () async {
    await _ensureRestored();
    return bridge.verifyRecoveryPassphrase(
      passphrase,
      _material(_activeOrThrow()),
    );
  });

  @override
  Future<Result<void, VaultFailure>> changeRecoveryPassphrase(
    String newPassphrase,
  ) => guardCrypto('changeRecoveryPassphrase', () async {
    _requireUnlocked();
    final active = _activeOrThrow();
    final rewrapped = await bridge.changeRecovery(
      epoch: active.epoch,
      newPassphrase: newPassphrase,
      kdfParamsJson: active.kdfParamsJson ?? '{}',
    );
    await _store(
      KeyEpoch(
        epoch: active.epoch,
        createdAt: active.createdAt,
        retiredAt: active.retiredAt,
        wrapAlgorithm: active.wrapAlgorithm,
        wrappedMkDevice: active.wrappedMkDevice,
        wrappedMkRecovery: rewrapped.wrappedMkRecovery,
        kdfParamsJson: rewrapped.kdfParamsJson,
        keystoreAlias: active.keystoreAlias,
        strongbox: active.strongbox,
      ),
    );
  });

  @override
  Future<Result<void, VaultFailure>> rotate() =>
      guardCrypto('rotate', () async {
        // §8.6 / Phase 9: needs the PIN to wrap MK' and the rewrap job for
        // every blob's DEK. Not wired yet; fail honestly.
        throw const PersistenceException(KeyRotationFailed(0, 0));
      });

  @override
  Future<Result<RecoveryKeyringBlob, VaultFailure>> exportKeyring({
    required DeviceId deviceId,
  }) => guardCrypto('exportKeyring', () async {
    await _ensureRestored();
    return RecoveryKeyringBlob(
      formatVersion: 1,
      deviceId: deviceId,
      createdAt: clock.now(),
      epochs: _epochs,
    );
  });

  @override
  Future<Result<void, VaultFailure>> importKeyring({
    required RecoveryKeyringBlob keyring,
    required String recoveryPassphrase,
    required String pin,
  }) => guardCrypto('importKeyring', () async {
    await _ensureRestored();
    if (_epochs.isNotEmpty) {
      throw const PersistenceException(
        InvalidAsset('a vault already exists on this device'),
      );
    }
    final source = keyring.epochs.where((e) => e.isActive).firstOrNull;
    if (source == null || source.wrappedMkRecovery == null) {
      throw const FormatException('keyring has no active recovery wrap');
    }
    final wrapped = await bridge.importUnwrapped(
      epoch: _material(source),
      passphrase: recoveryPassphrase,
      pin: pin,
    );
    await _store(
      KeyEpoch(
        epoch: source.epoch,
        createdAt: source.createdAt,
        wrapAlgorithm: wrapAlgorithm,
        wrappedMkDevice: wrapped.wrappedMkDevice,
        wrappedMkRecovery: wrapped.wrappedMkRecovery,
        kdfParamsJson: wrapped.kdfParamsJson,
        keystoreAlias: wrapped.keystoreAlias,
        strongbox: wrapped.strongbox,
      ),
    );
    _unlocked = true;
  });

  @override
  Future<Result<List<int>, VaultFailure>> deriveDbKey() =>
      guardCrypto('deriveDbKey', () async {
        _requireUnlocked();
        return bridge.deriveDbKey();
      });

  // ── Internals ──────────────────────────────────────────────────────────

  Future<void> _ensureRestored() async {
    if (!_restored) {
      await _reload();
      _restored = true;
    }
  }

  Future<void> _reload() async {
    final stored = await epochs.loadEpochs();
    _epochs = stored.fold(
      (rows) => rows,
      (failure) => throw PersistenceException(failure),
    );
  }

  KeyEpoch _activeOrThrow() {
    final active = _epochs.where((e) => e.isActive).firstOrNull;
    if (active == null) {
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.keystoreInvalidated),
      );
    }
    return active;
  }

  void _requireUnlocked() {
    if (!_unlocked) {
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.vaultLocked),
      );
    }
  }

  Future<void> _store(KeyEpoch epoch) async {
    final stored = await epochs.insertEpoch(epoch);
    if (stored.isErr) {
      throw PersistenceException(stored.errOrNull!);
    }
    _epochs = [..._epochs.where((e) => e.epoch != epoch.epoch), epoch];
  }

  static EpochMaterial _material(KeyEpoch e) => EpochMaterial(
    epoch: e.epoch,
    keystoreAlias: e.keystoreAlias,
    wrappedMkDevice: Uint8List.fromList(e.wrappedMkDevice),
    wrappedMkRecovery: e.wrappedMkRecovery == null
        ? null
        : Uint8List.fromList(e.wrappedMkRecovery!),
    kdfParamsJson: e.kdfParamsJson ?? '{}',
  );
}
