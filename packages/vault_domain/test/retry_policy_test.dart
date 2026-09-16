import 'package:test/test.dart';
import 'package:vault_domain/src/ports/clock.dart';
import 'package:vault_domain/src/sync/hlc.dart';
import 'package:vault_domain/src/sync/retry_policy.dart';
import 'package:vault_domain/src/sync/tombstone.dart';

final class _SeededRandom implements RandomSource {
  _SeededRandom(this._seed);

  int _seed;

  @override
  void fillBytes(List<int> out) {
    for (var i = 0; i < out.length; i++) {
      _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
      out[i] = _seed & 0xFF;
    }
  }

  @override
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed % max;
  }
}

void main() {
  group('RetryPolicy', () {
    const policy = RetryPolicy();

    test('delay grows with attempts and respects the cap', () {
      final random = _SeededRandom(1);
      for (final (attempt, expectedCeilingMs) in [
        (0, 2000),
        (1, 4000),
        (2, 8000),
        (12, policy.cap.inMilliseconds),
        (50, policy.cap.inMilliseconds),
      ]) {
        final delay = policy.delayForAttempt(attempt, random);
        expect(
          delay,
          lessThanOrEqualTo(const Duration(milliseconds: 21600000)),
        );
        expect(
          delay.inMilliseconds,
          lessThanOrEqualTo(expectedCeilingMs),
          reason: 'attempt $attempt',
        );
      }
    });

    test('negative attempts yield zero', () {
      expect(policy.delayForAttempt(-1, _SeededRandom(1)), Duration.zero);
    });

    test('maxAttempts gates giving up', () {
      expect(policy.hasAttemptsLeft(11), isTrue);
      expect(policy.hasAttemptsLeft(12), isFalse);
    });
  });

  group('Tombstone', () {
    test('purgeAfter = deletedAt + 180 days (M14)', () {
      final deletedAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final tombstone = Tombstone.of(
        entityKind: TombstoneEntityKind.entry,
        entityId: 'e1',
        deletedHlc: const Hlc(1, 0, 'dev-a'),
        originDevice: 'dev-a',
        deletedAt: deletedAt,
      );
      expect(tombstone.purgeAfter, deletedAt.add(const Duration(days: 180)));
    });

    test('entity kinds round-trip through DB values', () {
      expect(
        TombstoneEntityKind.fromDbValue('ENTRY'),
        TombstoneEntityKind.entry,
      );
      expect(
        TombstoneEntityKind.fromDbValue('ASSET'),
        TombstoneEntityKind.asset,
      );
      expect(
        TombstoneEntityKind.fromDbValue('VERSION'),
        TombstoneEntityKind.version,
      );
      expect(
        TombstoneEntityKind.fromDbValue('EXPORT'),
        TombstoneEntityKind.export,
      );
    });
  });
}
