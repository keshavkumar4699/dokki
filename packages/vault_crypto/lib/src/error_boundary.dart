/// The ONE translation boundary of `vault_crypto` (§12.3).
///
/// Converts native/format exceptions into package-local typed exceptions
/// and `VaultFailure`s. No other file in this package may catch.
library;

import 'package:platform_android/platform_android.dart'
    show
        NativeAuthFailed,
        NativeBiometricChanged,
        NativeFailure,
        NativeKeyInvalidated,
        NativeLocked,
        NativeNoDeviceLock,
        NativeTagVerificationFailed,
        NativeUserCancelled;
import 'package:vault_domain/vault_domain.dart';

import 'envelope/envelope_primitive.dart';

/// Translates native tag failures into the package-local exception.
Future<T> guardAead<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on NativeTagVerificationFailed {
    throw const TagVerificationFailed();
  }
}

/// Translates any crypto-path exception into a [VaultFailure].
Future<Result<T, VaultFailure>> guardCrypto<T>(
  String op,
  Future<T> Function() body,
) async {
  try {
    return Ok(await body());
  } on TagVerificationFailed catch (e, s) {
    return Err(DecryptionFailed(tamperSuspected: true, cause: e, trace: s));
  } on FormatException catch (e, s) {
    return Err(DecryptionFailed(cause: e, trace: s));
  } on NativeTagVerificationFailed catch (e, s) {
    return Err(DecryptionFailed(tamperSuspected: true, cause: e, trace: s));
  } on PersistenceException catch (e) {
    return Err(e.failure);
  } on NativeFailure catch (e, s) {
    return Err(_translateNative(e, s));
  } on StateError catch (e, s) {
    return Err(
      KeyUnavailable(KeyUnavailableReason.vaultLocked, cause: e, trace: s),
    );
  }
}

/// Wraps a `Result`-shaped persistence failure so it can flow through the
/// throw-based guard.
final class PersistenceException implements Exception {
  const PersistenceException(this.failure);

  final VaultFailure failure;
}

VaultFailure _translateNative(NativeFailure e, StackTrace s) => switch (e) {
  NativeKeyInvalidated() => KeyUnavailable(
    KeyUnavailableReason.keystoreInvalidated,
    cause: e,
    trace: s,
  ),
  NativeNoDeviceLock() => KeyUnavailable(
    KeyUnavailableReason.noDeviceLock,
    cause: e,
    trace: s,
  ),
  NativeBiometricChanged() => KeyUnavailable(
    KeyUnavailableReason.biometricChanged,
    cause: e,
    trace: s,
  ),
  // Kotlin does not count attempts; the session does (§12.5 copy).
  NativeAuthFailed() => AuthenticationFailed(-1, cause: e, trace: s),
  NativeUserCancelled() => OperationCancelled(cause: e, trace: s),
  NativeLocked() => KeyUnavailable(
    KeyUnavailableReason.vaultLocked,
    cause: e,
    trace: s,
  ),
  NativeTagVerificationFailed() => DecryptionFailed(
    tamperSuspected: true,
    cause: e,
    trace: s,
  ),
  NativeFailure() => EncryptionFailed(cause: e, trace: s),
};
