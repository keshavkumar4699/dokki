/// The shared "bytes → sealed ORIGINAL version" pipeline used by
/// `CreateEntry` and `AddAsset` (§2.1, §7.3).
///
/// 1. Stream the source into the `BlobStore` (sealed on the way in).
/// 2. Inspect the sealed blob for dimensions and format (native decode
///    of the header only; no full bitmap).
/// 3. Build the `NewAsset` value. The caller commits it; on any failure
///    the orphan blob is purged so a failed import leaves nothing behind.
library;

import 'package:vault_domain/vault_domain.dart';

import '../context/vault_context.dart';
import 'import_source.dart';

/// A sealed blob plus everything needed to describe it as a version.
final class ImportedBlob {
  const ImportedBlob({required this.blob, required this.info});

  final BlobRef blob;
  final ImageInfo info;

  ImageMeta get meta => ImageMeta(
    width: info.width,
    height: info.height,
    mime: info.mime,
    plaintextSha256: blob.plaintextSha256,
    byteSize: blob.plaintextSize,
  );
}

final class AssetImporter {
  const AssetImporter({
    required this.context,
    required this.blobStore,
    required this.images,
  });

  final VaultContext context;
  final BlobStore blobStore;
  final ImageProcessor images;

  /// Seals [source] and inspects it. Purges the blob if inspection fails.
  Future<Result<ImportedBlob, VaultFailure>> seal(
    ImportSource source, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final written = await blobStore.write(
      source.open(),
      storageClass: StorageClass.asset,
      expectedSize: source.byteSize,
      progress: progress,
      cancel: cancel,
    );
    return written.asyncFlatMap((blob) async {
      final inspected = await blobStore
          .openRead(blob.id)
          .asyncFlatMap(images.inspect);
      return switch (inspected) {
        Ok(:final value) => Ok(ImportedBlob(blob: blob, info: value)),
        Err(:final error) => await _discard(blob, error),
      };
    });
  }

  /// Describes [imported] as a `NewAsset` with its ORIGINAL version.
  NewAsset describe(
    ImportedBlob imported, {
    required EntryId entryId,
    required AssetRole role,
    required int ordinal,
  }) {
    final now = context.now();
    final hlc = context.nextHlc();
    final assetId = context.ids.newEntityId();
    return NewAsset(
      id: assetId,
      entryId: entryId,
      role: role,
      ordinal: ordinal,
      hlc: hlc,
      originDevice: context.deviceId,
      createdAt: now,
      blob: imported.blob,
      originalVersion: originalVersion(
        id: context.ids.newEntityId(),
        assetId: assetId,
        seq: 0,
        blobId: imported.blob.id,
        meta: imported.meta,
        hlc: hlc,
        originDevice: context.deviceId,
        createdAt: now,
      ),
    );
  }

  /// Removes a blob whose DB commit never happened (§7.3 step 8: an orphan
  /// file is harmless, but there is no reason to wait for the GC sweep).
  Future<Result<T, VaultFailure>> discard<T>(
    BlobRef blob,
    VaultFailure because,
  ) => _discard(blob, because);

  Future<Result<T, VaultFailure>> _discard<T>(
    BlobRef blob,
    VaultFailure because,
  ) async {
    await blobStore.purge(blob.id);
    return Err(because);
  }
}
