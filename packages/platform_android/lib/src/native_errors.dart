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

/// Generic native failure carrying the platform code.
final class NativeGenericFailure extends NativeFailure {
  const NativeGenericFailure(super.code);
}
