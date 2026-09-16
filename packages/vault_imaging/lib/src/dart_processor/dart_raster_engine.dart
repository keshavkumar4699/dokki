/// `DartRasterEngine`: the reference `RasterEngine` over `package:image`
/// (§11.3 steps 3, 4, 6). Same caveat as `DartImageProcessor`: the whole
/// bitmap lives in the Dart heap, so the plan's decode ceiling is enforced
/// by refusal rather than by subsampling. The native engine replaces it
/// without touching `vault_export`.
library;

import 'package:image/image.dart' as img;
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import '../plaintext_source.dart';
import 'dart_decode.dart';

final class DartRasterEngine implements RasterEngine {
  const DartRasterEngine({required this.source});

  final BlobPlaintextSource source;

  @override
  Future<Result<PreparedRaster, VaultFailure>> prepare(
    BlobHandle handle, {
    required RasterPlan plan,
    CancellationToken? cancel,
  }) => guardImaging('prepareRaster', () async {
    final decoded = decodeImageBytes(
      await readAllPlaintext(source, handle, cancel: cancel),
      maxDecodedPixels: plan.maxDecodedPixels,
      cancel: cancel,
    );
    var image = decoded.image;
    final sourceWidth = image.width;
    final sourceHeight = image.height;
    cancel?.throwIfCancelled();
    if (plan.resizes) {
      image = resizeToFit(
        image,
        width: plan.width,
        height: plan.height,
        fit: plan.fit,
        interpolation: interpolationFor(plan.filter),
        background: plan.color.backgroundColor,
      );
    }
    cancel?.throwIfCancelled();
    if (plan.color.bw) {
      image = img.luminanceThreshold(image);
    } else if (plan.color.grayscale) {
      image = img.grayscale(image);
    }
    return DartPreparedRaster._(
      image,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      background: plan.color.backgroundColor,
    );
  });
}

final class DartPreparedRaster implements PreparedRaster {
  DartPreparedRaster._(
    this._image, {
    required this.sourceWidth,
    required this.sourceHeight,
    required int? background,
  }) : _background = background;

  final img.Image _image;
  final int? _background;

  @override
  final int sourceWidth;

  @override
  final int sourceHeight;

  @override
  int get width => _image.width;

  @override
  int get height => _image.height;

  @override
  Future<int> measure(OutputFormat format, int quality) async =>
      _encodeBytes(format, quality).length;

  @override
  Future<EncodedRaster> encode(OutputFormat format, int quality) async =>
      EncodedRaster(
        bytes: _encodeBytes(format, quality),
        width: width,
        height: height,
        format: format,
        quality: quality,
      );

  @override
  Future<PreparedRaster> downscale(double factor) async {
    final w = (width * factor).round().clamp(1, width);
    final h = (height * factor).round().clamp(1, height);
    return DartPreparedRaster._(
      img.copyResize(
        _image,
        width: w,
        height: h,
        interpolation: img.Interpolation.cubic,
      ),
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      background: _background,
    );
  }

  @override
  void dispose() {}

  List<int> _encodeBytes(OutputFormat format, int quality) => switch (format) {
    OutputFormat.png => img.encodePng(_image),
    OutputFormat.jpeg => img.encodeJpg(_flattened(), quality: quality),
    // package:image cannot encode WebP; PDF is composed, not encoded here.
    OutputFormat.webp || OutputFormat.pdf => throw ImagingException(
      UnsupportedFormat(format.dbValue),
    ),
  };

  /// JPEG has no alpha: composite transparent sources onto the background
  /// so they do not come out black.
  img.Image _flattened() {
    if (!_image.hasAlpha) {
      return _image;
    }
    final canvas = img.Image(width: _image.width, height: _image.height)
      ..clear(colorFromArgb(_background ?? 0xFFFFFFFF));
    return img.compositeImage(canvas, _image);
  }
}
