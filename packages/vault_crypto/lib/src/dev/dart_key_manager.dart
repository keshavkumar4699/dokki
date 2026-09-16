/// DEVELOPMENT-ONLY `KeyManager` over `package:cryptography`.
///
/// ⚠ Here the PIN IS the key (via Argon2id), which is exactly mistake M1
/// of the architecture: with the database file an attacker can brute
/// force a 6-digit PIN offline. Production uses `KeyManagerImpl` over the
/// Keystore bridge, where the PIN is only an HKDF salt and the key
/// material is hardware-bound (§8.2). This class exists so the full app
/// runs before the Kotlin side lands, and it advertises itself through
/// [KeyEpoch.wrapAlgorithm] = `DART_ARGON2_AES_GCM_DEV` so the UI can
/// show a "software keys" warning.
///
/// The recovery path is honest, though: the passphrase wraps MK with a
/// stronger Argon2id cost, exactly as in production.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import 'dart_envelope_primitive.dart';

/// Argon2id costs. Pure-Dart Argon2 is ~50× slower than native, so the
/// dev PIN path is deliberately light; the recovery path keeps a real
/// cost because it is the only defence against a stolen dataset (§8.2).
final class DevKdfCosts {
  const DevKdfCosts({
    this.pinMemoryKiB = 8 * 1024,
    this.pinIterations = 2,
    this.recoveryMemoryKiB = 32 * 1024,
    this.recoveryIterations = 3,
    this.parallelism = 1,
  });

  final int pinMemoryKiB;
  final int pinIterations;
  final int recoveryMemoryKiB;
  final int recoveryIterations;
  final int parallelism;
}

final class DartKeyManager implements KeyManager {
  DartKeyManager({
    required this.epochs,
    required this.primitive,
    required this.clock,
    required this.random,
    this.costs = const DevKdfCosts(),
  });

  static const wrapAlgorithm = 'DART_ARGON2_AES_GCM_DEV';

  final KeyEpochRepository epochs;
  final DartEnvelopePrimitive primitive;
  final Clock clock;
  final RandomSource random;
  final DevKdfCosts costs;

  static final AesGcm _gcm = AesGcm.with256bits();

  List<KeyEpoch> _epochs = const [];
  bool _unlocked = false;
  bool _restored = false;
  int _failedAttempts = 0;

  @override
  bool get isUnlocked => _unlocked;

  @override
  LockState get lockState => _unlocked ? LockState.unlocked : LockState.locked;

  @override
  int? get activeKeyEpoch =>
      _epochs.where((e) => e.isActive).map((e) => e.epoch).firstOrNull;

  /// Loads the stored epochs. Must run once before anything else so
  /// `activeKeyEpoch` reflects the database rather than fresh memory.
  Future<Result<void, VaultFailure>> restoreState() =>
      guardCrypto('restoreKeyState', () async {
        final stored = await epochs.loadEpochs();
        _epochs = stored.fold(
          (rows) => rows,
          (failure) => throw PersistenceException(failure),
        );
        _restored = true;
      });

  // ── Vault lifecycle ────────────────────────────────────────────────────

  @override
  Future<Result<void, VaultFailure>> createVault({
    required String pin,
    required String recoveryPassphrase,
  }) => guardCrypto('createVault', () async {
    if (!_restored) {
      await restoreState();
    }
    if (_epochs.isNotEmpty) {
      throw const PersistenceException(
        InvalidAsset('a vault already exists on this device'),
      );
    }
    final master = await _gcm.newSecretKey();
    final epoch = await _wrapEpoch(
      epochNumber: 1,
      master: master,
      pin: pin,
      passphrase: recoveryPassphrase,
    );
    await _store(epoch);
    primitive.bindMasterKey(1, master);
    _activeMaster = master;
    _unlocked = true;
    _failedAttempts = 0;
  });

