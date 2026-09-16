/// Shared decode/resample helpers for the Dart reference pipeline, used by
/// both `DartImageProcessor` and `DartRasterEngine` so their semantics
/// cannot drift.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import '../plaintext_source.dart';

final class DecodedSource {
  const DecodedSource({required this.image, required this.mime});

  final img.Image image;
  final String mime;
}

/// Reads the whole plaintext of [handle]. The reference pipeline needs the
/// bytes in memory; the native pipeline streams instead.
Future<Uint8List> readAllPlaintext(
  BlobPlaintextSource source,
  BlobHandle handle, {
  CancellationToken? cancel,
}) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in source.openPlaintext(handle)) {
    cancel?.throwIfCancelled();
    builder.add(chunk);
  }
  return builder.takeBytes();
}

/// Decodes [bytes] with EXIF orientation baked in, refusing anything over
/// [maxDecodedPixels] (R2) *before* allocating a pixel buffer.
DecodedSource decodeImageBytes(
  Uint8List bytes, {
  required int maxDecodedPixels,
  CancellationToken? cancel,
}) {
  final decoder = img.findDecoderForData(bytes);
  if (decoder == null) {
    throw const ImagingException(UnsupportedFormat('unknown'));
  }
  final info = decoder.startDecode(bytes);
  if (info == null) {
    throw const ImagingException(UnsupportedFormat('undecodable'));
  }
  if (info.width * info.height > maxDecodedPixels) {
    throw ImagingException(
      ImageProcessingFailed(
        'decode: ${info.width}x${info.height} exceeds $maxDecodedPixels px',
      ),
    );
  }
  cancel?.throwIfCancelled();
  final image = decoder.decode(bytes);
  if (image == null) {
    throw const ImagingException(UnsupportedFormat('undecodable'));
  }
  return DecodedSource(image: img.bakeOrientation(image), mime: mimeOf(decoder));
}

String mimeOf(img.Decoder decoder) => switch (decoder) {
  img.JpegDecoder() => 'image/jpeg',
  img.PngDecoder() => 'image/png',
  img.WebPDecoder() => 'image/webp',
  img.GifDecoder() => 'image/gif',
  img.BmpDecoder() => 'image/bmp',
  _ => 'application/octet-stream',
};

img.Interpolation interpolationFor(ResampleFilter filter) => switch (filter) {
  ResampleFilter.lanczos => img.Interpolation.cubic,
  ResampleFilter.bilinear => img.Interpolation.linear,
  ResampleFilter.nearest => img.Interpolation.nearest,
};

/// Resizes [image] into a `width × height` box under [fit]; a `null` edge
/// follows the aspect ratio. [background] (ARGB) fills the letterbox for
/// [FitMode.pad]; white when null.
img.Image resizeToFit(
  img.Image image, {
  required int? width,
  required int? height,
  required FitMode fit,
  img.Interpolation interpolation = img.Interpolation.average,
  int? background,
}) {
  if (width == null && height == null) {
    return image;
  }
  final aspect = image.width / image.height;
  final targetW = width ?? (height! * aspect).round().clamp(1, 1 << 20);
  final targetH = height ?? (width! / aspect).round().clamp(1, 1 << 20);
  switch (fit) {
    case FitMode.stretch:
      return img.copyResize(
        image,
        width: targetW,
        height: targetH,
        interpolation: interpolation,
      );
    case FitMode.contain:
    case FitMode.pad:
      final scale = _min(targetW / image.width, targetH / image.height);
      final resized = img.copyResize(
        image,
        width: (image.width * scale).round().clamp(1, targetW),
        height: (image.height * scale).round().clamp(1, targetH),
        interpolation: interpolation,
      );
      if (fit == FitMode.contain) {
        return resized;
      }
      final canvas = img.Image(width: targetW, height: targetH)
        ..clear(colorFromArgb(background ?? 0xFFFFFFFF));
      return img.compositeImage(
        canvas,
        resized,
        dstX: (targetW - resized.width) ~/ 2,
        dstY: (targetH - resized.height) ~/ 2,
      );
    case FitMode.cover:
      final scale = _max(targetW / image.width, targetH / image.height);
      final resized = img.copyResize(
        image,
        width: (image.width * scale).ceil(),
        height: (image.height * scale).ceil(),
        interpolation: interpolation,
      );
      return img.copyCrop(
        resized,
        x: (resized.width - targetW) ~/ 2,
        y: (resized.height - targetH) ~/ 2,
        width: targetW,
        height: targetH,
      );
  }
}

img.Color colorFromArgb(int argb) => img.ColorRgb8(
  (argb >> 16) & 0xFF,
  (argb >> 8) & 0xFF,
  argb & 0xFF,
);

double _min(double a, double b) => a < b ? a : b;

double _max(double a, double b) => a > b ? a : b;
