/// `StorageBudget` over the on-disk layout (§7.6). Walks the sealed
/// directories per class and asks the host for free space; the import
/// path refuses BEFORE writing when the floor is crossed (checking after
/// writing 40 MB is how you end up with corrupt partial blobs).
library;

import 'dart:io';

import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import '../paths.dart';

final class StorageBudgetImpl implements StorageBudget {
  const StorageBudgetImpl({
    required this.paths,
    required this.freeSpace,
    this.floorBytes = defaultFloorBytes,
  });

  /// Default floor (§7.6): 300 MB of headroom before pressure.
  static const defaultFloorBytes = 300 * 1024 * 1024;

  final BlobPaths paths;

  /// Free bytes on the vault's filesystem (StatFs on Android).
  final Future<int?> Function() freeSpace;
  final int floorBytes;

  @override
  Future<Result<StorageBudgetReport, VaultFailure>> check() =>
      guardIo('storageBudget', () async {
        return StorageBudgetReport(
          assetBytes: await _dirBytes(StorageClass.asset),
          thumbnailBytes: await _dirBytes(StorageClass.thumbnail),
          exportBytes: await _dirBytes(StorageClass.exportArtifact),
          logBytes: await _dirBytes(StorageClass.syncLog),
          freeBytes: await freeSpace(),
          floorBytes: floorBytes,
        );
      });

  Future<int> _dirBytes(StorageClass storageClass) async {
    final dir = Directory(paths.absolute(BlobPaths.dirFor(storageClass)));
    if (!dir.existsSync()) {
      return 0;
    }
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && !entity.path.endsWith('.part')) {
        total += await entity.length();
      }
    }
    return total;
  }
}
