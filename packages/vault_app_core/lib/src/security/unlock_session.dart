/// `UnlockSession` (§5.5): the one object that knows whether the vault is
/// unlocked, owns the auto-lock timer, and is what the presentation layer
/// watches to gate every route.
///
/// Key material never lives here — the [KeyManager] holds only a native
/// session token. This class holds *state about* the session.
library;

import 'dart:async';

import 'package:vault_domain/vault_domain.dart';

/// Why the vault became locked; drives the copy on the unlock screen.
enum LockReason {
  /// App start, or nothing has happened yet.
  initial,

  /// The user tapped "Lock".
  user,

  /// The app sat in the background past [UnlockSession.autoLockAfter].
  autoLock,

  /// A screen-off / trim-memory signal from the platform.
  platform,
}

final class UnlockSession {
  UnlockSession({
    required KeyManager keyManager,
    this.autoLockAfter = const Duration(seconds: 60),
  }) : _keyManager = keyManager;

  final KeyManager _keyManager;

  /// How long the app may sit in the background before it locks (T2).
  final Duration autoLockAfter;

  final StreamController<LockState> _states =
      StreamController<LockState>.broadcast();

  Timer? _autoLock;
  LockReason _lastReason = LockReason.initial;
  int _failedAttempts = 0;

  /// The current state. Mirrors the key manager; never cached separately.
  LockState get state => _keyManager.lockState;

  bool get isUnlocked => _keyManager.isUnlocked;

  /// Whether a vault exists on this device at all (an epoch is stored).
  bool get hasVault => _keyManager.activeKeyEpoch != null;

  LockReason get lastLockReason => _lastReason;

  int get failedAttempts => _failedAttempts;

  /// Emits on every transition. Late subscribers should read [state] first.
  Stream<LockState> get states => _states.stream;

  // ── Vault lifecycle ────────────────────────────────────────────────────

  /// Creates a brand-new vault and leaves it unlocked. The recovery
  /// passphrase is mandatory and blocking (assumption A3, risk R1).
  Future<Result<void, VaultFailure>> createVault({
    required String pin,
    required String recoveryPassphrase,
  }) async {
    final result = await _keyManager.createVault(
      pin: pin,
      recoveryPassphrase: recoveryPassphrase,
    );
    if (result.isOk) {
      _failedAttempts = 0;
      _emit();
    }
    return result;
  }

  Future<Result<void, VaultFailure>> unlockWithPin(String pin) =>
      _unlock(() => _keyManager.unlock(pin: pin));

  Future<Result<void, VaultFailure>> unlockWithBiometric() =>
      _unlock(() => _keyManager.unlock(biometric: true));

  Future<Result<void, VaultFailure>> _unlock(
    Future<Result<void, VaultFailure>> Function() attempt,
  ) async {
    _emit();
    final result = await attempt();
    result.fold(
      (_) {
        _failedAttempts = 0;
        _cancelAutoLock();
      },
      (failure) {
        if (failure is AuthenticationFailed) {
          _failedAttempts++;
        }
      },
    );
    _emit();
    return result;
  }

  Future<Result<void, VaultFailure>> lock({
    LockReason reason = LockReason.user,
  }) async {
    _cancelAutoLock();
    if (!isUnlocked) {
      return const Ok(null);
    }
    _lastReason = reason;
    final result = await _keyManager.lock();
    _emit();
    return result;
  }

  // ── Lifecycle signals from the platform ────────────────────────────────

  /// The app went to the background: start the auto-lock countdown.
  void appBackgrounded() {
    if (!isUnlocked) {
      return;
    }
    _cancelAutoLock();
    _autoLock = Timer(autoLockAfter, () {
      unawaited(lock(reason: LockReason.autoLock));
    });
  }

  /// The app is visible again before the countdown fired.
  void appForegrounded() => _cancelAutoLock();

  /// Screen off or memory pressure: lock immediately (§8.4).
  void platformLockSignal() => unawaited(lock(reason: LockReason.platform));

  void _cancelAutoLock() {
    _autoLock?.cancel();
    _autoLock = null;
  }

  void _emit() {
    if (!_states.isClosed) {
      _states.add(state);
    }
  }

  Future<void> dispose() async {
    _cancelAutoLock();
    await _states.close();
  }
}
