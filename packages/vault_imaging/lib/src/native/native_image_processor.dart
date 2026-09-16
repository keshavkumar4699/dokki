/// `NativeImageProcessor`: the production `ImageProcessor` (§17 Phase 4).
///
/// Every call is one channel round trip: Kotlin decrypts the sealed source
/// into native memory, decodes at the smallest sufficient `inSampleSize`,
/// applies the ops, encodes, and seals the result to a `.part` file that
/// the blob store then commits. No decoded pixel and no full-resolution
/// plaintext ever enters the Dart heap (§8.4, R2).
library;

import 'dart:convert';

import 'package:platform_android/platform_android.dart';
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import 'sealed_files.dart';

final class NativeImageProcessor implements ImageProcessor {
  const NativeImageProcessor({
    required this.bridge,
    required this.files,
    this.maxDecodedPixels = 40 * 1024 * 1024,
    this.jpegQuality = 92,
  });

  final ImagingBridge bridge;
  final SealedBlobFiles files;

  /// Hard ceiling on decoded pixels after subsampling (R2, 40 MP).
  final int maxDecodedPixels;

  /// Quality for re-encoded JPEG output.
  final int jpegQuality;

  @override
  Future<Result<ImageInfo, VaultFailure>> inspect(BlobHandle source) =>
      guardImaging('inspect', () async {
        final input = await files.resolve(source);
        final info = await bridge.inspect(
          inputPath: input.path,
          purpose: input.purpose,
        );
        return ImageInfo(
          width: info.width,
          height: info.height,
          mime: info.mime,
        );
      });

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
    final ops = [for (final step in chain) ...step];
    if (ops.any((op) => !op.deterministic)) {
      // The op types exist so recipes can carry them (§5.3); the native
      // pipeline has no CV kernels until Phase 8.
      throw const ImagingException(ImageProcessingFailed('non-deterministic'));
    }
    cancel?.throwIfCancelled();
    final target =
        decode?.targetMaxPixels ?? DecodeSpec.fullResolution.targetMaxPixels;
    return _process(
      original,
      storageClass: StorageClass.asset,
      opsJson: jsonEncode([for (final op in ops) op.toJson()]),
      decodeTargetPixels: target,
      preferredMime: decode?.preferredMime,
      quality: jpegQuality,
      progress: progress,
      total: ops.length,
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
    // A preview needs no more than 4× its own pixels to resample well;
    // decoding a 48 MP photo for a 128 px thumbnail would be waste.
    final target = maxEdge * maxEdge * 4;
    return _process(
      source,
      storageClass: storageClass,
      opsJson: '[]',
      decodeTargetPixels: target,
      maxEdge: maxEdge,
      preferredMime: preferredMime,
      quality: quality,
    );
  });

  Future<ProcessedImage> _process(
    BlobHandle source, {
    required StorageClass storageClass,
    required String opsJson,
    required int decodeTargetPixels,
    required int quality,
    int maxEdge = 0,
    String? preferredMime,
    ProgressSink? progress,
    int total = 0,
    CancellationToken? cancel,
  }) async {
    final input = await files.resolve(source);
    final pending = await files.allocate(storageClass);
    ProcessedImageResult? result;
    try {
      result = await bridge.process(
        inputPath: input.path,
        purpose: input.purpose,
        outputPath: pending.partPath,
        outputPurpose: pending.purpose,
        keyEpoch: pending.keyEpoch,
        opsJson: opsJson,
        decodeTargetPixels: decodeTargetPixels,
        maxDecodedPixels: maxDecodedPixels,
        maxEdge: maxEdge,
        preferredMime: preferredMime,
        quality: quality,
      );
      // A cancellation that arrives after the native work finished still
      // wins: the caller asked for nothing to change.
      cancel?.throwIfCancelled();
    } finally {
      // Any exception (translated by the boundary) or a cancellation
      // leaves no half-written `.part` behind.
      if (result == null || (cancel?.isCancelled ?? false)) {
        await files.abandon(pending);
      }
    }
    progress?.call(total, total);
    final blob = await files.commit(
      pending,
      SealedFileInfo(
        keyEpoch: result.keyEpoch,
        wrappedDek: result.wrappedDek,
        plaintextSize: result.plaintextSize,
        ciphertextSize: result.ciphertextSize,
        plaintextSha256: result.plaintextSha256,
        ciphertextSha256: result.ciphertextSha256,
      ),
    );
    return ProcessedImage(
      blobRef: blob,
      meta: ImageMeta(
        width: result.width,
        height: result.height,
        mime: result.mime,
        plaintextSha256: result.plaintextSha256,
        byteSize: result.plaintextSize,
      ),
    );
  }
}