  @override
  Future<Result<void, VaultFailure>> unlock({
    String? pin,
    bool biometric = false,
  }) => guardCrypto('unlock', () async {
    if (!_restored) {
      await restoreState();
    }
    if (_epochs.isEmpty) {
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.keystoreInvalidated),
      );
    }
    if (pin == null) {
      // No Keystore here, so nothing biometric can unwrap (§8.3).
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.hardwareFailure),
      );
    }
    final keys = <int, SecretKey>{};
    for (final epoch in _epochs) {
      final params = _DevKdfParams.decode(epoch.kdfParamsJson);
      final master = await _unwrap(
        epoch.wrappedMkDevice,
        await _derive(pin, params.pinSalt, params.pin),
      );
      if (master == null) {
        _failedAttempts++;
        throw PersistenceException(AuthenticationFailed(_remainingAttempts()));
      }
      keys[epoch.epoch] = master;
    }
    keys.forEach(primitive.bindMasterKey);
    _activeMaster = keys[activeKeyEpoch];
    _unlocked = true;
    _failedAttempts = 0;
  });

  @override
  Future<Result<bool, VaultFailure>> verifyPin(String pin) =>
      guardCrypto('verifyPin', () async {
        final active = _activeEpochOrThrow();
        final params = _DevKdfParams.decode(active.kdfParamsJson);
        final master = await _unwrap(
          active.wrappedMkDevice,
          await _derive(pin, params.pinSalt, params.pin),
        );
        return master != null;
      });

  @override
  Future<Result<void, VaultFailure>> lock() async {
    primitive.clear();
    _activeMaster = null;
    _unlocked = false;
    return const Ok(null);
  }

  @override
  Future<Result<bool, VaultFailure>> verifyRecoveryPassphrase(
    String passphrase,
  ) => guardCrypto('verifyRecoveryPassphrase', () async {
    final active = _activeEpochOrThrow();
    final wrapped = active.wrappedMkRecovery;
    if (wrapped == null) {
      return false;
    }
    final params = _DevKdfParams.decode(active.kdfParamsJson);
    final master = await _unwrap(
      wrapped,
      await _derive(passphrase, params.recoverySalt, params.recovery),
    );
    return master != null;
  });

  @override
  Future<Result<void, VaultFailure>> changeRecoveryPassphrase(
    String newPassphrase,
  ) => guardCrypto('changeRecoveryPassphrase', () async {
    _requireUnlocked();
    final active = _activeEpochOrThrow();
    final master = _masterFor(active.epoch);
    final params = _DevKdfParams.decode(active.kdfParamsJson);
    final salt = _randomBytes(16);
    final wrapped = await _wrap(
      master,
      await _derive(newPassphrase, salt, params.recovery),
    );
    final updated = KeyEpoch(
      epoch: active.epoch,
      createdAt: active.createdAt,
      retiredAt: active.retiredAt,
      wrapAlgorithm: active.wrapAlgorithm,
      wrappedMkDevice: active.wrappedMkDevice,
      wrappedMkRecovery: wrapped,
      kdfParamsJson: params.copyWith(recoverySalt: salt).encode(),
      keystoreAlias: active.keystoreAlias,
      strongbox: false,
    );
    await _store(updated);
  });

  @override
  Future<Result<void, VaultFailure>> rotate({
    required String pin,
    required String recoveryPassphrase,
  }) => guardCrypto('rotate', () async {
    _requireUnlocked();
    // A wrong PIN stored under the new epoch would lock the user out.
    final verified = await verifyPin(pin);
    if (verified.isErr || verified.okOrNull! != true) {
      throw PersistenceException(AuthenticationFailed(_remainingAttempts()));
    }
    final active = _activeEpochOrThrow();
    final master = _masterFor(active.epoch);
    final newEpoch = active.epoch + 1;
    await _store(
      KeyEpoch(
        epoch: active.epoch,
        createdAt: active.createdAt,
        retiredAt: clock.now(),
        wrapAlgorithm: active.wrapAlgorithm,
        wrappedMkDevice: active.wrappedMkDevice,
        wrappedMkRecovery: active.wrappedMkRecovery,
        kdfParamsJson: active.kdfParamsJson,
        keystoreAlias: active.keystoreAlias,
        strongbox: false,
      ),
    );
    final epoch = await _wrapEpoch(
      epochNumber: newEpoch,
      master: master,
      pin: pin,
      passphrase: recoveryPassphrase,
    );
    await _store(epoch);
    primitive.bindMasterKey(newEpoch, master);
  });

  @override
  Future<Result<List<int>, VaultFailure>> rewrapDek({
    required List<int> wrappedDek,
    required int fromEpoch,
    required int toEpoch,
    required int purpose,
  }) => guardCrypto('rewrapDek', () async {
    _requireUnlocked();
    return primitive.rewrap(
      wrappedDek: Uint8List.fromList(wrappedDek),
      fromEpoch: fromEpoch,
      toEpoch: toEpoch,
      purpose: purpose,
    );
  });

  @override
  Future<Result<RecoveryKeyringBlob, VaultFailure>> exportKeyring({
    required DeviceId deviceId,
  }) => guardCrypto('exportKeyring', () async {
    if (!_restored) {
      await restoreState();
    }
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
    if (!_restored) {
      await restoreState();
    }
    if (_epochs.isNotEmpty) {
      throw const PersistenceException(
        InvalidAsset('a vault already exists on this device'),
      );
    }
    final source = keyring.epochs.where((e) => e.isActive).firstOrNull;
    final wrapped = source?.wrappedMkRecovery;
    if (source == null || wrapped == null) {
      throw const FormatException('keyring has no active recovery wrap');
    }
    final params = _DevKdfParams.decode(source.kdfParamsJson);
    final master = await _unwrap(
      wrapped,
      await _derive(recoveryPassphrase, params.recoverySalt, params.recovery),
    );
    if (master == null) {
      throw const PersistenceException(AuthenticationFailed(0));
    }
    // Bootstrap §9.9 step 4: same MK, re-wrapped under this device's PIN.
    final epoch = await _wrapEpoch(
      epochNumber: source.epoch,
      master: master,
      pin: pin,
      passphrase: recoveryPassphrase,
    );
    await _store(epoch);
    primitive.bindMasterKey(epoch.epoch, master);
    _activeMaster = master;
    _unlocked = true;
  });

  @override
  Future<Result<List<int>, VaultFailure>> deriveDbKey() =>
      guardCrypto('deriveDbKey', () async {
        _requireUnlocked();
        final master = _masterFor(_activeEpochOrThrow().epoch);
        final key = await Hkdf(
          hmac: Hmac.sha256(),
          outputLength: 32,
        ).deriveKey(secretKey: master, info: 'dokki/vault/kdb/v1'.codeUnits);
        return key.extractBytes();
      });

  // ── Internals ──────────────────────────────────────────────────────────

  Future<KeyEpoch> _wrapEpoch({
    required int epochNumber,
    required SecretKey master,
    required String pin,
    required String passphrase,
  }) async {
    final params = _DevKdfParams(
      pin: Argon2Params(
        memoryKiB: costs.pinMemoryKiB,
        iterations: costs.pinIterations,
        parallelism: costs.parallelism,
        saltBase64: '',
      ),
      recovery: Argon2Params(
        memoryKiB: costs.recoveryMemoryKiB,
        iterations: costs.recoveryIterations,
        parallelism: costs.parallelism,
        saltBase64: '',
      ),
      pinSalt: _randomBytes(16),
      recoverySalt: _randomBytes(16),
    );
    final wrappedDevice = await _wrap(
      master,
      await _derive(pin, params.pinSalt, params.pin),
    );
    final wrappedRecovery = await _wrap(
      master,
      await _derive(passphrase, params.recoverySalt, params.recovery),
    );
    return KeyEpoch(
      epoch: epochNumber,
      createdAt: clock.now(),
      wrapAlgorithm: wrapAlgorithm,
      wrappedMkDevice: wrappedDevice,
      wrappedMkRecovery: wrappedRecovery,
      kdfParamsJson: params.encode(),
      keystoreAlias: 'dev.software.$epochNumber',
      strongbox: false,
    );
  }

  Future<SecretKey> _derive(
    String secret,
    List<int> salt,
    Argon2Params params,
  ) => Argon2id(
    parallelism: params.parallelism,
    memory: params.memoryKiB,
    iterations: params.iterations,
    hashLength: 32,
  ).deriveKeyFromPassword(password: secret, nonce: salt);

  Future<List<int>> _wrap(SecretKey master, SecretKey kek) async {
    final box = await _gcm.encrypt(
      await master.extractBytes(),
      secretKey: kek,
      nonce: _randomBytes(12),
    );
    return [...box.nonce, ...box.cipherText, ...box.mac.bytes];
  }

  /// `null` means the KEK was wrong (a wrong PIN / passphrase).
  Future<SecretKey?> _unwrap(List<int> wrapped, SecretKey kek) async {
    if (wrapped.length < 28) {
      return null;
    }
    try {
      final bytes = await _gcm.decrypt(
        SecretBox(
          wrapped.sublist(12, wrapped.length - 16),
          nonce: wrapped.sublist(0, 12),
          mac: Mac(wrapped.sublist(wrapped.length - 16)),
        ),
        secretKey: kek,
      );
      return SecretKey(bytes);
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  /// The active epoch's master key, kept only while unlocked so the
  /// recovery passphrase can be re-wrapped without asking for the PIN.
  SecretKey? _activeMaster;

  SecretKey _masterFor(int epoch) {
    final key = _activeMaster;
    if (key == null || epoch != activeKeyEpoch) {
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.vaultLocked),
      );
    }
    return key;
  }

  void _requireUnlocked() {
    if (!_unlocked) {
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.vaultLocked),
      );
    }
  }

  KeyEpoch _activeEpochOrThrow() {
    final active = _epochs.where((e) => e.isActive).firstOrNull;
    if (active == null) {
      throw const PersistenceException(
        KeyUnavailable(KeyUnavailableReason.keystoreInvalidated),
      );
    }
    return active;
  }

  int _remainingAttempts() => (10 - _failedAttempts).clamp(0, 10);

  Future<void> _store(KeyEpoch epoch) async {
    final stored = await epochs.insertEpoch(epoch);
    if (stored.isErr) {
      throw PersistenceException(stored.errOrNull!);
    }
    _epochs = [..._epochs.where((e) => e.epoch != epoch.epoch), epoch];
  }

  Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    random.fillBytes(bytes);
    return bytes;
  }
}

