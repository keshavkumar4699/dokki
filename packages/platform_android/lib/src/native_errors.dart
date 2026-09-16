/// Typed exceptions surfaced by the native bridge. Kotlin NEVER sends a
/// message intended for a human; these map 1:1 onto `VaultFailure`s in the
/// consuming package's `guardNative` translator (§12.6).
library;

sealed class NativeFailure implements Exception {
  const NativeFailure(this.code);

  final String code;

  @override
  String toString() => 'NativeFailure($code)';
}

/// AES-GCM tag verification failed: tamper or wrong key.
final class NativeTagVerificationFailed extends NativeFailure {
  const NativeTagVerificationFailed() : super('TAG_VERIFICATION_FAILED');
}

/// The Keystore key was invalidated (biometric re-enrolment, key wiped).
final class NativeKeyInvalidated extends NativeFailure {
  const NativeKeyInvalidated() : super('KEY_INVALIDATED');
}

/// No secure device lock is set.
final class NativeNoDeviceLock extends NativeFailure {
  const NativeNoDeviceLock() : super('NO_DEVICE_LOCK');
}

/// Biometric data changed; device credential needed.
final class NativeBiometricChanged extends NativeFailure {
  const NativeBiometricChanged() : super('BIOMETRIC_CHANGED');
}

/// Wrong PIN or recovery passphrase (an unwrap tag failed).
final class NativeAuthFailed extends NativeFailure {
  const NativeAuthFailed() : super('AUTH_FAILED');
}

/// The user dismissed the device-credential prompt.
final class NativeUserCancelled extends NativeFailure {
  const NativeUserCancelled() : super('USER_CANCELLED');
}

/// The session holds no key for the requested epoch.
final class NativeLocked extends NativeFailure {
  const NativeLocked() : super('LOCKED');
}

/// A sealed file that is not a well-formed envelope (or the wrong purpose).
final class NativeEnvelopeFormat extends NativeFailure {
  const NativeEnvelopeFormat() : super('ENVELOPE_FORMAT');
}

/// The decoder could not read the image bytes.
final class NativeUnsupportedFormat extends NativeFailure {
  const NativeUnsupportedFormat() : super('UNSUPPORTED_FORMAT');
}

/// The source exceeds the decode ceiling even when subsampled (R2).
final class NativeDecodeTooLarge extends NativeFailure {
  const NativeDecodeTooLarge() : super('DECODE_TOO_LARGE');
}

/// An `ImageOp` the native pipeline cannot run (Phase 8 CV ops).
final class NativeUnsupportedOp extends NativeFailure {
  const NativeUnsupportedOp() : super('UNSUPPORTED_OP');
}

/// The native heap could not hold the bitmap.
final class NativeOutOfMemory extends NativeFailure {
  const NativeOutOfMemory() : super('OUT_OF_MEMORY');
}

/// A native file read or write failed.
final class NativeStorageIo extends NativeFailure {
  const NativeStorageIo() : super('STORAGE_IO');
}

/// Generic native failure carrying the platform code.
final class NativeGenericFailure extends NativeFailure {
  const NativeGenericFailure(super.code);
}
