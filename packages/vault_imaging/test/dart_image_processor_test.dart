/// `DartImageProcessor` over an in-memory store: op semantics, normalised
/// coordinates, determinism, and refusal of Phase-8 ops.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_imaging/vault_imaging.dart';

final class _Handle implements BlobHandle {
  const _Handle(this.token);

  @override
  final String token;

  @override
  int? get plaintextSize => null;
}

final class _MemoryStore implements BlobStore, BlobPlaintextSource {
  final Map<String, Uint8List> blobs = {};
  int _n = 0;

  String put(List<int> bytes) {
    final id = 'blob${++_n}';
    blobs[id] = Uint8List.fromList(bytes);
    return id;
  }

  @override
  Stream<List<int>> openPlaintext(BlobHandle handle) =>
      Stream.value(blobs[handle.token]!);

  @override
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id) async =>
      Ok(_Handle(id));

  @override
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final bytes = <int>[];
    await source.forEach(bytes.addAll);
    final id = put(bytes);
    return Ok(
      BlobRef(
        id: id,
        storageClass: storageClass,
        relPath: 'x/$id',
        keyEpoch: 1,
        wrappedDek: const [],
        plaintextSize: bytes.length,
        ciphertextSize: bytes.length,
        ciphertextSha256: '',
        plaintextSha256: _fnv(bytes),
      ),
    );
  }

  static String _fnv(List<int> bytes) {
    var h = 0x811c9dc5;
    for (final b in bytes) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  @override
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  }) async => Ok(blobs[id]!);

  @override
  Future<Result<void, VaultFailure>> verify(BlobId id) async => const Ok(null);

  @override
  Future<Result<void, VaultFailure>> evict(BlobId id) async => const Ok(null);

  @override
  Future<Result<void, VaultFailure>> purge(BlobId id) async {
    blobs.remove(id);
    return const Ok(null);
  }

  @override
  Future<Result<bool, VaultFailure>> exists(BlobId id) async =>
      Ok(blobs.containsKey(id));
}

/// A w×h PNG whose top-left quadrant is red and the rest blue, so crops
/// and rotations are visible in pixel assertions.
Uint8List _testImage(int w, int h) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final red = x < w ~/ 2 && y < h ~/ 2;
      image.setPixelRgb(x, y, red ? 255 : 0, 0, red ? 0 : 255);
    }
  }
  return img.encodePng(image);
}

img.Image _decode(_MemoryStore store, BlobRef ref) =>
    img.decodeImage(store.blobs[ref.id]!)!;

