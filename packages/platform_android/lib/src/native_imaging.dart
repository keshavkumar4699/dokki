/// Image pipeline channel: `dokki/vault_imaging` (§17 Phase 4).
///
/// Bitmaps and full-resolution plaintext stay in Kotlin (§8.4). Dart
/// hands over paths of sealed files and gets back sealed outputs plus
/// metadata; the only pixels that cross are export encodings, which are
/// bounded (a JPEG/PNG, never a decoded bitmap).
///
/// Protocol (all byte arrays base64 unless noted):
///   ping → true
///   inspect {inputPath, purpose} → {width, height, mime}
///   process {inputPath, purpose, outputPath, outputPurpose, epoch, opsJson,
///            decodeTargetPixels, maxDecodedPixels, maxEdge, preferredMime,
///            quality}
///     → {width, height, mime, keyEpoch, wrappedDek, plaintextSize,
///        ciphertextSize, plaintextSha256, ciphertextSha256}
///   prepareRaster {inputPath, purpose, width?, height?, fit, grayscale,
///                  bw, background?, maxDecodedPixels}
///     → {rasterId, width, height, sourceWidth, sourceHeight}
///   measureRaster {rasterId, format, quality} → int
///   encodeRaster {rasterId, format, quality} → {bytes (binary), width, height}
///   downscaleRaster {rasterId, factor} → (as prepareRaster)
///   disposeRaster {rasterId}
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'error_boundary.dart';

/// The imaging bridge as `vault_imaging` sees it, so a fake can stand in
/// for Kotlin in tests.
abstract interface class ImagingBridge {
  Future<bool> isAvailable();

  Future<InspectResult> inspect({
    required String inputPath,
    required int purpose,
  });

  Future<ProcessedImageResult> process({
    required String inputPath,
    required int purpose,
    required String outputPath,
    required int outputPurpose,
    required int keyEpoch,
    required String opsJson,
    required int decodeTargetPixels,
    required int maxDecodedPixels,
    int maxEdge = 0,
    String? preferredMime,
    int quality = 92,
  });

  Future<RasterHandleResult> prepareRaster({
    required String inputPath,
    required int purpose,
    int? width,
    int? height,
    String fit = 'contain',
    bool grayscale = false,
    bool bw = false,
    int? background,
    required int maxDecodedPixels,
  });

  Future<int> measureRaster({
    required int rasterId,
    required String mime,
    required int quality,
  });

  Future<EncodedRasterResult> encodeRaster({
    required int rasterId,
    required String mime,
    required int quality,
  });

  Future<RasterHandleResult> downscaleRaster({
    required int rasterId,
    required double factor,
  });

  Future<void> disposeRaster(int rasterId);
}

final class NativeImagingBridge implements ImagingBridge {
  const NativeImagingBridge();

  static const MethodChannel _channel = MethodChannel('dokki/vault_imaging');

  /// `true` when the Kotlin side answers; `false` on a host without the
  /// plugin (tests, desktop), where the Dart reference pipeline is used.
  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('ping') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<InspectResult> inspect({
    required String inputPath,
    required int purpose,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('inspect', {
        'inputPath': inputPath,
        'purpose': purpose,
      }),
    );
    return InspectResult.fromJson(result!);
  }

  @override
  Future<ProcessedImageResult> process({
    required String inputPath,
    required int purpose,
    required String outputPath,
    required int outputPurpose,
    required int keyEpoch,
    required String opsJson,
    required int decodeTargetPixels,
    required int maxDecodedPixels,
    int maxEdge = 0,
    String? preferredMime,
    int quality = 92,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('process', {
        'inputPath': inputPath,
        'purpose': purpose,
        'outputPath': outputPath,
        'outputPurpose': outputPurpose,
        'epoch': keyEpoch,
        'opsJson': opsJson,
        'decodeTargetPixels': decodeTargetPixels,
        'maxDecodedPixels': maxDecodedPixels,
        'maxEdge': maxEdge,
        'preferredMime': preferredMime,
        'quality': quality,
      }),
    );
    return ProcessedImageResult.fromJson(result!);
  }

