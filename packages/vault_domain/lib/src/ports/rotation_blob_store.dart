/// `RotationBlobStore`: the header-rewrite capability the key-rotation
/// job needs (§8.6 step 4). `FileBlobStore` implements it; the job lives
/// in `vault_app_core` and must not import `vault_storage` (§3).
library;

import 'dart:typed_data';

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';

abstract interface class RotationBlobStore {
  /// Rewrites [id]'s envelope header under [toEpoch]: same DEK (rewrapped
  /// by [rewrapDek], never exposed), same salt and flags, fresh header
  /// tag. Atomic (`.part` + rename); the body is streamed, never loaded.
  Future<Result<void, VaultFailure>> rewrapBlobHeader(
    BlobId id, {
    required int toEpoch,
    required Future<Uint8List> Function(Uint8List wrappedDek, int purpose)
    rewrapDek,
  });
}
