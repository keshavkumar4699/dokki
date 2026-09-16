/// `VaultFailure` → user-facing copy (§12.4). Exhaustive: adding a failure
/// subtype without a message here is a compile error, which is the point.
/// Never shows `e.toString()`, a path, or a cause.
library;

import 'package:flutter/material.dart';
import 'package:vault_domain/vault_domain.dart';

import '../bootstrap/providers.dart';

final class FailureCopy {
  const FailureCopy({required this.title, required this.detail, this.action});

  final String title;
  final String detail;

  /// A short verb for the primary button, when the user can do something.
  final String? action;
}

FailureCopy describeFailure(VaultFailure failure) => switch (failure) {
  InvalidAsset() => const FailureCopy(
    title: 'That didn’t work',
    detail: 'The item couldn’t be saved as requested.',
  ),
  CorruptFile() => const FailureCopy(
    title: 'File unreadable',
    detail: 'This image’s data is damaged and can’t be opened.',
  ),
  UnsupportedFormat() => const FailureCopy(
    title: 'Unsupported image',
    detail: 'Pick a JPEG, PNG or WebP image.',
    action: 'Choose another',
  ),
  MissingVersion() => const FailureCopy(
    title: 'Version not found',
    detail: 'That version no longer exists in this vault.',
  ),
  VersionNotRematerializable() => const FailureCopy(
    title: 'Can’t rebuild this version',
    detail:
        'Its edits included a step that can’t be replayed, so the original '
        'bytes are gone. Other versions are unaffected.',
  ),
  EntryInvariantViolated() => const FailureCopy(
    title: 'Not allowed here',
    detail: 'That change would leave the item in an invalid state.',
  ),
  EncryptionFailed() => const FailureCopy(
    title: 'Couldn’t encrypt',
    detail: 'Nothing was saved. Try again.',
    action: 'Retry',
  ),
  DecryptionFailed(:final tamperSuspected) => FailureCopy(
    title: tamperSuspected ? 'Integrity check failed' : 'Couldn’t decrypt',
    detail: tamperSuspected
        ? 'This file was modified outside dokki and will not be shown.'
        : 'The vault key can’t open this file.',
  ),
  KeyUnavailable(:final reason) => switch (reason) {
    KeyUnavailableReason.vaultLocked => const FailureCopy(
      title: 'Vault is locked',
      detail: 'Unlock to continue.',
      action: 'Unlock',
    ),
    KeyUnavailableReason.keystoreInvalidated => const FailureCopy(
      title: 'Device key was reset',
      detail: 'Use your recovery passphrase to restore access.',
      action: 'Recover',
    ),
    KeyUnavailableReason.biometricChanged => const FailureCopy(
      title: 'Biometrics changed',
      detail:
          'A fingerprint or face was added, which invalidates the key. Use '
          'your PIN or recovery passphrase.',
    ),
    KeyUnavailableReason.noDeviceLock => const FailureCopy(
      title: 'Set a screen lock first',
      detail: 'dokki needs a device PIN, pattern or password to protect keys.',
      action: 'Open settings',
    ),
    KeyUnavailableReason.hardwareFailure => const FailureCopy(
      title: 'Secure hardware unavailable',
      detail: 'This device can’t unlock the vault right now.',
    ),
  },
  KeyRotationFailed() => const FailureCopy(
    title: 'Key rotation didn’t finish',
    detail: 'Your data is still readable with the previous key.',
  ),
  InsufficientStorage() => const FailureCopy(
    title: 'Not enough space',
    detail: 'Free up storage on this device, then try again.',
    action: 'Free up space',
  ),
  StorageIoFailure() => const FailureCopy(
    title: 'Storage error',
    detail: 'The file couldn’t be written or read.',
    action: 'Retry',
  ),
  DatabaseFailure() => const FailureCopy(
    title: 'Database error',
    detail: 'The change wasn’t recorded.',
    action: 'Retry',
  ),
  MigrationFailed() => const FailureCopy(
    title: 'Upgrade failed',
    detail: 'The vault database couldn’t be upgraded. Nothing was lost.',
  ),
  InvalidExportDimensions() => const FailureCopy(
    title: 'Invalid export size',
    detail: 'Check the width, height and margins.',
  ),
  SizeUnattainable() => const FailureCopy(
    title: 'Can’t reach that file size',
    detail:
        'Even at the lowest quality the result is larger than the limit. '
        'Allow downscaling or raise the limit.',
  ),
  PdfGenerationFailed() => const FailureCopy(
    title: 'PDF failed',
    detail: 'One of the pages couldn’t be rendered.',
  ),
  ImageProcessingFailed() => const FailureCopy(
    title: 'Edit failed',
    detail: 'The image operation couldn’t be applied. Nothing was changed.',
  ),
  SyncAuthRequired() => const FailureCopy(
    title: 'Sign in again',
    detail: 'Google Drive access expired.',
    action: 'Sign in',
  ),
  SyncTransportFailure() => const FailureCopy(
    title: 'Network problem',
    detail: 'Sync will resume when you’re back online.',
  ),
  CloudRateLimited() => const FailureCopy(
    title: 'Slowing down',
    detail: 'Google Drive asked us to wait. Sync will retry on its own.',
  ),
  CloudQuotaExceeded() => const FailureCopy(
    title: 'Drive is full',
    detail: 'Uploads are paused until space is freed in Google Drive.',
  ),
  RemoteObjectMissing() => const FailureCopy(
    title: 'Missing in Drive',
    detail: 'A synced file was deleted from Drive. It will be re-uploaded.',
  ),
  RemoteObjectTampered() => const FailureCopy(
    title: 'Drive file rejected',
    detail: 'A synced file failed its integrity check and was quarantined.',
  ),
  VersionConflict() => const FailureCopy(
    title: 'Edited on two devices',
    detail: 'Both versions were kept. Choose which one to show.',
    action: 'Review',
  ),
  SyncRequiresUpgrade() => const FailureCopy(
    title: 'Update dokki',
    detail: 'Another device wrote data this version can’t read yet.',
  ),
  OperationCancelled() => const FailureCopy(
    title: 'Cancelled',
    detail: 'Nothing was changed.',
  ),
  OperationInterrupted() => const FailureCopy(
    title: 'Interrupted',
    detail: 'It will resume automatically.',
  ),
  AuthenticationFailed(:final attemptsRemaining) => FailureCopy(
    title: 'Wrong PIN',
    detail: attemptsRemaining == 1
        ? '1 attempt left before a cool-down.'
        : '$attemptsRemaining attempts left.',
  ),
};

/// Unwraps Riverpod's `AsyncError` back into copy.
FailureCopy describeError(Object error) => switch (error) {
  VaultFailureException(:final failure) => describeFailure(failure),
  _ => const FailureCopy(
    title: 'Something went wrong',
    detail: 'Please try again.',
    action: 'Retry',
  ),
};

/// Shows a failure as a floating snackbar with optional action.
void showFailureSnack(
  BuildContext context,
  VaultFailure failure, {
  VoidCallback? onAction,
}) {
  final copy = describeFailure(failure);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${copy.title} — ${copy.detail}'),
        action: copy.action != null && onAction != null
            ? SnackBarAction(label: copy.action!, onPressed: onAction)
            : null,
      ),
    );
}