/// The `kdf_params_json` column for the dev wrap: both Argon2id parameter
/// sets and both salts.
final class _DevKdfParams {
  const _DevKdfParams({
    required this.pin,
    required this.recovery,
    required this.pinSalt,
    required this.recoverySalt,
  });

  factory _DevKdfParams.decode(String? json) {
    if (json == null) {
      throw const FormatException('missing kdf params');
    }
    final map = (jsonDecode(json) as Map).cast<String, Object?>();
    Argon2Params params(String key) {
      final m = (map[key] as Map).cast<String, Object?>();
      return Argon2Params(
        memoryKiB: m['m'] as int,
        iterations: m['t'] as int,
        parallelism: m['p'] as int,
        saltBase64: '',
      );
    }

    return _DevKdfParams(
      pin: params('pin'),
      recovery: params('recovery'),
      pinSalt: base64Decode(map['pinSalt'] as String),
      recoverySalt: base64Decode(map['recoverySalt'] as String),
    );
  }

  final Argon2Params pin;
  final Argon2Params recovery;
  final List<int> pinSalt;
  final List<int> recoverySalt;

  String encode() => jsonEncode({
    'alg': DartKeyManager.wrapAlgorithm,
    'pin': {'m': pin.memoryKiB, 't': pin.iterations, 'p': pin.parallelism},
    'recovery': {
      'm': recovery.memoryKiB,
      't': recovery.iterations,
      'p': recovery.parallelism,
    },
    'pinSalt': base64Encode(pinSalt),
    'recoverySalt': base64Encode(recoverySalt),
  });

  _DevKdfParams copyWith({List<int>? recoverySalt}) => _DevKdfParams(
    pin: pin,
    recovery: recovery,
    pinSalt: pinSalt,
    recoverySalt: recoverySalt ?? this.recoverySalt,
  );
}
