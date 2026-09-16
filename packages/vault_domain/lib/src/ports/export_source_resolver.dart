/// `ExportSourceResolver` port: pipeline step 2 of §11.3 and the §11.7
/// "Export Again" strategy. Turns an [ExportSource] into the concrete
/// versions to render, applying the documented fallbacks and telling the
/// caller which one happened.
///
/// The policy lives in the application layer (it re-materializes through
/// the version use cases); the export engine only consumes the outcome.
library;

import '../export/export_request.dart';
import '../export/export_result.dart';
import '../failures/vault_failure.dart';
import '../ids.dart';
import '../imaging/image_meta.dart';
import '../result.dart';

/// One image to render, in output order.
final class ResolvedSource {
  const ResolvedSource({
    required this.entryId,
    required this.assetId,
    required this.requestedVersionId,
    required this.versionId,
    required this.blobId,
    required this.meta,
    this.warnings = const [],
  });

  final EntryId entryId;
  final AssetId assetId;

  /// The version the request named (for `SingleVersionSource` & co), or
  /// the current version for `CurrentOfEntrySource`.
  final VersionId requestedVersionId;

  /// The version actually rendered. Differs from [requestedVersionId]
  /// only after the "evicted, non-deterministic → current" fallback.
  final VersionId versionId;

  final BlobId blobId;
  final ImageMeta meta;

  /// `sourceEvicted` (rebuilt from its recipe) or `sourceChanged` (fell
  /// back to the asset's current version).
  final List<ExportWarning> warnings;
}

abstract interface class ExportSourceResolver {
  /// Resolves every version in [source] to a materialized blob:
  ///
  /// ```
  /// exact version materialized      → use it
  /// exact version evicted, det.     → rematerialize, use it   (+sourceEvicted)
  /// exact version evicted, non-det. → asset's CURRENT version (+sourceChanged)
  /// version row missing entirely    → MissingVersion failure
  /// ```
  Future<Result<List<ResolvedSource>, VaultFailure>> resolve(
    ExportSource source,
  );
}
