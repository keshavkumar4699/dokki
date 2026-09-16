/// `BlobEpochRepository`: the rotation job's view over the `blobs` table
/// (§8.6 step 4). Lists blobs sealed under retired epochs and records
/// their rewrapped DEKs.
library;

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';
import '../security/envelope_purpose.dart';

/// One blob the rotation job must rewrap.
final class BlobEpochRef {
  const BlobEpochRef({
    required this.id,
    required this.purpose,
    required this.keyEpoch,
  });

  final BlobId id;

  /// Its envelope purpose (the wrapping key family, §7.2).
  final EnvelopePurpose purpose;

  /// The epoch it is currently sealed under.
  final int keyEpoch;
}

abstract interface class BlobEpochRepository {
  /// How many blobs are still sealed under retired epochs.
  Future<Result<int, VaultFailure>> countBelowEpoch(int epoch);

  /// A batch of blobs below [epoch], oldest first.
  Future<Result<List<BlobEpochRef>, VaultFailure>> listBelowEpoch(
    int epoch, {
    int limit = 200,
  });

  /// Records a blob's rewrapped DEK and new epoch after its header was
  /// rewritten on disk (§8.6: file first, then the row).
  Future<Result<void, VaultFailure>> updateBlobEpoch(
    BlobId blobId, {
    required int toEpoch,
    required List<int> wrappedDek,
  });
}
