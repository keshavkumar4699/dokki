/// `NativeRasterEngine`: the production `RasterEngine` for exports. The
/// bitmap lives in Kotlin under an opaque raster id; each size-solver
/// probe is an encode-to-count over the channel, and only the final
/// encoding (a bounded JPEG/PNG) crosses into Dart.
library;

import 'package:platform_android/platform_android.dart';
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import 'sealed_files.dart';

final class NativeRasterEngine implements RasterEngine {
  const NativeRasterEngine({required this.bridge, required this.files});

  final ImagingBridge bridge;
  final SealedBlobFiles files;

  @override
  Future<Result<PreparedRaster, VaultFailure>> prepare(
    BlobHandle source, {
    required RasterPlan plan,
    CancellationToken? cancel,
  }) => guardImaging('prepareRaster', () async {
    cancel?.throwIfCancelled();
    final input = await files.resolve(source);
    final handle = await bridge.prepareRaster(
      inputPath: input.path,
      purpose: input.purpose,
      width: plan.width,
      height: plan.height,
      fit: plan.fit.name,
      grayscale: plan.color.grayscale,
      bw: plan.color.bw,
      background: plan.color.backgroundColor,
      maxDecodedPixels: plan.maxDecodedPixels,
    );
    return NativePreparedRaster._(bridge, handle);
  });
}

final class NativePreparedRaster implements PreparedRaster {
  NativePreparedRaster._(this._bridge, this._handle);

  final ImagingBridge _bridge;
  final RasterHandleResult _handle;
  bool _disposed = false;

  @override
  int get width => _handle.width;

  @override
  int get height => _handle.height;

  @override
  int get sourceWidth => _handle.sourceWidth;

  @override
  int get sourceHeight => _handle.sourceHeight;

  @override
  Future<int> measure(OutputFormat format, int quality) =>
      _bridge.measureRaster(
        rasterId: _handle.rasterId,
        mime: _mimeOf(format),
        quality: quality,
      );

  @override
  Future<EncodedRaster> encode(OutputFormat format, int quality) async {
    final encoded = await _bridge.encodeRaster(
      rasterId: _handle.rasterId,
      mime: _mimeOf(format),
      quality: quality,
    );
    return EncodedRaster(
      bytes: encoded.bytes,
      width: encoded.width,
      height: encoded.height,
      format: format,
      quality: quality,
    );
  }

  @override
  Future<PreparedRaster> downscale(double factor) async =>
      NativePreparedRaster._(
        _bridge,
        await _bridge.downscaleRaster(
          rasterId: _handle.rasterId,
          factor: factor,
        ),
      );

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    // Fire and forget: the Kotlin side recycles the bitmap; nothing
    // depends on when.
    _bridge.disposeRaster(_handle.rasterId).ignore();
  }

  static String _mimeOf(OutputFormat format) => switch (format) {
    OutputFormat.png => 'image/png',
    OutputFormat.jpeg => 'image/jpeg',
    OutputFormat.webp => throw const ImagingException(
      UnsupportedFormat('image/webp'),
    ),
    OutputFormat.pdf => throw const ImagingException(
      UnsupportedFormat('application/pdf'),
    ),
  };
}
