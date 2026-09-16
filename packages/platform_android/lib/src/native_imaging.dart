/// Image pipeline channel: `dokki/vault_imaging`.
///
/// Plaintext stays in Kotlin `DirectByteBuffer`s, which are zeroed after
/// use (§8.4). Dart receives paths of sealed blobs and sealed outputs —
/// never full-resolution plaintext.
///
/// Protocol:
///   process {inputPath, outputPath, opsJson, decodeTargetPixels,
///            preferredMime, quality, epoch, purpose}
///     → { width, height, mime, plaintextSha256, byteSize, outBytes }
///   inspect {inputPath} → { width, height, mime }
library;

import 'package:flutter/services.dart';

import 'error_boundary.dart';

final class NativeImagingBridge {
  const NativeImagingBridge._();

  static const MethodChannel _channel = MethodChannel('dokki/vault_imaging');

  /// Reads the sealed blob at [inputPath], decrypts (streaming AEAD),
  /// decodes at ≤ [decodeTargetPixels], applies [opsJson], encodes as
  /// [preferredMime] at [quality], seals to [outputPath].
  Future<ProcessedImageResult> process({
    required String inputPath,
    required String outputPath,
    required String opsJson,
    required int decodeTargetPixels,
    required String preferredMime,
    required int quality,
    required int keyEpoch,
    required int purpose,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('process', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'opsJson': opsJson,
        'decodeTargetPixels': decodeTargetPixels,
        'preferredMime': preferredMime,
        'quality': quality,
        'epoch': keyEpoch,
        'purpose': purpose,
      }),
    );
    return ProcessedImageResult.fromJson(result!);
  }

  Future<InspectResult> inspect(String inputPath) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('inspect', {
        'inputPath': inputPath,
      }),
    );
    return InspectResult.fromJson(result!);
  }
}

final class ProcessedImageResult {
  const ProcessedImageResult({
    required this.width,
    required this.height,
    required this.mime,
    required this.plaintextSha256,
    required this.byteSize,
    required this.outBytes,
  });

  factory ProcessedImageResult.fromJson(Map<String, Object?> json) =>
      ProcessedImageResult(
        width: (json['width'] as num).toInt(),
        height: (json['height'] as num).toInt(),
        mime: json['mime']! as String,
        plaintextSha256: json['plaintextSha256']! as String,
        byteSize: (json['byteSize'] as num).toInt(),
        outBytes: (json['outBytes'] as num).toInt(),
      );

  final int width;
  final int height;
  final String mime;
  final String plaintextSha256;
  final int byteSize;

  /// Sealed (ciphertext) size of the output file.
  final int outBytes;
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
