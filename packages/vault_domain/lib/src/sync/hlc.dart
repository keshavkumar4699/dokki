/// Hybrid logical clocks (§9.4).
///
/// HLC gives a total order for deterministic tiebreaking AND stays close
/// enough to wall time to be human-readable. Wall-clock is displayed to
/// humans; HLC makes decisions.
library;

import '../ids.dart';
import '../ports/clock.dart';

/// One HLC timestamp: `(physicalMillis, logicalCounter, deviceId)`.
final class Hlc implements Comparable<Hlc> {
  const Hlc(this.physicalMillis, this.logicalCounter, this.deviceId);

  /// Milliseconds since epoch, capped at 48 bits.
  final int physicalMillis;

  /// 16-bit logical counter.
  final int logicalCounter;

  final DeviceId deviceId;

  /// Sortable text form: `<48-bit-ms-hex>:<16-bit-counter-hex>:<deviceShort>`
  /// (§6 conventions).
  String toSortableString() {
    final pt = physicalMillis.toRadixString(16).padLeft(12, '0');
    final lc = logicalCounter.toRadixString(16).padLeft(4, '0');
    final dev = deviceId.length <= 8 ? deviceId : deviceId.substring(0, 8);
    return '$pt:$lc:$dev';
  }

  static Hlc parse(String text) {
    final parts = text.split(':');
    if (parts.length != 3) {
      throw FormatException('Invalid HLC: $text');
    }
    return Hlc(
      int.parse(parts[0], radix: 16),
      int.parse(parts[1], radix: 16),
      parts[2],
    );
  }

  @override
  int compareTo(Hlc other) {
    final byPt = physicalMillis.compareTo(other.physicalMillis);
    if (byPt != 0) {
      return byPt;
    }
    final byLc = logicalCounter.compareTo(other.logicalCounter);
    if (byLc != 0) {
      return byLc;
    }
    return deviceId.compareTo(other.deviceId);
  }

  /// Whether this timestamp is strictly after [other] in total order.
  bool isAfter(Hlc other) => compareTo(other) > 0;

  bool operator >(Hlc other) => isAfter(other);

  bool operator <(Hlc other) => compareTo(other) < 0;

  bool operator >=(Hlc other) => compareTo(other) >= 0;

  bool operator <=(Hlc other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc &&
      other.physicalMillis == physicalMillis &&
      other.logicalCounter == logicalCounter &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(physicalMillis, logicalCounter, deviceId);

  @override
  String toString() => 'Hlc(${toSortableString()})';
}

/// The mutable, per-device HLC state machine.
final class HybridLogicalClock {
  HybridLogicalClock({required this.deviceId, required this.clock, Hlc? last})
    : _last = last ?? Hlc(0, 0, deviceId);

  final DeviceId deviceId;
  final Clock clock;
  Hlc _last;

  /// The last timestamp issued or observed.
  Hlc get last => _last;

  static const _maxLc = 0xFFFF; // 16 bits

  /// A local event / send: `pt = max(lastPt, now()); lc = +1 or 0` (§9.4).
  Hlc next() {
    final nowMs = clock.now().millisecondsSinceEpoch;
    final pt = _max(nowMs, _last.physicalMillis);
    final lc = pt == _last.physicalMillis ? _wrap(_last.logicalCounter + 1) : 0;
    return _last = Hlc(pt, lc, deviceId);
  }

  /// Standard HLC receive merge (§9.4). The device component stays local:
  /// it identifies the issuer, and [deviceId] is who we are.
  Hlc receive(Hlc remote) {
    final nowMs = clock.now().millisecondsSinceEpoch;
    final pt = _max3(nowMs, _last.physicalMillis, remote.physicalMillis);
    final lc = switch ((
      pt == _last.physicalMillis,
      pt == remote.physicalMillis,
    )) {
      (true, true) => _wrap(
        _max(_last.logicalCounter, remote.logicalCounter) + 1,
      ),
      (true, false) => _wrap(_last.logicalCounter + 1),
      (false, true) => _wrap(remote.logicalCounter + 1),
      (false, false) => 0,
    };
    return _last = Hlc(pt, lc, deviceId);
  }

  int _max(int a, int b) => a > b ? a : b;

  int _max3(int a, int b, int c) => _max(_max(a, b), c);

  int _wrap(int value) => value > _maxLc ? 0 : value;
}
