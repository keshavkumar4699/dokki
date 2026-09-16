/// `KeyRotationJob` (§8.6 step 4): rewrites every retired-epoch blob
/// header under the active epoch.
///
/// It is resumable by construction: each blob is an independent file +
/// row, and the epoch-scoped query naturally skips finished ones, so a
/// process kill mid-job simply continues next launch. It is also cheap:
/// DEKs are rewrapped, bodies are never re-encrypted (M9).
library;

import 'dart:typed_data';

import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';

/// What a run did.
final class KeyRotationReport {
  const KeyRotationReport({
    required this.rewrapped,
    required this.remaining,
  });

  /// Headers rewritten in this run.
  final int rewrapped;

  /// Blobs still on retired epochs (0 ⇒ the job is done and the DB can
  /// be rekeyed).
  final int remaining;
}

/// Unwinds a key-backend failure out of the store's guard so the job can
/// report the original failure instead of a generic storage error.
final class _RewrapFailed implements Exception {
  const _RewrapFailed();
}

final class KeyRotationJob {
  const KeyRotationJob({
    required this.keyManager,
    required this.epochBlobs,
    required this.blobStore,
    required this.activeKeyEpoch,
    this.batchSize = 200,
  });

  final KeyManager keyManager;
  final BlobEpochRepository epochBlobs;
  final RotationBlobStore blobStore;
  final int Function() activeKeyEpoch;
  final int batchSize;

  /// Rewraps up to [batchSize] blob headers toward the active epoch.
  /// Call repeatedly (on charge+idle, or right after `rotate()`) until
  /// [KeyRotationReport.remaining] is 0.
  Future<Result<KeyRotationReport, VaultFailure>> run() =>
      guardUseCase(() async {
        final target = activeKeyEpoch();
        final batch = await epochBlobs.listBelowEpoch(
          target,
          limit: batchSize,
        );
        if (batch.isErr) {
          return Err(batch.errOrNull!);
        }
        var done = 0;
        for (final blob in batch.okOrNull!) {
          // Rewrap the DEK once; the SAME bytes go into the file header
          // and the `blobs` row (§6.2 "duplicate of file header"). The
          // old wrapped DEK arrives via the store's callback.
          VaultFailure? rewrapFailure;
          Uint8List? newWrapped;
          final rewritten = await blobStore.rewrapBlobHeader(
            blob.id,
            toEpoch: target,
            rewrapDek: (oldWrapped, purpose) async {
              final result = await keyManager.rewrapDek(
                wrappedDek: oldWrapped,
                fromEpoch: blob.keyEpoch,
                toEpoch: target,
                purpose: purpose,
              );
              return result.fold(
                (value) {
                  newWrapped = Uint8List.fromList(value);
                  return newWrapped!;
                },
                (failure) {
                  rewrapFailure = failure;
                  throw const _RewrapFailed();
                },
              );
            },
          );
          if (rewrapFailure != null) {
            return Err(rewrapFailure!);
          }
          if (rewritten.isErr) {
            return Err(rewritten.errOrNull!);
          }
          final updated = await epochBlobs.updateBlobEpoch(
            blob.id,
            toEpoch: target,
            wrappedDek: newWrapped!,
          );
          if (updated.isErr) {
            return Err(updated.errOrNull!);
          }
          done++;
        }
        final remaining = await epochBlobs.countBelowEpoch(target);
        return remaining.map(
          (count) => KeyRotationReport(rewrapped: done, remaining: count),
        );
      });
}
