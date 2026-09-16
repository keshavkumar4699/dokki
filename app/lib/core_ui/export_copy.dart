/// Export outcomes → user-facing copy (§11.2): warnings "do real work" —
/// the UI must say honestly what the engine produced.
library;

import 'package:vault_domain/vault_domain.dart';

/// One line per warning, exhaustive so a new warning is a compile error.
String describeExportWarning(ExportWarning warning) => switch (warning) {
  ExportWarning.targetSizeMissed =>
    'Couldn’t land on the requested size; this is the closest.',
  ExportWarning.qualityFloorReached =>
    'Compressed to the quality floor to get here.',
  ExportWarning.upscaledBeyondSource =>
    'Larger than the original — it was upscaled.',
  ExportWarning.sourceEvicted =>
    'This version was rebuilt from its edit history first.',
  ExportWarning.aspectRatioAdjusted => 'The aspect ratio was changed to fit.',
  ExportWarning.sourceChanged =>
    'The exact version was gone; the current one was used instead.',
  ExportWarning.suboptimalDpi => 'Lower than print resolution for that size.',
};

String formatLabel(OutputFormat format) => switch (format) {
  OutputFormat.jpeg => 'JPEG',
  OutputFormat.png => 'PNG',
  OutputFormat.webp => 'WebP',
  OutputFormat.pdf => 'PDF',
};

/// `184 KB`, `2.4 MB`.
String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).round()} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