  @override
  Future<RasterHandleResult> prepareRaster({
    required String inputPath,
    required int purpose,
    int? width,
    int? height,
    String fit = 'contain',
    bool grayscale = false,
    bool bw = false,
    int? background,
    required int maxDecodedPixels,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('prepareRaster', {
        'inputPath': inputPath,
        'purpose': purpose,
        'width': width,
        'height': height,
        'fit': fit,
        'grayscale': grayscale,
        'bw': bw,
        'background': background,
        'maxDecodedPixels': maxDecodedPixels,
      }),
    );
    return RasterHandleResult.fromJson(result!);
  }

  @override
  Future<int> measureRaster({
    required int rasterId,
    required String mime,
    required int quality,
  }) async {
    final bytes = await guardChannel(
      () => _channel.invokeMethod<int>('measureRaster', {
        'rasterId': rasterId,
        'format': mime,
        'quality': quality,
      }),
    );
    return bytes!;
  }

  @override
  Future<EncodedRasterResult> encodeRaster({
    required int rasterId,
    required String mime,
    required int quality,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('encodeRaster', {
        'rasterId': rasterId,
        'format': mime,
        'quality': quality,
      }),
    );
    return EncodedRasterResult(
      bytes: result!['bytes']! as Uint8List,
      width: (result['width'] as num).toInt(),
      height: (result['height'] as num).toInt(),
    );
  }

  @override
  Future<RasterHandleResult> downscaleRaster({
    required int rasterId,
    required double factor,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('downscaleRaster', {
        'rasterId': rasterId,
        'factor': factor,
      }),
    );
    return RasterHandleResult.fromJson(result!);
  }

  @override
  Future<void> disposeRaster(int rasterId) => guardChannel(
    () => _channel.invokeMethod<void>('disposeRaster', {'rasterId': rasterId}),
  );
}

final class InspectResult {
  const InspectResult({
    required this.width,
    required this.height,
    required this.mime,
  });

  factory InspectResult.fromJson(Map<String, Object?> json) => InspectResult(
    width: (json['width'] as num).toInt(),
    height: (json['height'] as num).toInt(),
    mime: json['mime']! as String,
  );

  final int width;
  final int height;
  final String mime;
}

/// A sealed output written by Kotlin: everything the `blobs` row needs.
final class ProcessedImageResult {
  const ProcessedImageResult({
    required this.width,
    required this.height,
    required this.mime,
    required this.keyEpoch,
    required this.wrappedDek,
    required this.plaintextSize,
    required this.ciphertextSize,
    required this.plaintextSha256,
    required this.ciphertextSha256,
  });

  factory ProcessedImageResult.fromJson(Map<String, Object?> json) =>
      ProcessedImageResult(
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
        mime: json['mime']! as String,
        keyEpoch: (json['keyEpoch'] as num).toInt(),
        wrappedDek: base64Decode(json['wrappedDek']! as String),
        plaintextSize: (json['plaintextSize'] as num).toInt(),
        ciphertextSize: (json['ciphertextSize'] as num).toInt(),
        plaintextSha256: json['plaintextSha256']! as String,
        ciphertextSha256: json['ciphertextSha256']! as String,
      );

  final int width;
  final int height;
  final String mime;
  final int keyEpoch;
  final Uint8List wrappedDek;
  final int plaintextSize;
  final int ciphertextSize;
  final String plaintextSha256;
  final String ciphertextSha256;
}

final class RasterHandleResult {
  const RasterHandleResult({
    required this.rasterId,
    required this.width,
    required this.height,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  factory RasterHandleResult.fromJson(Map<String, Object?> json) =>
      RasterHandleResult(
        rasterId: (json['rasterId'] as num).toInt(),
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
        sourceWidth: (json['sourceWidth'] as num).toInt(),
        sourceHeight: (json['sourceHeight'] as num).toInt(),
      );

  final int rasterId;
  final int width;
  final int height;
  final int sourceWidth;
  final int sourceHeight;
}

final class EncodedRasterResult {
  const EncodedRasterResult({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}
