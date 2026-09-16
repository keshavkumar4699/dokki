/// `RasterEngine` port: pipeline steps 3, 4 and 6 of §11.3 (decode,
/// raster, encode) behind one seam, so `vault_export` orchestrates the size
/// solver without ever holding a decoded bitmap (M10). The Dart reference
/// implementation lives in `vault_imaging`; the native one in Kotlin.
library;

import '../export/export_request.dart';
import '../failures/vault_failure.dart';
import '../imaging/image_op.dart' show FitMode;
import '../result.dart';
import 'blob_store.dart';

/// What the raster step must produce from one source image.
final class RasterPlan {
  const RasterPlan({
    this.width,
    this.height,
    this.fit = FitMode.contain,
    this.filter = ResampleFilter.lanczos,
    this.color = const ColorSpec(),
    this.maxDecodedPixels = 40 * 1024 * 1024,
  });

  /// Target size in pixels. Both `null` = keep the source size; one `null`
  /// = preserve the aspect ratio.
  final int? width;
  final int? height;
  final FitMode fit;
  final ResampleFilter filter;
  final ColorSpec color;

  /// Decode ceiling (R2): the engine decodes at the smallest sufficient
  /// scale and refuses sources that would exceed this even so.
  final int maxDecodedPixels;

  bool get resizes => width != null || height != null;

  RasterPlan copyWith({int? width, int? height}) => RasterPlan(
    width: width ?? this.width,
    height: height ?? this.height,
    fit: fit,
    filter: filter,
    color: color,
    maxDecodedPixels: maxDecodedPixels,
  );
}

/// Encoded output bytes plus the dimensions they encode.
final class EncodedRaster {
  const EncodedRaster({
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    required this.quality,
  });

  final List<int> bytes;
  final int width;
  final int height;
  final OutputFormat format;

  /// The quality the encoder was asked for (irrelevant for PNG).
  final int quality;
}

/// A decoded, rastered image held behind the boundary. Encode as many
/// times as the size solver needs, then [dispose].
abstract interface class PreparedRaster {
  int get width;

  int get height;

  /// Source pixel dimensions before the plan was applied, for the
  /// `upscaledBeyondSource` warning.
  int get sourceWidth;

  int get sourceHeight;

  /// Encode-to-count: the byte size the encoder would produce at [quality]
  /// without materialising an artifact (§11.4 "probe").
  Future<int> measure(OutputFormat format, int quality);

  /// Encode-to-bytes for the final artifact.
  Future<EncodedRaster> encode(OutputFormat format, int quality);

  /// A new raster at `size × factor` (both edges), for the size solver's
  /// downscale rounds. The receiver stays valid.
  Future<PreparedRaster> downscale(double factor);

  void dispose();
}

abstract interface class RasterEngine {
  /// Decodes [source] at the smallest sufficient scale for [plan] and
  /// applies resampling, fit and colour treatment.
  Future<Result<PreparedRaster, VaultFailure>> prepare(
    BlobHandle source, {
    required RasterPlan plan,
    CancellationToken? cancel,
  });
}
