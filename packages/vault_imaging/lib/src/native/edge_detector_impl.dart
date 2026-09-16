/// `EdgeDetectorImpl` (§5.3, Phase 8): the `EdgeDetector` port over the
/// Kotlin detector. Detection is separate from application — the returned
/// `Quad` becomes a `PerspectiveOp`, so upgrading the detector later
/// never invalidates a stored recipe.
library;

import 'package:platform_android/platform_android.dart';
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import 'sealed_files.dart';

final class EdgeDetectorImpl implements EdgeDetector {
  const EdgeDetectorImpl({required this.bridge, required this.files});

  final ImagingBridge bridge;
  final SealedBlobFiles files;

  @override
  Future<Result<Quad?, VaultFailure>> detect(
    BlobHandle source, {
    ProgressSink? progress,
  }) => guardImaging('detect', () async {
    final input = await files.resolve(source);
    final quad = await bridge.detectDocument(
      inputPath: input.path,
      purpose: input.purpose,
    );
    progress?.call(1, 1);
    if (quad == null) {
      return null;
    }
    return Quad(
      PointN(quad.x0, quad.y0),
      PointN(quad.x1, quad.y1),
      PointN(quad.x2, quad.y2),
      PointN(quad.x3, quad.y3),
    );
  });
}
