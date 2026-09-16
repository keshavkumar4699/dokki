/// `EdgeDetector` port (§5.3).
///
/// Detection is separate from application: the `Quad` it returns becomes a
/// `PerspectiveOp`. Replacing OpenCV with a better model later changes
/// detection quality, not a single stored recipe.
library;

import '../failures/vault_failure.dart';
import '../imaging/geometry.dart';
import '../result.dart';
import 'blob_store.dart';

abstract interface class EdgeDetector {
  /// Finds the document quad in [source]. Returns `null` (via
  /// `Ok(null)`) when no confident edge is found — the caller falls back
  /// to manual corners.
  Future<Result<Quad?, VaultFailure>> detect(
    BlobHandle source, {
    ProgressSink? progress,
  });
}
