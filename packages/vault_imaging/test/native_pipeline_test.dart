/// `NativeImageProcessor` / `NativeRasterEngine` over a fake bridge: the
/// channel protocol, the commit/abandon discipline around the `.part`
/// file, cancellation, and failure translation. Pixels are Kotlin's job
/// and are exercised on a device; this pins down everything around them.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:platform_android/platform_android.dart';
import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_imaging/vault_imaging.dart';

final class _Handle implements BlobHandle {
  const _Handle(this.token);

  @override
  final String token;

  @override
  int? get plaintextSize => 100;
}

final class FakeFiles implements SealedBlobFiles {
  final List<PendingSealedBlob> allocated = [];
  final List<PendingSealedBlob> committed = [];
  final List<PendingSealedBlob> abandoned = [];
  int _n = 0;

  @override
  Future<SealedInput> resolve(BlobHandle handle) async =>
      SealedInput(path: '/vault/blobs/${handle.token}', purpose: 1);

  @override
  Future<PendingSealedBlob> allocate(StorageClass storageClass) async {
    final id = 'out-${++_n}';
    final pending = PendingSealedBlob(
      id: id,
      storageClass: storageClass,
      relPath: '${BlobPathsLike.dirFor(storageClass)}/ou/$id',
      partPath: '/vault/${BlobPathsLike.dirFor(storageClass)}/ou/$id.part',
      purpose: BlobPathsLike.purposeFor(storageClass),
      keyEpoch: 3,
    );
    allocated.add(pending);
    return pending;
  }

  @override
  Future<BlobRef> commit(PendingSealedBlob pending, SealedFileInfo info) async {
    committed.add(pending);
    return BlobRef(
      id: pending.id,
      storageClass: pending.storageClass,
      relPath: pending.relPath,
      keyEpoch: info.keyEpoch,
      wrappedDek: info.wrappedDek,
      plaintextSize: info.plaintextSize,
      ciphertextSize: info.ciphertextSize,
      ciphertextSha256: info.ciphertextSha256,
      plaintextSha256: info.plaintextSha256,
    );
  }

  @override
  Future<void> abandon(PendingSealedBlob pending) async =>
      abandoned.add(pending);
}

/// Mirrors the storage layout without depending on `vault_storage`.
abstract final class BlobPathsLike {
  static String dirFor(StorageClass c) => switch (c) {
    StorageClass.asset => 'blobs',
    StorageClass.thumbnail => 'thumbs',
    StorageClass.exportArtifact => 'exports',
    StorageClass.syncLog => 'logs',
  };

  static int purposeFor(StorageClass c) => switch (c) {
    StorageClass.asset => EnvelopePurpose.asset.byte,
    StorageClass.thumbnail => EnvelopePurpose.thumbnail.byte,
    StorageClass.exportArtifact => EnvelopePurpose.exportArtifact.byte,
    StorageClass.syncLog => EnvelopePurpose.logSegment.byte,
  };
}

final class FakeBridge implements ImagingBridge {
  final List<Map<String, Object?>> calls = [];
  NativeFailure? failure;
  int width = 4000;
  int height = 3000;
  final Set<int> live = {};
  int _nextRaster = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<DetectedQuad?> detectDocument({
    required String inputPath,
    required int purpose,
  }) async {
    calls.add({'m': 'detectDocument', 'inputPath': inputPath});
    _maybeFail();
    return null; // "no confident quad" by default in tests
  }

  @override
  Future<InspectResult> inspect({
    required String inputPath,
    required int purpose,
  }) async {
    calls.add({'m': 'inspect', 'inputPath': inputPath, 'purpose': purpose});
    _maybeFail();
    return InspectResult(width: width, height: height, mime: 'image/jpeg');
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
    calls.add({
      'm': 'process',
      'inputPath': inputPath,
      'purpose': purpose,
      'outputPath': outputPath,
      'outputPurpose': outputPurpose,
      'keyEpoch': keyEpoch,
      'opsJson': opsJson,
      'decodeTargetPixels': decodeTargetPixels,
      'maxDecodedPixels': maxDecodedPixels,
      'maxEdge': maxEdge,
      'preferredMime': preferredMime,
      'quality': quality,
    });
    _maybeFail();
    return ProcessedImageResult(
      width: 300,
      height: 400,
      mime: preferredMime ?? 'image/jpeg',
      keyEpoch: keyEpoch,
      wrappedDek: Uint8List.fromList(List.filled(60, 7)),
      plaintextSize: 1234,
      ciphertextSize: 1234 + 100,
      plaintextSha256: 'cd' * 32,
      ciphertextSha256: 'ab' * 32,
    );
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
    calls.add({
      'm': 'prepareRaster',
      'width': width,
      'height': height,
      'fit': fit,
      'grayscale': grayscale,
      'bw': bw,
      'background': background,
      'maxDecodedPixels': maxDecodedPixels,
    });
    _maybeFail();
    final id = ++_nextRaster;
    live.add(id);
    return RasterHandleResult(
      rasterId: id,
      width: width ?? this.width,
      height: height ?? this.height,
      sourceWidth: this.width,
      sourceHeight: this.height,
    );
  }

