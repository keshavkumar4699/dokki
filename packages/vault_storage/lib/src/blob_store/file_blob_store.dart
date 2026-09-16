/// `FileBlobStore`: sealed Envelope-v1 files with the atomic write path of
/// §7.3 and the handle-only read path of §7.4.
///
/// The store never touches the database. The `blobs` row is written by
/// the repository from the [BlobRef] this store returns, inside the same
/// transaction as the version row.
library;

import 'dart:async';
import 'dart:convert' show ByteConversionSink;
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart' show AccumulatorSink, hex;
import 'package:crypto/crypto.dart';
import 'package:vault_crypto/vault_crypto.dart' show EnvelopeHeader;
import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import '../paths.dart';

/// A handle is just the blob id and where it lives; bytes never cross it.
final class FileBlobHandle implements BlobHandle {
  const FileBlobHandle({
    required this.token,
    required this.relPath,
    required this.storageClass,
    required this.plaintextSize,
  });

  @override
  final String token;

  final String relPath;
  final StorageClass storageClass;

  @override
  final int? plaintextSize;
}

final class FileBlobStore implements BlobStore {
  FileBlobStore({
    required String rootDir,
    required this.crypto,
    required this.ids,
    required this.activeKeyEpoch,
  }) : paths = BlobPaths(rootDir);

  final BlobPaths paths;
  final CryptoEngine crypto;
  final IdGenerator ids;

  /// Provided by the `KeyManager`; every new blob is sealed under it.
  final int Function() activeKeyEpoch;

  // ── Write path (§7.3) ──────────────────────────────────────────────────

  @override
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final id = ids.newBlobId();
    final relPath = BlobPaths.relPathFor(storageClass, id);
    final part = File(paths.partFile(relPath));
    final finalFile = File(paths.absolute(relPath));
    return guardIo('write', blobId: id, () async {
      await part.parent.create(recursive: true);
      final keyEpoch = activeKeyEpoch();
      final plaintextDigest = _Sha256Sink();
      final ciphertextDigest = _Sha256Sink();
      var plaintextSize = 0;
      var ciphertextSize = 0;
      Uint8List? headerBytes;

      final counted = source.map((chunk) {
        cancel?.throwIfCancelled();
        plaintextDigest.add(chunk);
        plaintextSize += chunk.length;
        progress?.call(plaintextSize, expectedSize);
        return chunk;
      });
      final sealed = crypto.sealStream(
        counted,
        keyEpoch: keyEpoch,
        purpose: BlobPaths.purposeFor(storageClass),
      );

      final sink = part.openWrite();
      try {
        await for (final chunk in sealed) {
          headerBytes ??= Uint8List.fromList(chunk);
          ciphertextDigest.add(chunk);
          ciphertextSize += chunk.length;
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (headerBytes == null) {
        await _deleteQuietly(part);
        throw const StorageException(StorageIoFailure('write: empty seal'));
      }
      final header = EnvelopeHeader.parse(headerBytes);
      // rename() is atomic on ext4/f2fs; a crash before this line leaves
      // only a .part file, swept on next launch.
      await part.rename(finalFile.path);
      return BlobRef(
        id: id,
        storageClass: storageClass,
        relPath: relPath,
        keyEpoch: header.keyEpoch,
        wrappedDek: header.wrappedDek,
        plaintextSize: plaintextSize,
        ciphertextSize: ciphertextSize,
        ciphertextSha256: ciphertextDigest.hexDigest(),
        plaintextSha256: plaintextDigest.hexDigest(),
      );
    }).then((result) async {
      if (result.isErr) {
        await _deleteQuietly(part);
      }
      return result;
    });
  }

  // ── Read path (§7.4) ───────────────────────────────────────────────────

  @override
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id) =>
      guardIo('openRead', blobId: id, () async {
        final located = await _locate(id);
        if (located == null) {
          throw StorageException(CorruptFile(id));
        }
        return located;
      });

