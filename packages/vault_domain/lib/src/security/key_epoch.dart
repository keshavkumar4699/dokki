/// One key epoch: a generation of the master key (§8.1).
///
/// The master key itself never leaves the native side; this row carries the
/// wrapped forms and metadata needed to unwrap it later.
library;

import '../ids.dart';

final class KeyEpoch {
  const KeyEpoch({
    required this.epoch,
    required this.createdAt,
    required this.wrapAlgorithm,
    required this.wrappedMkDevice,
    required this.keystoreAlias,
    required this.strongbox,
    this.retiredAt,
    this.wrappedMkRecovery,
    this.kdfParamsJson,
  });

  /// Monotonic, starts at 1.
  final int epoch;

  final DateTime createdAt;

  /// `NULL` means this is the active epoch.
  final DateTime? retiredAt;

  /// e.g. `KEYSTORE_AES_GCM_V1`.
  final String wrapAlgorithm;

  /// MK wrapped by the Keystore KEK. Opaque bytes.
  final List<int> wrappedMkDevice;

  /// MK wrapped by Argon2id(recovery passphrase). Opaque bytes.
  final List<int>? wrappedMkRecovery;

  /// `{alg, m, t, p, salt}` for the recovery KDF.
  final String? kdfParamsJson;

  final String keystoreAlias;

  /// Whether the KEK lives in StrongBox.
  final bool strongbox;

  bool get isActive => retiredAt == null;
}

/// Parameters for the Argon2id KDF used on the recovery path (§8.1).
final class Argon2Params {
  const Argon2Params({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.saltBase64,
  });

  /// Memory cost in KiB (64 MiB for PIN path, 256 MiB for recovery).
  final int memoryKiB;

  final int iterations;

  final int parallelism;

  final String saltBase64;
}

/// The recovery keyring blob, uploaded to Drive and kept locally (§8.1).
///
/// Everything inside is opaque; the only plaintext is the KDF parameters
/// and epoch metadata, which is not sensitive.
final class RecoveryKeyringBlob {
  const RecoveryKeyringBlob({
    required this.formatVersion,
    required this.deviceId,
    required this.createdAt,
    required this.epochs,
  });

  final int formatVersion;
  final DeviceId deviceId;
  final DateTime createdAt;
  final List<KeyEpoch> epochs;
}
