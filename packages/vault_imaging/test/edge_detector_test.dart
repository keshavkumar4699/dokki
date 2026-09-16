/// `EdgeDetectorImpl` over a fake bridge: path resolution, protocol shape,
/// quad mapping, and the honest null on "no confident quad".
library;

import 'package:platform_android/platform_android.dart';
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

final class _Files implements SealedBlobFiles {
  @override
  Future<SealedInput> resolve(BlobHandle handle) async =>
      SealedInput(path: '/vault/blobs/${handle.token}', purpose: 1);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class _Bridge implements ImagingBridge {
  DetectedQuad? quad;
  String? lastPath;
  int? lastPurpose;

  @override
  Future<DetectedQuad?> detectDocument({
    required String inputPath,
    required int purpose,
  }) async {
    lastPath = inputPath;
    lastPurpose = purpose;
    return quad;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _Bridge bridge;
  late EdgeDetectorImpl detector;

  setUp(() {
    bridge = _Bridge();
    detector = EdgeDetectorImpl(bridge: bridge, files: _Files());
  });

  test('a detected quad maps to normalised corners clockwise from TL', () async {
    bridge.quad = const DetectedQuad(
      x0: 0.10,
      y0: 0.20,
      x1: 0.90,
      y1: 0.15,
      x2: 0.85,
      y2: 0.80,
      x3: 0.05,
      y3: 0.75,
    );
    final quad = (await detector.detect(const _Handle('b1'))).okOrNull!;
    expect(bridge.lastPath, '/vault/blobs/b1');
    expect(bridge.lastPurpose, 1);
    expect(quad.topLeft, const PointN(0.10, 0.20));
    expect(quad.topRight, const PointN(0.90, 0.15));
    expect(quad.bottomRight, const PointN(0.85, 0.80));
    expect(quad.bottomLeft, const PointN(0.05, 0.75));
  });

  test('no quad found is Ok(null), never an error', () async {
    bridge.quad = null;
    final result = await detector.detect(const _Handle('b1'));
    expect(result.isOk, isTrue);
    expect(result.okOrNull, isNull);
  });
}
