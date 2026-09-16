/// `StorageBudget` (§7.6): storage accounting and pressure, so the app
/// degrades honestly before the disk fills instead of corrupting a write
/// halfway through a 40 MB blob.
library;

import '../failures/vault_failure.dart';
import '../result.dart';

/// A storage accounting snapshot (§7.6).
final class StorageBudgetReport {
  const StorageBudgetReport({
    required this.assetBytes,
    required this.thumbnailBytes,
    required this.exportBytes,
    required this.logBytes,
    required this.freeBytes,
    required this.floorBytes,
  });

  /// Sealed originals + derived versions.
  final int assetBytes;

  /// Thumbnail cache (fully regenerable — first to go under pressure).
  final int thumbnailBytes;

  /// Retained export artifacts.
  final int exportBytes;

  /// Sync scratch (segments pending upload/download).
  final int logBytes;

  /// Free bytes on the vault's filesystem, or null when unmeasurable.
  final int? freeBytes;

  /// The configured floor: below this, pressure behaviour kicks in.
  final int floorBytes;

  int get totalBytes => assetBytes + thumbnailBytes + exportBytes + logBytes;

  /// Whether free space is below the floor (§7.6). With no measurement,
  /// assume fine — refusing to write on a guess would be worse.
  bool get underPressure => freeBytes != null && freeBytes! < floorBytes;
}

abstract interface class StorageBudget {
  /// The current accounting. Cheap enough for a settings card; the
  /// import path uses it before every write.
  Future<Result<StorageBudgetReport, VaultFailure>> check();
}