  @override
  Future<int> measureRaster({
    required int rasterId,
    required String mime,
    required int quality,
  }) async {
    calls.add({'m': 'measure', 'id': rasterId, 'mime': mime, 'q': quality});
    return quality * 100;
  }

  @override
  Future<EncodedRasterResult> encodeRaster({
    required int rasterId,
    required String mime,
    required int quality,
  }) async {
    calls.add({'m': 'encode', 'id': rasterId, 'mime': mime, 'q': quality});
    return EncodedRasterResult(
      bytes: Uint8List.fromList(List.filled(quality, 1)),
      width: 10,
      height: 20,
    );
  }

  @override
  Future<RasterHandleResult> downscaleRaster({
    required int rasterId,
    required double factor,
  }) async {
    calls.add({'m': 'downscale', 'id': rasterId, 'factor': factor});
    final id = ++_nextRaster;
    live.add(id);
    return RasterHandleResult(
      rasterId: id,
      width: (width * factor).round(),
      height: (height * factor).round(),
      sourceWidth: width,
      sourceHeight: height,
    );
  }

  @override
  Future<void> disposeRaster(int rasterId) async {
    calls.add({'m': 'dispose', 'id': rasterId});
    live.remove(rasterId);
  }

  void _maybeFail() {
    final f = failure;
    if (f != null) {
      failure = null;
      throw f;
    }
  }
}

