/// `ExportResult` and warnings (§11.2).
///
/// Warnings do real work: "we produced 210 KB when you asked for 200 KB" is
/// a warning, not a failure, and the UI must say so honestly.
library;

import '../ids.dart';
import 'export_request.dart';

/// `export_records.status` (§6.3).
enum ExportStatus {
  success('SUCCESS'),
  failed('FAILED'),
  cancelled('CANCELLED');

  const ExportStatus(this.dbValue);

  final String dbValue;

  static ExportStatus? fromDbValue(String value) {
    for (final status in ExportStatus.values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    return null;
  }
}

enum ExportWarning {
  targetSizeMissed,
  qualityFloorReached,
  upscaledBeyondSource,
  sourceEvicted,
  aspectRatioAdjusted,
  sourceChanged,
  suboptimalDpi,
}

final class ExportResult {
  const ExportResult({
    required this.id,
    required this.format,
    required this.actualBytes,
    required this.outWidth,
    required this.outHeight,
    required this.pageCount,
    required this.appliedQuality,
    required this.warnings,
    required this.duration,
    this.artifactBlobId,
    this.shareUri,
    this.effectiveDpi,
  });

  final ExportId id;
  final BlobId? artifactBlobId;

  /// `FileProvider` content URI with a scoped grant; attached by the
  /// application layer, not by the engine.
  final String? shareUri;

  final OutputFormat format;
  final int actualBytes;
  final int outWidth;
  final int outHeight;
  final int? effectiveDpi;
  final int pageCount;

  /// What the size solver actually landed on.
  final int appliedQuality;

  final List<ExportWarning> warnings;
  final Duration duration;
}
