/// The sealed failure hierarchy (§12.2).
///
/// Every failure carries a stable, loggable, never-localised [code] string.
/// Because the hierarchy is sealed, an exhaustive `switch` over it fails to
/// compile when a new subtype is added without handling — which is the point.
library;

import '../ids.dart';

/// Base class of every expected failure in the system.
///
/// Unexpected (programmer) errors are thrown, not wrapped; see §12.4.
sealed class VaultFailure {
  const VaultFailure({this.isRetryable = false, this.cause, this.trace});

  /// Stable machine-readable code, e.g. `ASSET_CORRUPT`. Never localised.
  String get code;

  /// Whether retrying the identical operation might succeed.
  final bool isRetryable;

  /// The original library exception, when one exists. Never surfaced to UI.
  final Object? cause;

  /// Stack trace captured at the failure site. Never surfaced to UI.
  final StackTrace? trace;

  @override
  String toString() => 'VaultFailure($code)';
}

// ── Asset & data ───────────────────────────────────────────────────────────

/// An entity violates a domain rule that the database also enforces.
final class InvalidAsset extends VaultFailure {
  const InvalidAsset(this.reason, {super.cause, super.trace});

  @override
  String get code => 'INVALID_ASSET';

  final String reason;
}

/// A blob's bytes are unreadable or fail integrity verification.
final class CorruptFile extends VaultFailure {
  const CorruptFile(this.blobId, {super.cause, super.trace});

  @override
  String get code => 'CORRUPT_FILE';

  final BlobId blobId;
}

/// The stored bytes are not a format we can decode.
final class UnsupportedFormat extends VaultFailure {
  const UnsupportedFormat(this.mime, {super.cause, super.trace});

  @override
  String get code => 'UNSUPPORTED_FORMAT';

  final String mime;
}

/// A referenced version row does not exist.
final class MissingVersion extends VaultFailure {
  const MissingVersion(this.id, {super.cause, super.trace});

  @override
  String get code => 'MISSING_VERSION';

  final VersionId id;
}

/// An evicted version cannot be reconstructed because its recipe is
/// non-deterministic (e.g. an ML background removal).
final class VersionNotRematerializable extends VaultFailure {
  const VersionNotRematerializable(this.id, {super.cause, super.trace});

  @override
  String get code => 'VERSION_NOT_REMATERIALIZABLE';

  final VersionId id;
}

/// An `EntryInvariants` check failed.
final class EntryInvariantViolated extends VaultFailure {
  const EntryInvariantViolated(this.invariant, {super.cause, super.trace});

  @override
  String get code => 'ENTRY_INVARIANT_VIOLATED';

  final String invariant;
}

// ── Crypto ─────────────────────────────────────────────────────────────────

/// Sealing (encryption) failed.
final class EncryptionFailed extends VaultFailure {
  const EncryptionFailed({super.cause, super.trace});

  @override
  String get code => 'ENCRYPTION_FAILED';
}

/// Opening (decryption) failed. [tamperSuspected] is true when the AEAD tag
/// failed, which means the bytes were modified or the key is wrong.
final class DecryptionFailed extends VaultFailure {
  const DecryptionFailed({
    this.blobId,
    this.tamperSuspected = false,
    super.cause,
    super.trace,
  });

  @override
  String get code => 'DECRYPTION_FAILED';

  final BlobId? blobId;
  final bool tamperSuspected;
}

/// A required key cannot be used right now.
final class KeyUnavailable extends VaultFailure {
  const KeyUnavailable(this.reason, {super.cause, super.trace});

  @override
  String get code => 'KEY_UNAVAILABLE';

  final KeyUnavailableReason reason;
}

/// Why a key is unavailable. Stable strings; exhaustive switch upstream.
enum KeyUnavailableReason {
  vaultLocked('VAULT_LOCKED'),
  keystoreInvalidated('KEYSTORE_INVALIDATED'),
  biometricChanged('BIOMETRIC_CHANGED'),
  noDeviceLock('NO_DEVICE_LOCK'),
  hardwareFailure('HARDWARE_FAILURE');

  const KeyUnavailableReason(this.code);

  final String code;
}

/// Key rotation failed part-way. The old epoch remains readable.
final class KeyRotationFailed extends VaultFailure {
  const KeyRotationFailed(
    this.fromEpoch,
    this.toEpoch, {
    super.cause,
    super.trace,
  });

  @override
  String get code => 'KEY_ROTATION_FAILED';

  final int fromEpoch;
  final int toEpoch;
}

// ── Storage ────────────────────────────────────────────────────────────────

/// Not enough free space to start (not finish) the write.
final class InsufficientStorage extends VaultFailure {
  const InsufficientStorage(
    this.neededBytes,
    this.availableBytes, {
    super.cause,
    super.trace,
  });

  @override
  String get code => 'INSUFFICIENT_STORAGE';

  final int neededBytes;
  final int availableBytes;
}

/// A filesystem operation failed.
final class StorageIoFailure extends VaultFailure {
  const StorageIoFailure(this.op, {super.cause, super.trace});

  @override
  String get code => 'STORAGE_IO';

  final String op;
}

