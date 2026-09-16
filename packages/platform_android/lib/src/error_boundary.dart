/// The ONE place in `platform_android` where [PlatformException] is
/// converted into typed [NativeFailure]s (§12.3).
library;

import 'package:flutter/services.dart';

import 'native_errors.dart';

/// Runs a channel call, translating platform error codes.
Future<T> guardChannel<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on PlatformException catch (e) {
    throw _translate(e);
  } on MissingPluginException {
    throw const NativeGenericFailure('MISSING_PLUGIN');
  }
}

NativeFailure _translate(PlatformException e) => switch (e.code) {
  'TAG_VERIFICATION_FAILED' => const NativeTagVerificationFailed(),
  'KEY_INVALIDATED' => const NativeKeyInvalidated(),
  'NO_DEVICE_LOCK' => const NativeNoDeviceLock(),
  'BIOMETRIC_CHANGED' => const NativeBiometricChanged(),
  'AUTH_FAILED' => const NativeAuthFailed(),
  'USER_CANCELLED' => const NativeUserCancelled(),
  'LOCKED' => const NativeLocked(),
  'ENVELOPE_FORMAT' => const NativeEnvelopeFormat(),
  'UNSUPPORTED_FORMAT' => const NativeUnsupportedFormat(),
  'DECODE_TOO_LARGE' => const NativeDecodeTooLarge(),
  'UNSUPPORTED_OP' => const NativeUnsupportedOp(),
  'OUT_OF_MEMORY' => const NativeOutOfMemory(),
  'STORAGE_IO' => const NativeStorageIo(),
  _ => NativeGenericFailure(e.code),
};
