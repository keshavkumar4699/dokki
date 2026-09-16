/// `CloudProvider` port (§9.1).
///
/// The domain knows about a cloud, not about Google. `vault_drive` is the
/// only package that has ever heard of `googleapis`. Adding Dropbox or S3
/// later is a new package implementing this same port.
///
/// Note that `put` takes a CIPHERTEXT stream — the type signature makes it
/// impossible to hand plaintext to a cloud provider (§9.1).
library;

import '../failures/vault_failure.dart';
import '../result.dart';
import 'blob_store.dart';

enum CloudAuthState { unknown, signedOut, signedIn, refreshRequired }

final class RemoteObject {
  const RemoteObject({
    required this.remoteId,
    required this.name,
    this.sizeBytes,
    this.checksum,
    this.modifiedAt,
  });

  /// Provider-side identifier (Drive fileId).
  final String remoteId;

  /// Opaque name (`b_<uuid>.bin`, `l_<dev>_<seq>.bin`).
  final String name;

  final int? sizeBytes;

  /// Provider-reported checksum — advisory only, ours is authoritative.
  final String? checksum;

  final DateTime? modifiedAt;
}

final class CloudQuota {
  const CloudQuota({this.usedBytes, this.limitBytes});

  final int? usedBytes;
  final int? limitBytes;
}

final class ByteRange {
  const ByteRange({this.start, this.end});

  final int? start;
  final int? end;

  bool get isOpenEnded => end == null;

  bool get isEmpty => end != null && start != null && end! <= start!;
}

abstract interface class CloudProvider {
  /// Stable identifier, e.g. `google_drive`.
  String get providerId;

  Future<Result<CloudAuthState, VaultFailure>> authState();

  /// Triggers sign-in if needed. Returns when authorised.
  Future<Result<void, VaultFailure>> ensureAuthorized();

  /// Uploads [ciphertext] under [opaqueName]. Idempotent by name: a
  /// retry with the same bytes is a no-op.
  Future<Result<RemoteObject, VaultFailure>> put(
    String opaqueName,
    Stream<List<int>> ciphertext, {
    required int totalBytes,
    Map<String, String> routingProps = const {},
    String? resumeToken,
    ProgressSink? progress,
    CancellationToken? cancel,
  });

  /// Downloads the object's bytes.
  Future<Result<Stream<List<int>>, VaultFailure>> get(
    String remoteId, {
    ByteRange? range,
  });

  Future<Result<List<RemoteObject>, VaultFailure>> list({
    String? namePrefix,
    String? pageToken,
  });

  Future<Result<void, VaultFailure>> delete(String remoteId);

  Future<Result<CloudQuota, VaultFailure>> quota();
}
