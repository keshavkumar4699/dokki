/// The per-device identity and determinism bundle every use case needs
/// (§13.2): who we are, what time it is, how ids are minted, and the HLC.
library;

import 'package:vault_domain/vault_domain.dart';

final class VaultContext {
  VaultContext({
    required this.deviceId,
    required this.clock,
    required this.ids,
    required this.random,
    HybridLogicalClock? hlc,
  }) : hlc = hlc ?? HybridLogicalClock(deviceId: deviceId, clock: clock);

  final DeviceId deviceId;
  final Clock clock;
  final IdGenerator ids;

  /// Cryptographically secure randomness for anything user-facing that
  /// needs it (passphrase words); never for keys, which stay native.
  final RandomSource random;

  /// The single HLC state machine for this device. Every local mutation
  /// takes its timestamp from here so causality stays monotonic (§9.4).
  final HybridLogicalClock hlc;

  DateTime now() => clock.now();

  Hlc nextHlc() => hlc.next();
}
