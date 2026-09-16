/// The segment sealer (§9.3): turns the local device's durable op buffer
/// into an immutable, sealed segment file and queues it for upload.
///
/// A segment seals at 256 KiB of payload or 5 minutes of age, whichever
/// comes first. Sealed segments are immutable, so upload is idempotent —
/// re-uploading identical bytes under the same name is a no-op the cloud
/// side detects by ciphertext hash.
library;

import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';
import 'op_codec.dart';

final class SegmentSealer {
  const SegmentSealer({
    required this.syncState,
    required this.blobStore,
    required this.clock,
    this.maxPayloadBytes = 256 * 1024,
    this.maxAge = const Duration(minutes: 5),
  });

  final SyncStateRepository syncState;
  final BlobStore blobStore;
  final Clock clock;

  /// Payload size at which a segment seals immediately.
  final int maxPayloadBytes;

  /// Wall-clock age (measured on the first op's HLC) after which a
  /// non-empty open segment seals.
  final Duration maxAge;

  /// Seals the device's open segment when it is due and queues the
  /// upload. Returns the sealed record, or null when there is nothing to
  /// seal (or it is not due yet).
  Future<Result<LogSegmentRecord?, VaultFailure>> sealIfDue(
    DeviceId deviceId,
  ) => guardSync('sealIfDue', () async {
    final open = unwrapSync(await syncState.openSegment(deviceId));
    if (open == null || open.opCount == 0) {
      return null;
    }
    final ops = unwrapSync(await syncState.openSegmentOps(deviceId));
    if (ops.isEmpty) {
      return null;
    }
    final payload = encodeSegmentPayload(
      deviceId: deviceId,
      seq: open.seq,
      ops: ops,
    );
    final aged =
        open.hlcLow != null &&
        clock.now().millisecondsSinceEpoch -
                Hlc.parse(open.hlcLow!).physicalMillis >=
            maxAge.inMilliseconds;
    if (payload.length < maxPayloadBytes && !aged) {
      return null;
    }

    final written = unwrapSync(
      await blobStore.write(
        Stream.value(payload.codeUnits),
        storageClass: StorageClass.syncLog,
        expectedSize: payload.length,
      ),
    );
    final sealed = unwrapSync(
      await syncState.sealSegment(
        deviceId: deviceId,
        blob: written,
        opCount: ops.length,
        hlcLow: open.hlcLow ?? ops.first.hlc.toSortableString(),
        hlcHigh: ops.last.hlc.toSortableString(),
        now: clock.now(),
      ),
    );
    // Upload is a queue op, idempotent by the segment's identity.
    unwrapSync(
      await syncState.enqueueUploadBlob(
        blobId: written.id,
        remoteName: sealed.remoteName,
        idempotencyKey: 'segment:$deviceId:${sealed.seq}',
        priority: 50, // segments outrank blob bodies: metadata first
        now: clock.now(),
      ),
    );
    return sealed;
  });
}