/// A database operation failed.
final class DatabaseFailure extends VaultFailure {
  const DatabaseFailure(this.op, {super.cause, super.trace});

  @override
  String get code => 'DATABASE_FAILURE';

  final String op;
}

/// A schema or data migration failed.
final class MigrationFailed extends VaultFailure {
  const MigrationFailed(this.from, this.to, {super.cause, super.trace});

  @override
  String get code => 'MIGRATION_FAILED';

  final int from;
  final int to;
}

// ── Export ─────────────────────────────────────────────────────────────────

/// The export request is impossible (dimensions, layout, format mismatch).
final class InvalidExportDimensions extends VaultFailure {
  const InvalidExportDimensions(this.constraint, {super.cause, super.trace});

  @override
  String get code => 'INVALID_EXPORT_DIMENSIONS';

  final String constraint;
}

/// `maxBytes` cannot be met even at the quality floor and max downscale.
final class SizeUnattainable extends VaultFailure {
  const SizeUnattainable(
    this.bestBytes,
    this.maxBytes, {
    super.cause,
    super.trace,
  });

  @override
  String get code => 'SIZE_UNATTAINABLE';

  final int bestBytes;
  final int maxBytes;
}

/// PDF generation failed, optionally per page.
final class PdfGenerationFailed extends VaultFailure {
  const PdfGenerationFailed({this.pageIndex, super.cause, super.trace});

  @override
  String get code => 'PDF_GENERATION_FAILED';

  final int? pageIndex;
}

/// A native image operation failed.
final class ImageProcessingFailed extends VaultFailure {
  const ImageProcessingFailed(this.opId, {super.cause, super.trace});

  @override
  String get code => 'IMAGE_PROCESSING_FAILED';

  final String opId;
}

// ── Sync ───────────────────────────────────────────────────────────────────

/// Drive auth is required and cannot be refreshed automatically.
final class SyncAuthRequired extends VaultFailure {
  const SyncAuthRequired({super.cause, super.trace});

  @override
  String get code => 'SYNC_AUTH_REQUIRED';

  @override
  bool get isRetryable => false;
}

/// A network-level failure talking to the cloud provider.
final class SyncTransportFailure extends VaultFailure {
  const SyncTransportFailure({this.httpStatus, super.cause, super.trace});

  @override
  String get code => 'SYNC_TRANSPORT';

  @override
  bool get isRetryable => true;

  final int? httpStatus;
}

/// The cloud provider rate-limited us; retry after backing off.
final class CloudRateLimited extends VaultFailure {
  const CloudRateLimited({this.retryAfter, super.cause, super.trace});

  @override
  String get code => 'CLOUD_RATE_LIMITED';

  @override
  bool get isRetryable => true;

  final Duration? retryAfter;
}

/// Cloud storage quota exhausted; uploads must stop.
final class CloudQuotaExceeded extends VaultFailure {
  const CloudQuotaExceeded({
    this.usedBytes,
    this.limitBytes,
    super.cause,
    super.trace,
  });

  @override
  String get code => 'CLOUD_QUOTA_EXCEEDED';

  final int? usedBytes;
  final int? limitBytes;
}

/// The remote object vanished (deleted in Drive by someone else).
final class RemoteObjectMissing extends VaultFailure {
  const RemoteObjectMissing(this.remoteId, {super.cause, super.trace});

  @override
  String get code => 'REMOTE_OBJECT_MISSING';

  final String remoteId;
}

/// The remote object failed our integrity checks.
final class RemoteObjectTampered extends VaultFailure {
  const RemoteObjectTampered(this.remoteId, {super.cause, super.trace});

  @override
  String get code => 'REMOTE_OBJECT_TAMPERED';

  final String remoteId;
}

/// A sync conflict was detected and recorded; the operation is on hold.
final class VersionConflict extends VaultFailure {
  const VersionConflict(this.id, {super.cause, super.trace});

  @override
  String get code => 'VERSION_CONFLICT';

  final ConflictId id;
}

/// A peer's log requires a newer app; this device must upgrade.
final class SyncRequiresUpgrade extends VaultFailure {
  const SyncRequiresUpgrade(this.minVersion, {super.cause, super.trace});

  @override
  String get code => 'SYNC_REQUIRES_UPGRADE';

  final int minVersion;
}

// ── Lifecycle ──────────────────────────────────────────────────────────────

/// The operation was cancelled by the user.
final class OperationCancelled extends VaultFailure {
  const OperationCancelled({super.cause, super.trace});

  @override
  String get code => 'OPERATION_CANCELLED';
}

/// The operation was interrupted but can be resumed from [resumeToken].
final class OperationInterrupted extends VaultFailure {
  const OperationInterrupted(this.resumeToken, {super.cause, super.trace});

  @override
  String get code => 'OPERATION_INTERRUPTED';

  @override
  bool get isRetryable => true;

  final String resumeToken;
}

/// PIN/passphrase verification failed; [attemptsRemaining] tries left.
final class AuthenticationFailed extends VaultFailure {
  const AuthenticationFailed(
    this.attemptsRemaining, {
    super.cause,
    super.trace,
  });

  @override
  String get code => 'AUTHENTICATION_FAILED';

  final int attemptsRemaining;
}
