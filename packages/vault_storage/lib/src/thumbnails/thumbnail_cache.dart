/// `ThumbnailProvider` implementation (§7.5): lazy generation on first
/// request, sealed under `K_thumb`, indexed with an LRU column, capped.
library;

import 'dart:async';

import 'package:vault_domain/vault_domain.dart';

final class ThumbnailCache implements ThumbnailProvider {
  ThumbnailCache({
    required this.index,
    required this.entries,
    required this.blobStore,
    required this.images,
    required this.clock,
    required this.ids,
    this.budgetBytes = 250 * 1024 * 1024,
  });

  final ThumbnailIndex index;
  final EntryRepository entries;
  final BlobStore blobStore;
  final ImageProcessor images;
  final Clock clock;
  final IdGenerator ids;

  /// Default 250 MB (§7.5). Trimmed opportunistically after generation.
  final int budgetBytes;

  /// De-duplicates concurrent requests for the same slot so a grid of 500
  /// tiles does not decode the same original twice.
  final Map<String, Future<Result<ThumbnailReady, VaultFailure>>> _inFlight =
      {};

  @override
  Stream<ThumbnailState> request(
    VersionId versionId,
    ThumbnailSizeClass size,
  ) async* {
    yield const ThumbnailLoading();
    final result = await _resolve(versionId, size);
    yield switch (result) {
      Ok(:final value) => value,
      Err(:final error) => ThumbnailFailed(error),
    };
  }

  Future<Result<ThumbnailReady, VaultFailure>> _resolve(
    VersionId versionId,
    ThumbnailSizeClass size,
  ) {
    final key = '$versionId/${size.name}';
    return _inFlight.putIfAbsent(key, () async {
      try {
        return await _lookupOrGenerate(versionId, size);
      } finally {
        unawaited(_inFlight.remove(key));
      }
    });
  }

  Future<Result<ThumbnailReady, VaultFailure>> _lookupOrGenerate(
    VersionId versionId,
    ThumbnailSizeClass size,
  ) async {
    final cached = await index.find(versionId, size);
    if (cached case Ok(value: final record?)) {
      if (await _present(record.blobId)) {
        await index.touch(record.id, clock.now());
        return Ok(
          ThumbnailReady(
            blobId: record.blobId,
            width: record.width,
            height: record.height,
          ),
        );
      }
      // The index knows a thumbnail the disk no longer has (LRU trim or a
      // crash between file delete and row delete): regenerate.
      await index.remove(record.id);
    }
    return _generate(versionId, size);
  }

  Future<Result<ThumbnailReady, VaultFailure>> _generate(
    VersionId versionId,
    ThumbnailSizeClass size,
  ) async {
    final version = await entries.findVersion(versionId);
    return version.asyncFlatMap((row) async {
      if (row == null) {
        return Err(MissingVersion(versionId));
      }
      final blobId = row.blobId;
      if (blobId == null) {
        return Err(MissingVersion(versionId));
      }
      final preview = await blobStore
          .openRead(blobId)
          .asyncFlatMap(
            (handle) => images.preview(handle, maxEdge: size.maxEdge),
          );
      return preview.asyncFlatMap((image) async {
        final recorded = await index.record(
          id: ids.newEntityId(),
          versionId: versionId,
          sizeClass: size,
          blob: image.blobRef,
          width: image.meta.width,
          height: image.meta.height,
          now: clock.now(),
        );
        if (recorded.isErr) {
          await blobStore.purge(image.blobRef.id);
          return Err(recorded.errOrNull!);
        }
        unawaited(trimToBudget(budgetBytes));
        return Ok(
          ThumbnailReady(
            blobId: image.blobRef.id,
            width: image.meta.width,
            height: image.meta.height,
          ),
        );
      });
    });
  }

  @override
  Future<Result<void, VaultFailure>> invalidate(AssetId assetId) async {
    final removed = await index.removeForAsset(assetId);
    return removed.asyncMap((blobIds) async {
      for (final id in blobIds) {
        await blobStore.purge(id);
      }
    });
  }

  @override
  Future<Result<int, VaultFailure>> trimToBudget(int maxBytes) async {
    final total = await index.totalBytes();
    return total.asyncFlatMap((bytes) async {
      var remaining = bytes;
      var evicted = 0;
      if (remaining <= maxBytes) {
        return const Ok(0);
      }
      final lru = await index.leastRecentlyUsed();
      if (lru case Err(:final error)) {
        return Err(error);
      }
      for (final record in lru.okOrNull!) {
        if (remaining <= maxBytes) {
          break;
        }
        await index.remove(record.id);
        await blobStore.purge(record.blobId);
        remaining -= record.byteSize;
        evicted++;
      }
      return Ok(evicted);
    });
  }

  Future<bool> _present(BlobId id) async =>
      (await blobStore.exists(id)).getOrElse((_) => false);
}
