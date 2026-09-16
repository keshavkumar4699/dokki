/// The ONE translation boundary of `vault_app_core` (§12.3).
///
/// Use cases compose `Result`s; the only exception they need to translate
/// is cooperative cancellation, which unwinds through native/storage code
/// as [OperationCancelledException].
library;

import 'package:vault_domain/vault_domain.dart';

/// Runs [body] and turns a cancellation unwind into `Err(OperationCancelled)`.
/// Any other exception is a programmer error and propagates (§12.4).
Future<Result<T, VaultFailure>> guardUseCase<T>(
  Future<Result<T, VaultFailure>> Function() body,
) async {
  try {
    return await body();
  } on OperationCancelledException catch (e, s) {
    return Err(OperationCancelled(cause: e, trace: s));
  }
}
