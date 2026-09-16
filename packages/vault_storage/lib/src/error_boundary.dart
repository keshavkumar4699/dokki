/// The ONE translation boundary of `vault_storage` (§12.3).
library;

import 'dart:io';

import 'package:vault_crypto/vault_crypto.dart' show TagVerificationFailed;
import 'package:vault_domain/vault_domain.dart';

/// Carries a [VaultFailure] through the throw-based guard.
final class StorageException implements Exception {
  const StorageException(this.failure);

  final VaultFailure failure;
}

/// Runs [body] and translates filesystem and envelope exceptions into
/// [VaultFailure] values.
Future<Result<T, VaultFailure>> guardIo<T>(
  String op,
  Future<T> Function() body, {
  BlobId? blobId,
}) async {
  try {
    return Ok(await body());
  } on StorageException catch (e) {
    return Err(e.failure);
  } on OperationCancelledException catch (e, s) {
    return Err(OperationCancelled(cause: e, trace: s));
  } on TagVerificationFailed catch (e, s) {
    return Err(
      DecryptionFailed(
        blobId: blobId,
        tamperSuspected: true,
        cause: e,
        trace: s,
      ),
    );
  } on FormatException catch (e, s) {
    // A malformed envelope header: the file is not one of ours or is
    // damaged before the first authenticated byte.
    return Err(
      blobId == null
          ? DecryptionFailed(cause: e, trace: s)
          : CorruptFile(blobId, cause: e, trace: s),
    );
  } on FileSystemException catch (e, s) {
    return Err(_translateFs(op, e, s));
  } on StateError catch (e, s) {
    // The primitive refuses to derive keys while the vault is locked.
    return Err(
      KeyUnavailable(KeyUnavailableReason.vaultLocked, cause: e, trace: s),
    );
  }
}

VaultFailure _translateFs(String op, FileSystemException e, StackTrace s) {
  final errno = e.osError?.errorCode;
  // ENOSPC on Linux/Android (28); ERROR_DISK_FULL / HANDLE_DISK_FULL on
  // Windows (112 / 39) so desktop dev runs classify the same way.
  if (errno == 28 || errno == 112 || errno == 39) {
    return InsufficientStorage(0, 0, cause: e, trace: s);
  }
  return StorageIoFailure(op, cause: e, trace: s);
}
