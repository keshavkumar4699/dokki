import 'package:test/test.dart';
import 'package:vault_domain/src/ports/clock.dart';
import 'package:vault_domain/src/sync/hlc.dart';

/// A test double for the real Clock port. Real sources live in the app's
/// composition root; the domain only sees this interface.
final class FakeClock implements Clock {
  FakeClock(this.value);

  DateTime value;

  void advance(Duration d) => value = value.add(d);

  @override
  DateTime now() => value;
}

void main() {
  group('Hlc ordering', () {
    test('orders by physical time first', () {
      expect(
        const Hlc(100, 0, 'a').compareTo(const Hlc(200, 0, 'a')),
        lessThan(0),
      );
    });

    test('then by logical counter', () {
      expect(
        const Hlc(100, 1, 'a').compareTo(const Hlc(100, 2, 'a')),
        lessThan(0),
      );
    });

    test('then by device id (deterministic tiebreak)', () {
      expect(
        const Hlc(100, 1, 'a').compareTo(const Hlc(100, 1, 'b')),
        lessThan(0),
      );
      expect(const Hlc(100, 1, 'a').compareTo(const Hlc(100, 1, 'a')), 0);
    });

    test('isAfter mirrors compareTo', () {
      expect(const Hlc(200, 0, 'a').isAfter(const Hlc(100, 5, 'z')), isTrue);
      expect(const Hlc(100, 0, 'a').isAfter(const Hlc(100, 0, 'a')), isFalse);
    });
  });

  group('sortable text form', () {
    test('round-trips', () {
      for (final hlc in [
        const Hlc(0, 0, 'a'),
        const Hlc(1700000000123, 7, 'device-a'),
        const Hlc(281474976710655, 65535, 'devw'),
      ]) {
        expect(Hlc.parse(hlc.toSortableString()), hlc);
      }
    });

    test('is lexicographically sortable', () {
      final a = const Hlc(100, 0, 'z').toSortableString();
      final b = const Hlc(200, 0, 'a').toSortableString();
      expect(a.compareTo(b), lessThan(0));
    });

    test('rejects malformed input', () {
      expect(() => Hlc.parse('nope'), throwsFormatException);
      expect(() => Hlc.parse('1:2'), throwsFormatException);
    });
  });

  group('HybridLogicalClock', () {
    final clock = FakeClock(DateTime.fromMillisecondsSinceEpoch(1000));
    final hlc = HybridLogicalClock(deviceId: 'dev-a', clock: clock);

    test('local events tick the logical counter at equal physical time', () {
      final first = hlc.next();
      final second = hlc.next();
      expect(first.physicalMillis, 1000);
      expect(first.logicalCounter, 0);
      expect(second.logicalCounter, 1);
      expect(second.isAfter(first), isTrue);
    });

    test('counter resets when physical time advances', () {
      clock.advance(const Duration(milliseconds: 1));
      final next = hlc.next();
      expect(next.physicalMillis, 1001);
      expect(next.logicalCounter, 0);
    });

    test('receive merges a remote timestamp', () {
      const remote = Hlc(5000, 3, 'dev-b');
      final merged = hlc.receive(remote);
      expect(merged.physicalMillis, 5000);
      expect(merged.logicalCounter, 4);
      expect(merged.deviceId, 'dev-a', reason: 'issuer stays local');
    });

    test('clock running backwards does not lower the HLC', () {
      clock.value = DateTime.fromMillisecondsSinceEpoch(10);
      final before = hlc.last;
      final next = hlc.next();
      expect(next.physicalMillis, greaterThanOrEqualTo(before.physicalMillis));
    });

    test('two clocks with identical inputs issue identical stamps apart '
        'from the device id', () {
      final a = HybridLogicalClock(
        deviceId: 'a',
        clock: FakeClock(DateTime.fromMillisecondsSinceEpoch(42)),
      );
      final b = HybridLogicalClock(
        deviceId: 'b',
        clock: FakeClock(DateTime.fromMillisecondsSinceEpoch(42)),
      );
      final ta = a.next();
      final tb = b.next();
      expect(ta.physicalMillis, tb.physicalMillis);
      expect(ta.logicalCounter, tb.logicalCounter);
      expect(ta.compareTo(tb), lessThan(0), reason: '"a" < "b"');
    });
  });
}
