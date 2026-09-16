/// `DartImageProcessor`: the deterministic reference implementation of
/// `ImageProcessor` over `package:image` (§15.5).
///
/// ⚠ This decodes full-resolution bitmaps in the Dart heap, which the
/// architecture rejects for production (R2, M10). It is the fallback and
/// the reference implementation the native pipeline is tested against; a
/// [maxDecodedPixels] ceiling keeps it from OOM-ing a low-end device in
/// the meantime by refusing, rather than attempting, oversized decodes.
///
/// Ops are applied in recipe order with coordinates normalised to 0..1, so
/// a recipe recorded against a 4000 px original applies identically to a
/// 1000 px preview (§5.3).
library;

import 'package:image/image.dart' as img;
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import '../plaintext_source.dart';
import 'dart_decode.dart';

final class DartImageProcessor implements ImageProcessor {
  const DartImageProcessor({
    required this.source,
    required this.blobStore,
    this.maxDecodedPixels = 24 * 1024 * 1024,
    this.jpegQuality = 92,
  });

  final BlobPlaintextSource source;
  final BlobStore blobStore;

  /// Refuse to decode anything larger than this (R2). 24 MP ≈ 96 MB ARGB.
  final int maxDecodedPixels;

  /// Quality for re-encoded JPEG output.
  final int jpegQuality;

  // ── Inspection ─────────────────────────────────────────────────────────

  @override
  Future<Result<ImageInfo, VaultFailure>> inspect(BlobHandle handle) =>
      guardImaging('inspect', () async {
        final bytes = await readAllPlaintext(source, handle);
        final decoder = img.findDecoderForData(bytes);
        if (decoder == null) {
          throw const ImagingException(UnsupportedFormat('unknown'));
        }
        // Header-only decode: no pixel buffer is allocated.
        final info = decoder.startDecode(bytes);
        if (info == null) {
          throw const ImagingException(UnsupportedFormat('undecodable'));
        }
        return ImageInfo(
          width: info.width,
          height: info.height,
          mime: mimeOf(decoder),
        );
      });

  // ── Editing ────────────────────────────────────────────────────────────

  @override
  Future<Result<ProcessedImage, VaultFailure>> apply(
    BlobHandle source, {
    required List<ImageOp> ops,
    DecodeSpec? decode,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => applyChain(
    source,
    chain: [ops],
    decode: decode,
    progress: progress,
    cancel: cancel,
  );

  @override
  Future<Result<ProcessedImage, VaultFailure>> applyChain(
    BlobHandle original, {
    required List<List<ImageOp>> chain,
    DecodeSpec? decode,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardImaging('applyChain', () async {
    final decoded = await _decode(original, cancel: cancel);
    var image = decoded.image;
    final total = chain.fold<int>(0, (n, ops) => n + ops.length);
    var done = 0;
    for (final ops in chain) {
      for (final op in ops) {
        cancel?.throwIfCancelled();
        image = _applyOp(image, op);
        progress?.call(++done, total);
      }
    }
    return _encodeAndStore(
      image,
      mime: decode?.preferredMime ?? decoded.mime,
      storageClass: StorageClass.asset,
      cancel: cancel,
    );
  });

  @override
  Future<Result<ProcessedImage, VaultFailure>> preview(
    BlobHandle source, {
    int maxEdge = 1024,
    String preferredMime = 'image/jpeg',
    int quality = 85,
    StorageClass storageClass = StorageClass.thumbnail,
  }) => guardImaging('preview', () async {
    final decoded = await _decode(source);
    var image = decoded.image;
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxEdge) {
      final scale = maxEdge / longest;
      image = img.copyResize(
        image,
        width: (image.width * scale).round().clamp(1, maxEdge),
        height: (image.height * scale).round().clamp(1, maxEdge),
        interpolation: img.Interpolation.average,
      );
    }
    return _encodeAndStore(
      image,
      mime: preferredMime,
      storageClass: storageClass,
      quality: quality,
    );
  });

  // ── Op semantics (the reference the native pipeline must match) ────────

  img.Image _applyOp(img.Image image, ImageOp op) => switch (op) {
    CropOp(:final rect) => _crop(image, rect),
    RotateOp(:final quarterTurns) => switch (quarterTurns % 4) {
      0 => image,
      1 => img.copyRotate(image, angle: 90),
      2 => img.copyRotate(image, angle: 180),
      _ => img.copyRotate(image, angle: 270),
    },
    BrightnessOp(:final delta) => img.adjustColor(image, brightness: 1 + delta),
    ContrastOp(:final factor) => img.adjustColor(image, contrast: factor),
    ExposureOp(:final ev) => img.adjustColor(image, exposure: ev),
    SharpenOp(:final amount) =>
      amount <= 0
          ? image
          : img.convolution(
              image,
              filter: [
                0,
                -amount,
                0,
                -amount,
                1 + 4 * amount,
                -amount,
                0,
                -amount,
                0,
              ],
            ),
    ResizeOp(:final width, :final height, :final fit) => resizeToFit(
      image,
      width: width,
      height: height,
      fit: fit,
    ),
    FilterOp(:final id) => switch (id) {
      'grayscale' => img.grayscale(image),
      'sepia' => img.sepia(image),
      'invert' => img.invert(image),
      'bw' => img.luminanceThreshold(image),
      _ => throw ImagingException(ImageProcessingFailed('filter:$id')),
    },
    // Phase 8 (§17): the op types exist so recipes can carry them; the
    // reference pipeline has no CV kernels.
    PerspectiveOp() => throw const ImagingException(
      ImageProcessingFailed('perspective'),
    ),
    DenoiseOp() => throw const ImagingException(
      ImageProcessingFailed('denoise'),
    ),
    BackgroundOp() => throw const ImagingException(
      ImageProcessingFailed('background'),
    ),
  };

  static img.Image _crop(img.Image image, RectN rect) {
    final x = (rect.left * image.width).round().clamp(0, image.width - 1);
    final y = (rect.top * image.height).round().clamp(0, image.height - 1);
    final right = (rect.right * image.width).round().clamp(x + 1, image.width);
    final bottom = (rect.bottom * image.height).round().clamp(
      y + 1,
      image.height,
    );
    return img.copyCrop(
      image,
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );
  }

  // ── Decode / encode ────────────────────────────────────────────────────

  Future<DecodedSource> _decode(
    BlobHandle handle, {
    CancellationToken? cancel,
  }) async => decodeImageBytes(
    await readAllPlaintext(source, handle, cancel: cancel),
    maxDecodedPixels: maxDecodedPixels,
    cancel: cancel,
  );

  Future<ProcessedImage> _encodeAndStore(
    img.Image image, {
    required String mime,
    required StorageClass storageClass,
    int? quality,
    CancellationToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    final (encoded, outMime) = switch (mime) {
      'image/png' => (img.encodePng(image), 'image/png'),
      _ => (
        img.encodeJpg(image, quality: quality ?? jpegQuality),
        'image/jpeg',
      ),
    };
    final written = await blobStore.write(
      Stream.value(encoded),
      storageClass: storageClass,
      expectedSize: encoded.length,
      cancel: cancel,
    );
    final blob = written.fold(
      (ref) => ref,
      (failure) => throw ImagingException(failure),
    );
    return ProcessedImage(
      blobRef: blob,
      meta: ImageMeta(
        width: image.width,
        height: image.height,
        mime: outMime,
        plaintextSha256: blob.plaintextSha256,
        byteSize: blob.plaintextSize,
      ),
    );
  }
}
