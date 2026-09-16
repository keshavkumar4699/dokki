/// User-actionable recovery attached to a failure (§12.5).
///
/// A failure the user cannot act on is a dead end; every surfaced failure
/// carries exactly one of these.
library;

import '../ids.dart';

sealed class RecoveryAction {
  const RecoveryAction();
}

final class RetryNow extends RecoveryAction {
  const RetryNow();
}

final class RetryLater extends RecoveryAction {
  const RetryLater(this.after);

  final Duration after;
}

final class Reauthenticate extends RecoveryAction {
  const Reauthenticate();
}

final class FreeUpSpace extends RecoveryAction {
  const FreeUpSpace(this.neededBytes);

  final int neededBytes;
}

final class RestoreFromCloud extends RecoveryAction {
  const RestoreFromCloud(this.blobId);

  final BlobId blobId;
}

final class UseCurrentVersion extends RecoveryAction {
  const UseCurrentVersion(this.fallback);

  final VersionId fallback;
}

final class ContactSupport extends RecoveryAction {
  const ContactSupport(this.diagnosticCode);

  final String diagnosticCode;
}

final class NoActionPossible extends RecoveryAction {
  const NoActionPossible(this.explanation);

  final String explanation;
}
