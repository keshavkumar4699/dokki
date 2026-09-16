/// The ONE translation boundary of `vault_imaging` (§12.3).
library;

import 'package:image/image.dart' show ImageException;
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
