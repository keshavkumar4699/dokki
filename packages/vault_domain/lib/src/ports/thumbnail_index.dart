/// `ThumbnailIndex` port: the `thumbnails` table (§7.5) behind an
/// interface, so the cache in `vault_storage` can track its entries and
/// run LRU eviction without touching the database directly.
library;

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';
import 'blob_store.dart';
import 'thumbnail_provider.dart';

final class ThumbnailRecord {
  const ThumbnailRecord({
    required this.id,
    required this.versionId,
    required this.sizeClass,
    required this.blobId,
    required this.width,
    required this.height,
    required this.byteSize,
    required this.createdAt,
    required this.lastAccessedAt,
  });

  final String id;
  final VersionId versionId;
  final ThumbnailSizeClass sizeClass;
  final BlobId blobId;
  final int width;
  final int height;

  /// Ciphertext size on disk, for budget accounting.
  final int byteSize;

  final DateTime createdAt;
  final DateTime lastAccessedAt;
}

abstract interface class ThumbnailIndex {
  Future<Result<ThumbnailRecord?, VaultFailure>> find(
    VersionId versionId,
    ThumbnailSizeClass sizeClass,
  );

  /// Records a freshly generated thumbnail and its sealed [blob] in one
  /// transaction. Replaces an existing entry for the same slot.
  Future<Result<ThumbnailRecord, VaultFailure>> record({
    required String id,
    required VersionId versionId,
    required ThumbnailSizeClass sizeClass,
    required BlobRef blob,
    required int width,
    required int height,
    required DateTime now,
  });

  /// Bumps the LRU column.
  Future<Result<void, VaultFailure>> touch(String id, DateTime at);

  /// Removes every thumbnail of every version of [assetId]; returns the
  /// blob ids the caller must purge from disk.
  Future<Result<List<BlobId>, VaultFailure>> removeForAsset(AssetId assetId);

  /// Removes one record; returns its blob id for purging.
  Future<Result<BlobId?, VaultFailure>> remove(String id);

  /// Least-recently-used first, for budget trimming.
  Future<Result<List<ThumbnailRecord>, VaultFailure>> leastRecentlyUsed({
    int limit = 100,
  });

  /// Total ciphertext bytes held by the cache.
  Future<Result<int, VaultFailure>> totalBytes();
}
