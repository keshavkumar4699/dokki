/// `UnlockSession`: lock gating and the auto-lock timer (T2).
library;

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'support/fakes.dart';

void main() {
  late FakeKeyManager keys;
  late UnlockSession session;

  setUp(() {
    keys = FakeKeyManager();
    session = UnlockSession(
      keyManager: keys,
      autoLockAfter: const Duration(seconds: 30),
    );
  });

  tearDown(() => session.dispose());

  test('starts locked when a vault exists', () {
    expect(session.hasVault, isTrue);
    expect(session.isUnlocked, isFalse);
    expect(session.state, LockState.locked);
  });

  test('hasVault is false on a fresh install', () {
    final fresh = UnlockSession(keyManager: FakeKeyManager(hasVault: false));
    expect(fresh.hasVault, isFalse);
  });

  test('a wrong PIN counts a failed attempt and stays locked', () async {
    final states = <LockState>[];
    final sub = session.states.listen(states.add);
    final failure = unwrapErr(await session.unlockWithPin('0000'));
    expect(failure, isA<AuthenticationFailed>());
    expect(session.isUnlocked, isFalse);
    expect(session.failedAttempts, 1);
    unwrap(await session.unlockWithPin('1234'));
    expect(session.isUnlocked, isTrue);
    expect(session.failedAttempts, 0);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(states.last, LockState.unlocked);
  });

  test('createVault leaves the vault unlocked', () async {
    final fresh = UnlockSession(keyManager: FakeKeyManager(hasVault: false));
    unwrap(
      await fresh.createVault(
        pin: '1234',
        recoveryPassphrase: 'six words go here',
      ),
    );
    expect(fresh.hasVault, isTrue);
    expect(fresh.isUnlocked, isTrue);
  });

  test('backgrounding locks after autoLockAfter, not before', () {
    fakeAsync((async) {
      session.unlockWithPin('1234');
      async.flushMicrotasks();
      expect(session.isUnlocked, isTrue);

      session.appBackgrounded();
      async.elapse(const Duration(seconds: 29));
      expect(session.isUnlocked, isTrue);

      async.elapse(const Duration(seconds: 2));
      expect(session.isUnlocked, isFalse);
      expect(session.lastLockReason, LockReason.autoLock);
      expect(keys.lockCalls, 1);
    });
  });

  test('foregrounding in time cancels the countdown', () {
    fakeAsync((async) {
      session.unlockWithPin('1234');
      async.flushMicrotasks();
      session.appBackgrounded();
      async.elapse(const Duration(seconds: 20));
      session.appForegrounded();
      async.elapse(const Duration(minutes: 5));
      expect(session.isUnlocked, isTrue);
      expect(keys.lockCalls, 0);
    });
  });

  test('a platform lock signal locks immediately', () {
    fakeAsync((async) {
      session.unlockWithPin('1234');
      async.flushMicrotasks();
      session.platformLockSignal();
      async.flushMicrotasks();
      expect(session.isUnlocked, isFalse);
      expect(session.lastLockReason, LockReason.platform);
    });
  });

  test('lock() while already locked is a harmless no-op', () async {
    unwrap(await session.lock());
    expect(keys.lockCalls, 0);
  });
}
