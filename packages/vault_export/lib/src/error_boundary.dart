/// The ONE translation boundary of `vault_export` (§12.3).
library;

import 'package:vault_domain/vault_domain.dart';

/// Carries a [VaultFailure] through the throw-based guard.
final class ExportException implements Exception {
  const ExportException(this.failure);

  final VaultFailure failure;
}

Future<Result<T, VaultFailure>> guardExport<T>(
  String op,
  Future<T> Function() body,
) async {
  try {
    return Ok(await body());
  } on ExportException catch (e) {
    return Err(e.failure);
  } on OperationCancelledException catch (e, s) {
    return Err(OperationCancelled(cause: e, trace: s));
  } on StateError catch (e, s) {
    // A locked primitive while reading a source.
    return Err(
      KeyUnavailable(KeyUnavailableReason.vaultLocked, cause: e, trace: s),
    );
  }
}
