/// `ThumbnailProvider` port (§7.5).
///
/// The UI asks for a thumbnail and receives a stream of states; it has no
/// idea whether the result came from cache, a fresh decode, or a
/// downsampled re-decode of a 40 MP original.
library;

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';

enum ThumbnailSizeClass {
  s(128),
  m(384),
  l(1024);

  const ThumbnailSizeClass(this.maxEdge);

  final int maxEdge;

  String get dbValue => name.toUpperCase();

  static ThumbnailSizeClass? fromDbValue(String value) {
    for (final sizeClass in ThumbnailSizeClass.values) {
      if (sizeClass.dbValue == value) {
        return sizeClass;
      }
    }
    return null;
  }
}

sealed class ThumbnailState {
  const ThumbnailState();
}

final class ThumbnailLoading extends ThumbnailState {
  const ThumbnailLoading();
}

final class ThumbnailReady extends ThumbnailState {
  const ThumbnailReady({
    required this.blobId,
    required this.width,
    required this.height,
  });

  /// The sealed thumbnail blob. The presentation layer adapts this into a
  /// renderable image through `BlobStore.readSmall` — thumbnails are the
  /// one bounded plaintext the Dart heap is allowed to hold (§8.4).
  final BlobId blobId;
  final int width;
  final int height;
}

final class ThumbnailFailed extends ThumbnailState {
  const ThumbnailFailed(this.failure);

  final VaultFailure failure;
}

abstract interface class ThumbnailProvider {
  /// Emits `loading` → `ready` / `failed`. Re-emits when the source
  /// version changes.
  Stream<ThumbnailState> request(VersionId versionId, ThumbnailSizeClass size);

  /// Drops cached thumbnails for every version of [assetId].
  Future<Result<void, VaultFailure>> invalidate(AssetId assetId);

  /// Evicts thumbnails by LRU until the cache is within budget.
  Future<Result<int, VaultFailure>> trimToBudget(int maxBytes);
}
