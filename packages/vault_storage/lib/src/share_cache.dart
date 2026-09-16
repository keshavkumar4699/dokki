/// The share cache (§7.1 "export output"): the one directory that may hold
/// plaintext, and only for as long as a share intent needs it. Swept on
/// every launch and on lock.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';

final class ShareCache {
  const ShareCache(this.directory);

  /// Absolute path of the cache directory (`<cache>/export_tmp`).
  final String directory;

  /// Where a plaintext copy of an export artifact goes.
  String pathFor(String fileName) => p.join(directory, fileName);

  /// Deletes everything in the cache. Returns how many files went.
  Future<Result<int, VaultFailure>> sweep() =>
      guardIo('sweepShareCache', () async {
        final dir = Directory(directory);
        if (!dir.existsSync()) {
          return 0;
        }
        var removed = 0;
        await for (final entity in dir.list()) {
          await entity.delete(recursive: true);
          removed++;
        }
        return removed;
      });

  /// Deletes one shared file once the share sheet has returned.
  Future<Result<void, VaultFailure>> discard(String path) =>
      guardIo('discardShared', () async {
        if (!p.isWithin(directory, path)) {
          throw const StorageException(InvalidAsset('not in the share cache'));
        }
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
        }
      });
}
