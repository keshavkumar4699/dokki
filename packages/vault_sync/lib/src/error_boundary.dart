/// The ONE translation boundary of `vault_sync` (§12.3).
library;

import 'package:vault_domain/vault_domain.dart';

/// Carries a [VaultFailure] through the throw-based guard.
final class SyncException implements Exception {
  const SyncException(this.failure);

  final VaultFailure failure;
}

/// A segment demands a newer op-log reader than this build ships (§9.6
/// rule 5): halt instead of corrupting state.
final class SegmentRequiresUpgrade implements Exception {
  const SegmentRequiresUpgrade(this.minReaderVersion);

  final int minReaderVersion;
}

Future<Result<T, VaultFailure>> guardSync<T>(
  String op,
  Future<T> Function() body,
) async {
  try {
    return Ok(await body());
  } on SyncException catch (e) {
    return Err(e.failure);
  } on SegmentRequiresUpgrade catch (e, s) {
    return Err(SyncRequiresUpgrade(e.minReaderVersion, cause: e, trace: s));
  } on OperationCancelledException catch (e, s) {
    return Err(OperationCancelled(cause: e, trace: s));
  } on FormatException catch (e, s) {
    // A malformed segment payload is the integrity failure, not a bug.
    return Err(RemoteObjectTampered(op, cause: e, trace: s));
  }
}

/// Unwraps a [Result] or throws for the guard.
T unwrapSync<T>(Result<T, VaultFailure> result) => result.fold(
  (value) => value,
  (failure) => throw SyncException(failure),
);
