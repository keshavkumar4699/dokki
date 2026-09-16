/// The seam between the native pipeline and the blob store: the native
/// side works on *files* (a sealed input, a sealed output), while the
/// store owns ids, paths, atomic commits and the `BlobRef` contract. The
/// composition root implements this over `FileBlobStore`.
library;

import 'package:vault_domain/vault_domain.dart';

/// A sealed blob file the native side may read.
final class SealedInput {
  const SealedInput({required this.path, required this.purpose});

  /// Absolute path of the sealed file.
  final String path;

  /// `EnvelopePurpose.byte` of its storage class.
  final int purpose;
}

/// An output slot: the native side writes the sealed file to [partPath];
/// [SealedBlobFiles.commit] renames it into place and mints the
/// `BlobRef`; [SealedBlobFiles.abandon] deletes it after a failure.
final class PendingSealedBlob {
  const PendingSealedBlob({
    required this.id,
    required this.storageClass,
    required this.relPath,
    required this.partPath,
    required this.purpose,
    required this.keyEpoch,
  });

  final BlobId id;
  final StorageClass storageClass;
  final String relPath;
  final String partPath;
  final int purpose;
  final int keyEpoch;
}

/// What the native seal reported, for the `BlobRef`.
final class SealedFileInfo {
  const SealedFileInfo({
    required this.keyEpoch,
    required this.wrappedDek,
    required this.plaintextSize,
    required this.ciphertextSize,
    required this.plaintextSha256,
    required this.ciphertextSha256,
  });

  final int keyEpoch;
  final List<int> wrappedDek;
  final int plaintextSize;
  final int ciphertextSize;
  final String plaintextSha256;
  final String ciphertextSha256;
}

abstract interface class SealedBlobFiles {
  /// Locates the sealed file behind [handle].
  Future<SealedInput> resolve(BlobHandle handle);

  /// Reserves an id and a `.part` path for a new blob of [storageClass].
  Future<PendingSealedBlob> allocate(StorageClass storageClass);

  /// Renames the `.part` into place and returns the blob reference.
  Future<BlobRef> commit(PendingSealedBlob pending, SealedFileInfo info);

  /// Deletes a `.part` the native side wrote before a failure.
  Future<void> abandon(PendingSealedBlob pending);
}