  /// Decrypted bytes of the blob behind [handle], streamed in envelope
  /// chunks. For the in-process image pipeline and small-payload reads;
  /// the native pipeline reads the file directly.
  Stream<List<int>> openPlaintext(BlobHandle handle) {
    final located = handle is FileBlobHandle ? handle : null;
    if (located == null) {
      return Stream.error(ArgumentError('Not a FileBlobHandle'));
    }
    return crypto.openStream(
      File(paths.absolute(located.relPath)).openRead(),
      expectedPurpose: BlobPaths.purposeFor(located.storageClass),
    );
  }

  @override
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  }) => guardIo('readSmall', blobId: id, () async {
    final located = await _locate(id);
    if (located == null) {
      throw StorageException(CorruptFile(id));
    }
    final size = located.plaintextSize ?? 0;
    if (size > maxBytes) {
      throw StorageException(
        InvalidAsset('blob $id is $size bytes; readSmall cap is $maxBytes'),
      );
    }
    final out = BytesBuilder(copy: false);
    await openPlaintext(located).forEach(out.add);
    return out.takeBytes();
  });

  /// Decrypts [id] into a plaintext file at [destinationPath] (§7.1 export
  /// output): the only sanctioned way plaintext reaches disk, and only for
  /// the share intent, in the cache directory the caller sweeps. Written
  /// via a `.part` and renamed, so a reader never sees a half file.
  Future<Result<int, VaultFailure>> copyPlaintextTo(
    BlobId id,
    String destinationPath, {
    CancellationToken? cancel,
  }) => guardIo('copyPlaintextTo', blobId: id, () async {
    final located = await _locate(id);
    if (located == null) {
      throw StorageException(CorruptFile(id));
    }
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    final part = File('$destinationPath.part');
    var written = 0;
    final sink = part.openWrite();
    try {
      await for (final chunk in openPlaintext(located)) {
        cancel?.throwIfCancelled();
        sink.add(chunk);
        written += chunk.length;
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await part.rename(destinationPath);
    return written;
  });

  /// The sealed bytes as stored on disk — the cloud upload path moves
  /// these verbatim (§9.2 "sync never decrypts anything").
  @override
  Stream<List<int>>? ciphertextStream(BlobHandle handle) {
    final located = handle is FileBlobHandle ? handle : null;
    if (located == null) {
      return null;
    }
    return File(paths.absolute(located.relPath)).openRead();
  }

  /// §9.8 download path: stream to `.part`, verify the ciphertext hash,
  /// rename. A partially downloaded file is never visible under a real
  /// blob path, so an interrupted download is never mistaken for a
  /// corrupt blob.
  @override
  Future<Result<({int ciphertextSize, String ciphertextSha256}), VaultFailure>>
  writeSealed(
    BlobId id,
    Stream<List<int>> ciphertext, {
    StorageClass storageClass = StorageClass.asset,
    required String expectedCiphertextSha256,
    CancellationToken? cancel,
  }) => guardIo('writeSealed', blobId: id, () async {
    final relPath = BlobPaths.relPathFor(storageClass, id);
    final part = File(paths.partFile(relPath));
    await part.parent.create(recursive: true);
    final digest = _Sha256Sink();
    var size = 0;
    try {
      final sink = part.openWrite();
      try {
        await for (final chunk in ciphertext) {
          cancel?.throwIfCancelled();
          digest.add(chunk);
          size += chunk.length;
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final hexDigest = digest.hexDigest();
      // An empty expectation means the caller cannot know the hash yet
      // (a peer-written segment); the AEAD verification at open time is
      // then the authoritative integrity check (T12).
      if (expectedCiphertextSha256.isNotEmpty &&
          hexDigest != expectedCiphertextSha256.toLowerCase()) {
        throw StorageException(RemoteObjectTampered(id));
      }
      await part.rename(paths.absolute(relPath));
      return (ciphertextSize: size, ciphertextSha256: hexDigest);
    } catch (e) {
      await _deleteQuietly(part);
      rethrow;
    }
  });

  @override
  Future<Result<void, VaultFailure>> verify(BlobId id) =>
      guardIo('verify', blobId: id, () async {
        final located = await _locate(id);
        if (located == null) {
          throw StorageException(CorruptFile(id));
        }
        final verified = await crypto.verifyStream(
          File(paths.absolute(located.relPath)).openRead(),
          expectedPurpose: BlobPaths.purposeFor(located.storageClass),
        );
        if (verified.isErr) {
          throw StorageException(verified.errOrNull!);
        }
      });

  @override
  Future<Result<bool, VaultFailure>> exists(BlobId id) =>
      guardIo('exists', blobId: id, () async => await _locate(id) != null);

  // ── Deletion ───────────────────────────────────────────────────────────

  /// At the file level eviction and purge are the same delete; the
  /// repository is what refuses to evict an ORIGINAL (I2) or a pinned
  /// version (I10), before this is ever called.
  @override
  Future<Result<void, VaultFailure>> evict(BlobId id) => purge(id);

  @override
  Future<Result<void, VaultFailure>> purge(BlobId id) =>
      guardIo('purge', blobId: id, () async {
        for (final relPath in BlobPaths.candidateRelPaths(id)) {
          await _deleteQuietly(File(paths.absolute(relPath)));
          await _deleteQuietly(File(paths.partFile(relPath)));
        }
      });

  // ── Startup GC (§7.3 step 8) ───────────────────────────────────────────

  /// Deletes every `.part` file: a write that never reached `rename`.
  /// Returns how many were removed.
  Future<Result<int, VaultFailure>> sweepPartialWrites() =>
      guardIo('sweepPartialWrites', () async {
        var removed = 0;
        for (final storageClass in StorageClass.values) {
          final dir = Directory(paths.absolute(BlobPaths.dirFor(storageClass)));
          if (!dir.existsSync()) {
            continue;
          }
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.part')) {
              await _deleteQuietly(entity);
              removed++;
            }
          }
        }
        return removed;
      });

  /// Every blob id present on disk, for orphan reconciliation against the
  /// `blobs` table.
  Future<Result<Set<BlobId>, VaultFailure>> listBlobIds() =>
      guardIo('listBlobIds', () async {
        final found = <BlobId>{};
        for (final storageClass in StorageClass.values) {
          final dir = Directory(paths.absolute(BlobPaths.dirFor(storageClass)));
          if (!dir.existsSync()) {
            continue;
          }
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File && !entity.path.endsWith('.part')) {
              found.add(entity.uri.pathSegments.last);
            }
          }
        }
        return found;
      });

  // ── Internals ──────────────────────────────────────────────────────────

  /// Finds the blob's file by trying each class directory; reads the
  /// authenticated header only to learn the purpose, never the body.
  Future<FileBlobHandle?> _locate(BlobId id) async {
    for (final storageClass in StorageClass.values) {
      final relPath = BlobPaths.relPathFor(storageClass, id);
      final file = File(paths.absolute(relPath));
      if (file.existsSync()) {
        final length = await file.length();
        return FileBlobHandle(
          token: id,
          relPath: relPath,
          storageClass: storageClass,
          plaintextSize: length,
        );
      }
    }
    return null;
  }

  static Future<void> _deleteQuietly(File file) async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// Incremental SHA-256 over a stream of chunks.
final class _Sha256Sink {
  _Sha256Sink() {
    _output = sha256.startChunkedConversion(_digest);
  }

  final AccumulatorSink<Digest> _digest = AccumulatorSink<Digest>();
  late final ByteConversionSink _output;

  void add(List<int> chunk) => _output.add(chunk);

  /// Closes both sinks; the accumulator holds exactly one digest after.
  String hexDigest() {
    _output.close();
    final digest = _digest.events.single;
    _digest.close();
    return hex.encode(digest.bytes);
  }
}
