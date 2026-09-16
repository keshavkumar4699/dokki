/// The ONE translation boundary of `vault_imaging` (§12.3).
library;

import 'package:image/image.dart' show ImageException;
import 'package:platform_android/platform_android.dart'
    show
        NativeDecodeTooLarge,
        NativeEnvelopeFormat,
        NativeFailure,
        NativeLocked,
        NativeOutOfMemory,
        NativeStorageIo,
        NativeTagVerificationFailed,
        NativeUnsupportedFormat,
        NativeUnsupportedOp;
import 'package:vault_domain/vault_domain.dart';

/// Carries a [VaultFailure] through the throw-based guard.
final class ImagingException implements Exception {
  const ImagingException(this.failure);

  final VaultFailure failure;
}

Future<Result<T, VaultFailure>> guardImaging<T>(
  String op,
  Future<T> Function() body,
) async {
  try {
    return Ok(await body());
  } on ImagingException catch (e) {
    return Err(e.failure);
  } on OperationCancelledException catch (e, s) {
    return Err(OperationCancelled(cause: e, trace: s));
  } on NativeFailure catch (e, s) {
    return Err(_translateNative(op, e, s));
  } on ImageException catch (e, s) {
    return Err(ImageProcessingFailed(op, cause: e, trace: s));
  } on FormatException catch (e, s) {
    return Err(UnsupportedFormat('unknown', cause: e, trace: s));
  } on RangeError catch (e, s) {
    // package:image indexes past the end of truncated or bogus inputs
    // instead of raising its own exception.
    return Err(UnsupportedFormat('truncated', cause: e, trace: s));
  } on StateError catch (e, s) {
    // Locked primitive while streaming plaintext.
    return Err(
      KeyUnavailable(KeyUnavailableReason.vaultLocked, cause: e, trace: s),
    );
  }
}

/// Kotlin's stable codes → the same failures the Dart pipeline raises, so
/// callers cannot tell which backend ran (§12.6).
VaultFailure _translateNative(String op, NativeFailure e, StackTrace s) =>
    switch (e) {
      NativeTagVerificationFailed() => DecryptionFailed(
        tamperSuspected: true,
        cause: e,
        trace: s,
      ),
      NativeEnvelopeFormat() => DecryptionFailed(cause: e, trace: s),
      NativeUnsupportedFormat() => UnsupportedFormat(
        'undecodable',
        cause: e,
        trace: s,
      ),
      NativeDecodeTooLarge() => ImageProcessingFailed(
        '$op: decode ceiling',
        cause: e,
        trace: s,
      ),
      NativeUnsupportedOp() => ImageProcessingFailed(
        '$op: unsupported op',
        cause: e,
        trace: s,
      ),
      NativeOutOfMemory() => ImageProcessingFailed(
        '$op: out of memory',
        cause: e,
        trace: s,
      ),
      NativeStorageIo() => StorageIoFailure(op, cause: e, trace: s),
      NativeLocked() => KeyUnavailable(
        KeyUnavailableReason.vaultLocked,
        cause: e,
        trace: s,
      ),
      _ => ImageProcessingFailed('$op: ${e.code}', cause: e, trace: s),
    };
