/// `DartKeyManager` + `DartEnvelopePrimitive`: the dev key path round-trips
/// and, crucially, a wrong PIN never yields a usable key.
library;

import 'package:test/test.dart';
import 'package:vault_crypto/vault_crypto.dart';
import 'package:vault_domain/vault_domain.dart';

final class _MemoryEpochs implements KeyEpochRepository {
  final Map<int, KeyEpoch> rows = {};

  @override
  Future<Result<List<KeyEpoch>, VaultFailure>> loadEpochs() async =>
      Ok(rows.values.toList());

  @override
  Future<Result<KeyEpoch?, VaultFailure>> activeEpoch() async =>
      Ok(rows.values.where((e) => e.isActive).firstOrNull);

  @override
  Future<Result<void, VaultFailure>> insertEpoch(KeyEpoch epoch) async {
    rows[epoch.epoch] = epoch;
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> retireEpoch(
    int epoch,
    DateTime retiredAt,
  ) async => const Ok(null);
}

final class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026);
}

final class _SeededRandom implements RandomSource {
  int _seed = 7;

  @override
  void fillBytes(List<int> out) {
    for (var i = 0; i < out.length; i++) {
      _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
      out[i] = _seed & 0xFF;
    }
  }

  @override
  int nextInt(int max) =>
      (_seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF) % max;
}

// Tiny costs: these tests exercise the wiring, not the KDF's strength.
const _costs = DevKdfCosts(
  pinMemoryKiB: 256,
  pinIterations: 1,
  recoveryMemoryKiB: 256,
  recoveryIterations: 1,
);

void main() {
  late _MemoryEpochs epochs;
  late DartEnvelopePrimitive primitive;
  late DartKeyManager keys;

  DartKeyManager manager() => DartKeyManager(
    epochs: epochs,
    primitive: primitive,
    clock: _FixedClock(),
    random: _SeededRandom(),
    costs: _costs,
  );

  setUp(() {
    epochs = _MemoryEpochs();
    primitive = DartEnvelopePrimitive();
    keys = manager();
  });

  test('createVault stores epoch 1 and unlocks', () async {
    expect(keys.activeKeyEpoch, isNull);
    final created = await keys.createVault(
      pin: '2468',
      recoveryPassphrase: 'correct horse battery staple six',
    );
    expect(created.isOk, isTrue);
    expect(keys.isUnlocked, isTrue);
    expect(keys.activeKeyEpoch, 1);
    final row = epochs.rows[1]!;
    expect(row.wrapAlgorithm, DartKeyManager.wrapAlgorithm);
    expect(row.wrappedMkRecovery, isNotNull);
    expect(primitive.isBound, isTrue);
  });

  test('a second createVault is refused', () async {
    await keys.createVault(pin: '1', recoveryPassphrase: 'p');
    final again = await keys.createVault(pin: '2', recoveryPassphrase: 'q');
    expect(again.errOrNull, isA<InvalidAsset>());
  });

  test('lock clears keys; unlock with the right PIN restores them', () async {
    await keys.createVault(pin: '2468', recoveryPassphrase: 'p');
    final cipher = EnvelopeCipher(
      primitive: primitive,
      random: _SeededRandom(),
    );
    final sealed = await cipher.sealSmall(
      [1, 2, 3, 4],
      keyEpoch: 1,
      purpose: EnvelopePurpose.meta,
    );

    await keys.lock();
    expect(keys.isUnlocked, isFalse);
    expect(primitive.isBound, isFalse);

    // A fresh manager (process restart) with the same rows.
    final restarted = manager();
    expect((await restarted.restoreState()).isOk, isTrue);
    expect(restarted.activeKeyEpoch, 1);
    expect(restarted.isUnlocked, isFalse);

    final unlocked = await restarted.unlock(pin: '2468');
    expect(unlocked.isOk, isTrue);
    final opened = await cipher.openSmall(
      sealed.ciphertext,
      expectedPurpose: EnvelopePurpose.meta,
    );
    expect(opened, [1, 2, 3, 4]);
  });

  test('a wrong PIN is AuthenticationFailed and binds nothing', () async {
    await keys.createVault(pin: '2468', recoveryPassphrase: 'p');
    await keys.lock();
    final failure = (await keys.unlock(pin: '0000')).errOrNull;
    expect(failure, isA<AuthenticationFailed>());
    expect((failure! as AuthenticationFailed).attemptsRemaining, 9);
    expect(keys.isUnlocked, isFalse);
    expect(primitive.isBound, isFalse);
  });

  test('verifyPin and verifyRecoveryPassphrase do not change state', () async {
    await keys.createVault(pin: '2468', recoveryPassphrase: 'open sesame');
    await keys.lock();
    expect((await keys.verifyPin('2468')).okOrNull, isTrue);
    expect((await keys.verifyPin('1111')).okOrNull, isFalse);
    expect(
      (await keys.verifyRecoveryPassphrase('open sesame')).okOrNull,
      isTrue,
    );
    expect((await keys.verifyRecoveryPassphrase('nope')).okOrNull, isFalse);
    expect(keys.isUnlocked, isFalse);
  });

  test('changeRecoveryPassphrase re-wraps under the new passphrase', () async {
    await keys.createVault(pin: '2468', recoveryPassphrase: 'old one');
    expect((await keys.changeRecoveryPassphrase('new one')).isOk, isTrue);
    expect((await keys.verifyRecoveryPassphrase('old one')).okOrNull, isFalse);
    expect((await keys.verifyRecoveryPassphrase('new one')).okOrNull, isTrue);
    // The PIN wrap is untouched.
    await keys.lock();
    expect((await keys.unlock(pin: '2468')).isOk, isTrue);
  });

  test('biometric unlock is impossible without a Keystore', () async {
    await keys.createVault(pin: '2468', recoveryPassphrase: 'p');
    await keys.lock();
    expect(
      (await keys.unlock(biometric: true)).errOrNull,
      isA<KeyUnavailable>(),
    );
  });
}
