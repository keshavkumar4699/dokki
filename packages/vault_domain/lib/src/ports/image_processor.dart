/// `ImageProcessor` port.
///
/// Operations run on opaque handles; full-resolution plaintext exists only
/// on the native side (§8.4).
library;

import '../failures/vault_failure.dart';
import '../imaging/decode_spec.dart';
import '../imaging/image_meta.dart';
import '../imaging/image_op.dart';
import '../result.dart';
import 'blob_store.dart';

/// Result of a processing pass: a NEW sealed blob plus its metadata.
final class ProcessedImage {
  const ProcessedImage({required this.blobRef, required this.meta});

  final BlobRef blobRef;
  final ImageMeta meta;
}

/// Result of inspecting a source without decoding it fully.
final class ImageInfo {
  const ImageInfo({
    required this.width,
    required this.height,
    required this.mime,
  });

  final int width;
  final int height;
  final String mime;
}

abstract interface class ImageProcessor {
  /// Applies [ops] to [source] and returns a NEW sealed blob (§2.1).
  Future<Result<ProcessedImage, VaultFailure>> apply(
    BlobHandle source, {
    required List<ImageOp> ops,
    DecodeSpec? decode,
    ProgressSink? progress,
    CancellationToken? cancel,
  });

  /// Applies a lineage chain of op lists (re-materialization, §10.3):
  /// original + chain[0] + chain[1] + … The result must equal the stored
  /// derived version byte-for-byte when all ops are deterministic.
  Future<Result<ProcessedImage, VaultFailure>> applyChain(
    BlobHandle original, {
    required List<List<ImageOp>> chain,
    DecodeSpec? decode,
    ProgressSink? progress,
    CancellationToken? cancel,
  });

  /// Reads dimensions and format without full decode.
  Future<Result<ImageInfo, VaultFailure>> inspect(BlobHandle source);

  /// Produces a downsampled preview of [source] (≤ [maxEdge] px on the
  /// longest edge), for the editor and quick export.
  Future<Result<ProcessedImage, VaultFailure>> preview(
    BlobHandle source, {
    int maxEdge = 1024,
    String preferredMime = 'image/jpeg',
    int quality = 85,
    StorageClass storageClass = StorageClass.thumbnail,
  });
}