void main() {
  late FakeBridge bridge;
  late FakeFiles files;
  late NativeImageProcessor processor;

  setUp(() {
    bridge = FakeBridge();
    files = FakeFiles();
    processor = NativeImageProcessor(bridge: bridge, files: files);
  });

  group('NativeImageProcessor', () {
    test('inspect resolves the sealed path and purpose', () async {
      final info = (await processor.inspect(const _Handle('b1'))).okOrNull!;
      expect(info.width, 4000);
      expect(bridge.calls.single['inputPath'], '/vault/blobs/b1');
      expect(bridge.calls.single['purpose'], 1);
    });

    test('apply flattens the chain, seals to a .part and commits it', () async {
      final result = await processor.applyChain(
        const _Handle('b1'),
        chain: const [
          [RotateOp(1)],
          [CropOp(RectN(0, 0, 0.5, 0.5)), FilterOp('grayscale')],
        ],
      );
      final image = result.okOrNull!;
      final call = bridge.calls.single;
      expect(jsonDecode(call['opsJson']! as String), [
        {'op': 'rotate', 'quarterTurns': 1},
        {
          'op': 'crop',
          'rect': {'left': 0, 'top': 0, 'right': 0.5, 'bottom': 0.5},
        },
        {'op': 'filter', 'id': 'grayscale'},
      ]);
      expect(call['outputPath'], endsWith('.part'));
      expect(call['outputPurpose'], EnvelopePurpose.asset.byte);
      expect(call['keyEpoch'], 3);
      expect(
        call['decodeTargetPixels'],
        DecodeSpec.fullResolution.targetMaxPixels,
      );
      expect(call['maxDecodedPixels'], 40 * 1024 * 1024);
      expect(call['quality'], 92);
      expect(files.committed.single.id, 'out-1');
      expect(files.abandoned, isEmpty);
      expect(image.blobRef.id, 'out-1');
      expect(image.blobRef.storageClass, StorageClass.asset);
      expect(image.blobRef.keyEpoch, 3);
      expect(image.blobRef.plaintextSha256, 'cd' * 32);
      expect(image.meta.width, 300);
      expect(image.meta.height, 400);
      expect(image.meta.byteSize, 1234);
    });

    test(
      'preview asks for a bounded decode, the edge cap and the class',
      () async {
        final result = await processor.preview(
          const _Handle('b1'),
          maxEdge: 384,
          quality: 80,
        );
        expect(result.isOk, isTrue);
        final call = bridge.calls.single;
        expect(call['opsJson'], '[]');
        expect(call['maxEdge'], 384);
        expect(call['decodeTargetPixels'], 384 * 384 * 4);
        expect(call['quality'], 80);
        expect(call['preferredMime'], 'image/jpeg');
        expect(call['outputPurpose'], EnvelopePurpose.thumbnail.byte);
        expect(files.committed.single.storageClass, StorageClass.thumbnail);
      },
    );

    test('a native failure abandons the .part and is translated', () async {
      bridge.failure = const NativeTagVerificationFailed();
      final result = await processor.apply(
        const _Handle('b1'),
        ops: const [RotateOp(1)],
      );
      final failure = result.errOrNull;
      expect(failure, isA<DecryptionFailed>());
      expect((failure! as DecryptionFailed).tamperSuspected, isTrue);
      expect(files.abandoned.single.id, 'out-1');
      expect(files.committed, isEmpty);
    });

    test(
      'every native code lands on the same failure the Dart path raises',
      () async {
        final expectations = <NativeFailure, Type>{
          const NativeEnvelopeFormat(): DecryptionFailed,
          const NativeUnsupportedFormat(): UnsupportedFormat,
          const NativeDecodeTooLarge(): ImageProcessingFailed,
          const NativeUnsupportedOp(): ImageProcessingFailed,
          const NativeOutOfMemory(): ImageProcessingFailed,
          const NativeStorageIo(): StorageIoFailure,
          const NativeLocked(): KeyUnavailable,
          const NativeGenericFailure('NATIVE_X'): ImageProcessingFailed,
        };
        for (final entry in expectations.entries) {
          bridge.failure = entry.key;
          final result = await processor.inspect(const _Handle('b1'));
          expect(
            result.errOrNull.runtimeType,
            entry.value,
            reason: entry.key.code,
          );
        }
      },
    );

    test('a cancellation after native work abandons the output', () async {
      final token = CancellationToken()..cancel();
      final result = await processor.apply(
        const _Handle('b1'),
        ops: const [RotateOp(1)],
        cancel: token,
      );
      expect(result.errOrNull, isA<OperationCancelled>());
      expect(bridge.calls, isEmpty, reason: 'cancelled before the call');
      expect(files.abandoned, isEmpty);
      expect(files.committed, isEmpty);
    });

    test('non-deterministic ops are refused before any native work', () async {
      final result = await processor.apply(
        const _Handle('b1'),
        ops: const [BackgroundOp(BackgroundSpec(color: 0xFFFFFFFF))],
      );
      expect(result.errOrNull, isA<ImageProcessingFailed>());
      expect(bridge.calls, isEmpty);
      expect(files.allocated, isEmpty);
    });
  });

  group('NativeRasterEngine', () {
    late NativeRasterEngine engine;

    setUp(() => engine = NativeRasterEngine(bridge: bridge, files: files));

    test(
      'prepare forwards the plan; measure/encode map formats to mimes',
      () async {
        const plan = RasterPlan(
          width: 800,
          fit: FitMode.cover,
          color: ColorSpec(grayscale: true, backgroundColor: 0xFF102030),
        );
        final raster = (await engine.prepare(
          const _Handle('b1'),
          plan: plan,
        )).okOrNull!;
        expect(bridge.calls.single['fit'], 'cover');
        expect(bridge.calls.single['grayscale'], isTrue);
        expect(bridge.calls.single['background'], 0xFF102030);
        expect(raster.width, 800);
        expect(raster.sourceWidth, 4000);

        expect(await raster.measure(OutputFormat.jpeg, 70), 7000);
        expect(bridge.calls.last['mime'], 'image/jpeg');
        final encoded = await raster.encode(OutputFormat.png, 100);
        expect(bridge.calls.last['mime'], 'image/png');
        expect(encoded.bytes, hasLength(100));
        expect(encoded.format, OutputFormat.png);

        final smaller = await raster.downscale(0.5);
        expect(smaller.width, 2000);
        expect(bridge.live, hasLength(2));
        raster.dispose();
        smaller.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(bridge.live, isEmpty);
        raster.dispose(); // idempotent
        expect(bridge.calls.where((c) => c['m'] == 'dispose'), hasLength(2));
      },
    );

    test('pdf and webp are refused at the seam', () async {
      final raster = (await engine.prepare(
        const _Handle('b1'),
        plan: const RasterPlan(),
      )).okOrNull!;
      expect(
        () => raster.measure(OutputFormat.webp, 80),
        throwsA(isA<ImagingException>()),
      );
    });

    test('a native failure surfaces as a translated Err', () async {
      bridge.failure = const NativeOutOfMemory();
      final result = await engine.prepare(
        const _Handle('b1'),
        plan: const RasterPlan(width: 100000),
      );
      expect(result.errOrNull, isA<ImageProcessingFailed>());
    });
  });
}