void main() {
  late _MemoryStore store;
  late DartImageProcessor processor;

  setUp(() {
    store = _MemoryStore();
    processor = DartImageProcessor(source: store, blobStore: store);
  });

  test('inspect reports dimensions and mime without full decode', () async {
    final id = store.put(_testImage(640, 480));
    final info = (await processor.inspect(_Handle(id))).okOrNull!;
    expect(info.width, 640);
    expect(info.height, 480);
    expect(info.mime, 'image/png');
  });

  test('inspect of non-image bytes is UnsupportedFormat', () async {
    final id = store.put([1, 2, 3, 4, 5]);
    expect(
      (await processor.inspect(_Handle(id))).errOrNull,
      isA<UnsupportedFormat>(),
    );
  });

  test('rotate 90° swaps dimensions and moves the red quadrant', () async {
    final id = store.put(_testImage(400, 200));
    final out = (await processor.apply(
      _Handle(id),
      ops: const [RotateOp(1)],
    )).okOrNull!;
    expect(out.meta.width, 200);
    expect(out.meta.height, 400);
    expect(out.meta.mime, 'image/png');
    final image = _decode(store, out.blobRef);
    // Top-left quadrant rotated clockwise lands top-right.
    expect(image.getPixel(190, 10).r, 255);
    expect(image.getPixel(10, 10).b, 255);
  });

  test('crop uses normalised coordinates (same recipe, two scales)', () async {
    const recipe = [CropOp(RectN(0, 0, 0.5, 0.5))];
    final big = store.put(_testImage(800, 800));
    final small = store.put(_testImage(80, 80));
    final bigOut = (await processor.apply(_Handle(big), ops: recipe)).okOrNull!;
    final smallOut = (await processor.apply(
      _Handle(small),
      ops: recipe,
    )).okOrNull!;
    expect((bigOut.meta.width, bigOut.meta.height), (400, 400));
    expect((smallOut.meta.width, smallOut.meta.height), (40, 40));
    // Both crops contain only the red quadrant.
    for (final out in [bigOut, smallOut]) {
      final image = _decode(store, out.blobRef);
      expect(image.getPixel(image.width - 1, image.height - 1).r, 255);
    }
  });

  test('applyChain is deterministic: same ops, same bytes', () async {
    final id = store.put(_testImage(300, 200));
    const chain = [
      [RotateOp(1)],
      [CropOp(RectN(0.1, 0.1, 0.9, 0.9))],
      [BrightnessOp(0.1)],
    ];
    final a = (await processor.applyChain(_Handle(id), chain: chain)).okOrNull!;
    final b = (await processor.applyChain(_Handle(id), chain: chain)).okOrNull!;
    expect(a.meta.plaintextSha256, b.meta.plaintextSha256);
    expect(store.blobs[a.blobRef.id], store.blobs[b.blobRef.id]);
  });

  test('preview fits the longest edge and re-encodes as JPEG', () async {
    final id = store.put(_testImage(2000, 1000));
    final out = (await processor.preview(_Handle(id), maxEdge: 384)).okOrNull!;
    expect(out.meta.width, 384);
    expect(out.meta.height, 192);
    expect(out.meta.mime, 'image/jpeg');
    expect(out.blobRef.storageClass, StorageClass.thumbnail);
    expect(store.blobs[out.blobRef.id]!.sublist(0, 2), [0xFF, 0xD8]);
  });

  test('preview never upscales', () async {
    final id = store.put(_testImage(100, 50));
    final out = (await processor.preview(_Handle(id))).okOrNull!;
    expect((out.meta.width, out.meta.height), (100, 50));
  });

  test('resize honours fit modes', () async {
    final id = store.put(_testImage(400, 200));
    Future<(int, int)> dims(FitMode fit) async {
      final out = (await processor.apply(
        _Handle(id),
        ops: [ResizeOp(width: 100, height: 100, fit: fit)],
      )).okOrNull!;
      return (out.meta.width, out.meta.height);
    }

    expect(await dims(FitMode.stretch), (100, 100));
    expect(await dims(FitMode.contain), (100, 50));
    expect(await dims(FitMode.pad), (100, 100));
    expect(await dims(FitMode.cover), (100, 100));
  });

  test('Phase-8 ops are refused, not silently skipped', () async {
    final id = store.put(_testImage(10, 10));
    final failure = (await processor.apply(
      _Handle(id),
      ops: const [PerspectiveOp(Quad.fullFrame)],
    )).errOrNull;
    expect(failure, isA<ImageProcessingFailed>());
  });

  test('oversized decodes are refused up front (R2)', () async {
    final tiny = DartImageProcessor(
      source: store,
      blobStore: store,
      maxDecodedPixels: 1000,
    );
    final id = store.put(_testImage(100, 100));
    final failure = (await tiny.apply(
      _Handle(id),
      ops: const [RotateOp(1)],
    )).errOrNull;
    expect(failure, isA<ImageProcessingFailed>());
  });

  test('cancellation between ops is OperationCancelled', () async {
    final id = store.put(_testImage(50, 50));
    final token = CancellationToken();
    var calls = 0;
    final result = await processor.apply(
      _Handle(id),
      ops: const [RotateOp(1), RotateOp(1), RotateOp(1)],
      progress: (done, total) {
        if (++calls == 1) {
          token.cancel();
        }
      },
      cancel: token,
    );
    expect(result.errOrNull, isA<OperationCancelled>());
  });
}
