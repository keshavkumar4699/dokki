/// The ONE translation boundary of `vault_pdf` (§12.3).
library;

import 'package:image/image.dart' show ImageException;
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_imaging/vault_imaging.dart' show ImagingException;

/// Carries a [VaultFailure] through the throw-based guard.
final class PdfException implements Exception {
  const PdfException(this.failure);

  final VaultFailure failure;
}

/// Decode failures inside a compose are page-scoped (§13, Phase 6): the
/// imaging boundary's exception becomes a [PdfGenerationFailed] naming
/// the page. The only catch outside [guardPdf], by design.
Future<T> guardPdfPage<T>(int pageIndex, Future<T> Function() body) async {
  try {
    return await body();
  } on ImagingException catch (e) {
    throw PdfException(PdfGenerationFailed(pageIndex: pageIndex, cause: e));
  }
}

Future<Result<T, VaultFailure>> guardPdf<T>(
  Future<T> Function() body,
) async {
  try {
    return Ok(await body());
  } on PdfException catch (e) {
    return Err(e.failure);
  } on OperationCancelledException catch (e, s) {
    return Err(OperationCancelled(cause: e, trace: s));
  } on ImageException catch (e, s) {
    return Err(PdfGenerationFailed(cause: e, trace: s));
  } on FormatException catch (e, s) {
    // package:pdf raises FormatException on image bytes it cannot place.
    return Err(PdfGenerationFailed(cause: e, trace: s));
  } on StateError catch (e, s) {
    // Locked primitive while streaming plaintext.
    return Err(
      KeyUnavailable(KeyUnavailableReason.vaultLocked, cause: e, trace: s),
    );
  }
}
