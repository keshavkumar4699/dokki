/// Asset-level use cases: add a page or an ID back, reorder pages, and
/// remove an asset. Each validates against the entry's `EntryTypeSpec`
/// before touching storage so a doomed import never seals a blob.
library;

import 'package:vault_domain/vault_domain.dart';

import '../assets/asset_importer.dart';
import '../assets/import_source.dart';
import '../context/vault_context.dart';
import '../error_boundary.dart';

final class AddAssetUseCase {
  const AddAssetUseCase({
    required this.context,
    required this.entries,
    required this.importer,
  });

  final VaultContext context;
  final EntryRepository entries;
  final AssetImporter importer;

  /// Appends a `PAGE` to a document (at the end unless [ordinal] is
  /// given) or fills a singleton slot such as `ID_BACK`.
  Future<Result<Asset, VaultFailure>> execute(
    EntryId entryId, {
    required AssetRole role,
    required ImportSource source,
    int? ordinal,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    final loaded = await entries.findEntry(entryId);
    return loaded.asyncFlatMap((entry) async {
      final spec = specFor(entry.type);
      final live = entry.liveAssets.toList(growable: false);
      final slotCheck = _checkSlot(spec, live, role);
      if (slotCheck != null) {
        return Err(slotCheck);
      }
      final slot = ordinal ?? _nextOrdinal(live, role);
      final sealed = await importer.seal(
        source,
        progress: progress,
        cancel: cancel,
      );
      return sealed.asyncFlatMap((imported) async {
        final added = await entries.addAsset(
          importer.describe(
            imported,
            entryId: entryId,
            role: role,
            ordinal: slot,
          ),
        );
        return switch (added) {
          Ok() => added,
          Err(:final error) => await importer.discard(imported.blob, error),
        };
      });
    });
  });

  static VaultFailure? _checkSlot(
    EntryTypeSpec spec,
    List<Asset> live,
    AssetRole role,
  ) {
    if (!spec.allowsRole(role)) {
      return EntryInvariantViolated(
        'role ${role.dbValue} not allowed on ${spec.type.dbValue}',
      );
    }
    final max = spec.cardinalityFor(role).max;
    final count = live.where((a) => a.role == role).length;
    if (max >= 0 && count >= max) {
      return EntryInvariantViolated(
        '${spec.type.dbValue} already has $count ${role.dbValue} '
        '(max $max)',
      );
    }
    return null;
  }

  static int _nextOrdinal(List<Asset> live, AssetRole role) {
    var next = 0;
    for (final asset in live) {
      if (asset.role == role && asset.ordinal >= next) {
        next = asset.ordinal + 1;
      }
    }
    return next;
  }
}

final class ReorderPagesUseCase {
  const ReorderPagesUseCase({required this.context, required this.entries});

  final VaultContext context;
  final EntryRepository entries;

  /// [orderedAssetIds] must name every live page exactly once (I7).
  Future<Result<VaultEntry, VaultFailure>> execute(
    EntryId entryId,
    List<AssetId> orderedAssetIds,
  ) async {
    final loaded = await entries.findEntry(entryId);
    return loaded.asyncFlatMap((entry) async {
      if (!specFor(entry.type).ordinalIsMeaningful) {
        return Err(
          EntryInvariantViolated(
            '${entry.type.dbValue} pages cannot be reordered',
          ),
        );
      }
      final reordered = await entries.reorderPages(
        entryId,
        orderedAssetIds,
        hlc: context.nextHlc(),
        now: context.now(),
      );
      return reordered.asyncFlatMap((_) => entries.findEntry(entryId));
    });
  }
}

final class DeleteAssetUseCase {
  const DeleteAssetUseCase({required this.context, required this.entries});

  final VaultContext context;
  final EntryRepository entries;

  /// Soft-deletes one asset. Refuses to drop below the type's minimum
  /// (a document keeps ≥1 page; an ID keeps its front). For pages the
  /// remaining ordinals are re-packed to `0..n-1` (I7).
  Future<Result<VaultEntry, VaultFailure>> execute(AssetId assetId) async {
    final loadedAsset = await entries.findAsset(assetId);
    return loadedAsset.asyncFlatMap((asset) async {
      final loadedEntry = await entries.findEntry(asset.entryId);
      return loadedEntry.asyncFlatMap((entry) async {
        final spec = specFor(entry.type);
        final live = entry.liveAssets.toList(growable: false);
        final sameRole = live.where((a) => a.role == asset.role).length;
        if (sameRole - 1 < spec.cardinalityFor(asset.role).min) {
          return Err(
            EntryInvariantViolated(
              'cannot remove the last ${asset.role.dbValue} of a '
              '${entry.type.dbValue}',
            ),
          );
        }
        final now = context.now();
        final deleted = await entries.deleteAsset(
          assetId,
          Tombstone.of(
            entityKind: TombstoneEntityKind.asset,
            entityId: assetId,
            deletedHlc: context.nextHlc(),
            originDevice: context.deviceId,
            deletedAt: now,
          ),
          now: now,
        );
        return deleted.asyncFlatMap((_) async {
          if (spec.ordinalIsMeaningful) {
            final remaining = live
                .where((a) => a.id != assetId)
                .map((a) => a.id)
                .toList(growable: false);
            final packed = await entries.reorderPages(
              entry.id,
              remaining,
              hlc: context.nextHlc(),
              now: context.now(),
            );
            if (packed.isErr) {
              return Err(packed.errOrNull!);
            }
          }
          return entries.findEntry(entry.id);
        });
      });
    });
  }
}
