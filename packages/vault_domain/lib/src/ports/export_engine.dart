/// `ExportEngine` port (§11). Implemented by `vault_export`.
library;

import '../export/export_request.dart';
import '../export/export_result.dart';
import '../failures/vault_failure.dart';
import '../result.dart';
import 'blob_store.dart';

abstract interface class ExportEngine {
  /// Runs the full pipeline (§11.3): validate → resolve → decode →
  /// raster → layout → encode → size-solve → seal. Runs entirely off the
  /// platform thread; cancellation is checked between stages.
  ///
  /// [retainArtifact] keeps the sealed output past the share (§11.7):
  /// the record pins its sources and the artifact expires by GC.
  Future<Result<ExportResult, VaultFailure>> run(
    ExportRequest request, {
    ProgressSink? progress,
    CancellationToken? cancel,
    bool retainArtifact = false,
  });
}
