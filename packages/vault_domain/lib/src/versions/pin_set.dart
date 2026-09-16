/// Eviction pins (§10.4).
///
/// Pins are rows, so the eviction query is one indexed anti-join rather
/// than five special cases scattered through the code.
library;

import '../ids.dart';

enum PinReason {
  /// An export with `retain_artifact = 1` uses the version.
  exportRetained('EXPORT_RETAINED'),

  /// A blob has a `sync_queue` row not yet DONE.
  syncPending('SYNC_PENDING'),

  /// The version is a side of an open `ASSET_CURRENT` conflict.
  conflict('CONFLICT'),

  /// The user explicitly starred the version.
  user('USER'),

  /// A peer's log references it and the peer hasn't confirmed eviction.
  remoteRef('REMOTE_REF');

  const PinReason(this.dbValue);

  final String dbValue;

  static PinReason? fromDbValue(String value) {
    for (final reason in PinReason.values) {
      if (reason.dbValue == value) {
        return reason;
      }
    }
    return null;
  }
}

final class Pin {
  const Pin({
    required this.versionId,
    required this.reason,
    required this.refId,
  });

  final VersionId versionId;
  final PinReason reason;

  /// Free-form reference, e.g. the export id or conflict id.
  final String refId;

  @override
  bool operator ==(Object other) =>
      other is Pin &&
      other.versionId == versionId &&
      other.reason == reason &&
      other.refId == refId;

  @override
  int get hashCode => Object.hash(versionId, reason, refId);
}

final class PinSet {
  const PinSet(this.pins);

  const PinSet.empty() : pins = const [];

  final List<Pin> pins;

  Set<VersionId> get pinned => pins.map((Pin p) => p.versionId).toSet();

  bool isPinned(VersionId id) => pinned.contains(id);

  bool hasPin(VersionId id, PinReason reason, {String refId = ''}) => pins.any(
    (Pin p) => p.versionId == id && p.reason == reason && p.refId == refId,
  );

  PinSet withPin(Pin pin) => PinSet([...pins, pin]);

  PinSet withoutPin(Pin pin) =>
      PinSet(pins.where((Pin p) => p != pin).toList(growable: false));

  PinSet forVersion(VersionId id) =>
      PinSet(pins.where((Pin p) => p.versionId == id).toList(growable: false));
}
