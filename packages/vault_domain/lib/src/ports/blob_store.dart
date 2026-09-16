/// `BlobStore` port (§7.4).
///
/// Deliberately does NOT expose `Future<Uint8List> read(BlobId)` — that
/// signature invites someone to pull a 60 MB decoded bitmap into the Dart
/// heap (M10). Handles and streams only; `readSmall` is capped.
library;

import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';

enum StorageClass {
  asset('ASSET'),
  thumbnail('THUMBNAIL'),
  exportArtifact('EXPORT'),
  syncLog('SYNC_LOG');

  const StorageClass(this.dbValue);

  final String dbValue;

  static StorageClass? fromDbValue(String value) {
    for (final storageClass in StorageClass.values) {
      if (storageClass.dbValue == value) {
        return storageClass;
      }
    }
    return null;
  }
}

/// Progress callback: bytes done, total bytes (null if unknown).
typedef ProgressSink = void Function(int bytesDone, int? totalBytes);

/// Thrown by [CancellationToken.throwIfCancelled] to unwind an in-flight
/// pipeline; use cases surface it as `Err(OperationCancelled)`.
final class OperationCancelledException implements Exception {
  const OperationCancelledException();
}

/// Cooperative cancellation token, checked between chunks and stages.
final class CancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) {
      throw const OperationCancelledException();
    }
  }
}

/// An opaque handle to a blob's bytes. What it points at (native buffer,
/// file, memory region) is the implementer's business; the domain never
/// sees bytes through it.
abstract interface class BlobHandle {
  /// Opaque token, meaningless outside the storage layer.
  String get token;

  /// Approximate plaintext size in bytes, for progress reporting.
  int? get plaintextSize;
}

/// Reference to a freshly written blob.
final class BlobRef {
  const BlobRef({
    required this.id,
    required this.storageClass,
    required this.relPath,
    required this.keyEpoch,
    required this.wrappedDek,
    required this.plaintextSize,
    required this.ciphertextSize,
    required this.ciphertextSha256,
    required this.plaintextSha256,
    this.envelopeVersion = 1,
  });

  final BlobId id;

  final StorageClass storageClass;

  /// Storage-relative path, e.g. `blobs/0a/<uuid>`.
  final String relPath;

  /// The envelope format version written to the file header.
  final int envelopeVersion;

  /// The key epoch the DEK was wrapped under.
  final int keyEpoch;

  /// The wrapped DEK, duplicated from the file header into the `blobs` row
  /// for recovery (§6.2). Opaque bytes.
  final List<int> wrappedDek;

  final int plaintextSize;
  final int ciphertextSize;

  /// Hex SHA-256 of the CIPHERTEXT (integrity + upload idempotency).
  final String ciphertextSha256;

  /// Hex SHA-256 of the PLAINTEXT, computed while streaming it in. Becomes
  /// `ImageMeta.plaintextSha256` so no caller has to hash twice.
  final String plaintextSha256;

  @override
  bool operator ==(Object other) =>
      other is BlobRef && other.id == id && other.relPath == relPath;

  @override
  int get hashCode => Object.hash(id, relPath);
}

abstract interface class BlobStore {
  /// Returns an opaque handle. Bytes stay behind the boundary.
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id);

  /// Streaming write with progress + cancellation. Seals under the current
  /// envelope format before touching disk.
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  });

  /// Small payloads only (<256 KiB): keyring, log segments, encrypted
  /// titles. [maxBytes] is a hard cap; larger requests fail.
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  });

  /// Verifies AEAD tags end-to-end without materialising plaintext.
  Future<Result<void, VaultFailure>> verify(BlobId id);

  /// The SEALED bytes of a blob as a stream, for cloud upload (§9.2):
  /// sync moves the exact bytes already on disk and never decrypts
  /// anything, so it never needs a user-authenticated key. Returns null
  /// when the implementation cannot stream ciphertext (in-memory fakes
  /// that only hold plaintext).
  Stream<List<int>>? ciphertextStream(BlobHandle handle);

  /// Writes an already-sealed blob fetched from the cloud (§9.8): the
  /// bytes stream to a `.part` file, the ciphertext SHA-256 is verified
  /// against [expectedCiphertextSha256] (T12), and only then does the
  /// file become visible under the real blob path. A mismatch fails with
  /// [RemoteObjectTampered] and leaves nothing behind. The `blobs` row
  /// already exists (replay registered it REMOTE_ONLY); this only places
  /// the file and reports what landed.
  Future<Result<({int ciphertextSize, String ciphertextSha256}), VaultFailure>>
  writeSealed(
    BlobId id,
    Stream<List<int>> ciphertext, {
    StorageClass storageClass = StorageClass.asset,
    required String expectedCiphertextSha256,
    CancellationToken? cancel,
  });

  /// Rejects ORIGINAL-backed blobs (invariant I2) and pinned versions.
  Future<Result<void, VaultFailure>> evict(BlobId id);

  /// Hard-delete a blob file. GC only; never call for a referenced blob.
  Future<Result<void, VaultFailure>> purge(BlobId id);

  /// Whether the blob's file is present on disk.
  Future<Result<bool, VaultFailure>> exists(BlobId id);
}
