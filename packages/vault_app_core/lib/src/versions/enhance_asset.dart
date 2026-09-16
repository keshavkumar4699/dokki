/// `EnhanceAssetUseCase` (Phase 8): detect the document quad and commit a
/// perspective correction as a new derived version.
///
/// Detection is honest: a `null` quad is an [ImageProcessingFailed]
/// outcome, so the UI can offer manual corners instead of pretending the
/// auto-crop worked.
library;

import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import 'version_use_cases.dart';

final class EnhanceAssetUseCase {
  const EnhanceAssetUseCase({required this.services, required this.detector});

  final VersionServices services;
  final EdgeDetector detector;

  Future<Result<Asset, VaultFailure>> execute(
    AssetId assetId, {
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    final loaded = await services.entries.findAsset(assetId);
    return loaded.asyncFlatMap((asset) async {
      final current = asset.currentVersion;
      if (current == null || current.blobId == null) {
        return Err(MissingVersion(asset.currentVersionId));
      }
      final opened = await services.blobStore.openRead(current.blobId!);
      return opened.asyncFlatMap((handle) async {
        cancel?.throwIfCancelled();
        final detected = await detector.detect(handle);
        return detected.asyncFlatMap((quad) async {
          if (quad == null) {
            return const Err(
              ImageProcessingFailed('detectDocument: no confident quad'),
            );
          }
          return CommitEditUseCase(
            services,
          ).execute(assetId, EditRecipe([PerspectiveOp(quad)]), cancel: cancel);
        });
      });
    });
  });
}
