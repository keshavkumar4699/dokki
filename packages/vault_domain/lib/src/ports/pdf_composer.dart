/// `PdfComposer` port (§11.5, §15.6).
///
/// Swapping the PDF library changes the composer and nothing else. The
/// composer takes `PlacedCell`s plus image handles and emits bytes; it
/// knows nothing about Flutter, widgets, or screen density (M12).
library;

import '../export/export_request.dart';
import '../export/placed_cell.dart';
import '../failures/vault_failure.dart';
import '../result.dart';
import 'blob_store.dart';

/// Metadata policy: the composer must emit NO author/producer/path
/// metadata that could leak document names (§15.6).
final class PdfComposeRequest {
  const PdfComposeRequest({
    required this.spec,
    required this.placements,
    required this.images,
  });

  final PageLayoutSpec spec;

  /// One placement per image index.
  final List<PlacedCell> placements;

  /// Sealed image blobs, in the same order as [placements].
  final List<BlobHandle> images;
}

abstract interface class PdfComposer {
  Future<Result<List<int>, VaultFailure>> compose(
    PdfComposeRequest request, {
    ProgressSink? progress,
    CancellationToken? cancel,
  });
}
