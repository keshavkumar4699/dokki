/// Version use cases (§2.1, §10): commit an edit, switch the current
/// pointer, and re-materialize an evicted version from its recipe chain.
library;

import 'package:vault_domain/vault_domain.dart';

import '../context/vault_context.dart';
import '../error_boundary.dart';

/// Everything a version mutation needs. Shared by the three use cases so
/// the composition root wires one bundle, not nine constructor arguments.
final class VersionServices {
  const VersionServices({
    required this.context,
    required this.entries,
    required this.blobStore,
    required this.images,
    required this.thumbnails,
    this.retention = const KeepOriginalCurrentAndNPolicy(),
  });

  final VaultContext context;
  final EntryRepository entries;
  final BlobStore blobStore;
  final ImageProcessor images;
  final ThumbnailProvider thumbnails;
  final VersionRetentionPolicy retention;
}

/// The §2.1 flow: apply ops natively, append a DERIVED version, move the
/// pointer, run retention, purge evicted binaries AFTER commit (§10.5).
final class CommitEditUseCase {
  const CommitEditUseCase(this.services);

  final VersionServices services;

  Future<Result<Asset, VaultFailure>> execute(
    AssetId assetId,
    EditRecipe recipe, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    if (recipe.isEmpty) {
      return services.entries.findAsset(assetId);
    }
    final loaded = await services.entries.findAsset(assetId);
    return loaded.asyncFlatMap((asset) async {
      final current = asset.currentVersion;
      if (current == null || current.blobId == null) {
        return Err(MissingVersion(asset.currentVersionId));
      }
      final processed = await services.blobStore
          .openRead(current.blobId!)
          .asyncFlatMap(
            (handle) => services.images.apply(
              handle,
              ops: recipe.ops,
              progress: progress,
              cancel: cancel,
            ),
          );
      return processed.asyncFlatMap((image) async {
        final ctx = services.context;
        final version = derivedVersion(
          id: ctx.ids.newEntityId(),
          assetId: asset.id,
          parentVersionId: current.id,
          seq: _nextSeq(asset),
          blobId: image.blobRef.id,
          recipe: recipe,
          meta: image.meta,
          hlc: ctx.nextHlc(),
          originDevice: ctx.deviceId,
          createdAt: ctx.now(),
        );
        final pins = await services.entries.loadPins(asset.id);
        return pins.asyncFlatMap((pinSet) async {
          // Retention sees the graph as it will be after the insert: the
          // new version is current and therefore protected (§10.5).
          final graph = VersionGraph(
            versions: [...asset.versions, version],
            currentId: version.id,
          );
          final outcome = await services.entries.commitVersion(
            VersionCommit(
              assetId: asset.id,
              version: version,
              blob: image.blobRef,
              hlc: version.createdHlc,
              now: version.createdAt,
              pinsToAdd: const [],
              pinsToRemove: const [],
              evictable: services.retention.selectEvictable(graph, pinSet),
            ),
          );
          return switch (outcome) {
            Ok(:final value) => await _afterCommit(value),
            Err(:final error) => await _discard(image.blobRef, error),
          };
        });
      });
    });
  });

  Future<Result<Asset, VaultFailure>> _afterCommit(
    CommitOutcome outcome,
  ) async {
    for (final blobId in outcome.purgableBlobIds) {
      await services.blobStore.purge(blobId);
    }
    await services.thumbnails.invalidate(outcome.asset.id);
    return Ok(outcome.asset);
  }

  Future<Result<Asset, VaultFailure>> _discard(
    BlobRef blob,
    VaultFailure because,
  ) async {
    await services.blobStore.purge(blob.id);
    return Err(because);
  }

  static int _nextSeq(Asset asset) {
    var max = -1;
    for (final version in asset.versions) {
      if (version.seq > max) {
        max = version.seq;
      }
    }
    return max + 1;
  }
}

/// Moves `current` to any version; re-materializes it first if it was
/// evicted and its recipe chain is deterministic (§10.3).
final class SwitchCurrentVersionUseCase {
  const SwitchCurrentVersionUseCase(this.services);

  final VersionServices services;

  Future<Result<Asset, VaultFailure>> execute(
    AssetId assetId,
    VersionId versionId, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    final loaded = await services.entries.findAsset(assetId);
    return loaded.asyncFlatMap((asset) async {
      final target = asset.versions.where((v) => v.id == versionId).firstOrNull;
      if (target == null) {
        return Err(MissingVersion(versionId));
      }
      if (target.id == asset.currentVersionId) {
        return Ok(asset);
      }
      if (!target.isMaterialized) {
        final rebuilt = await RematerializeVersionUseCase(
          services,
        ).execute(assetId, versionId, progress: progress, cancel: cancel);
        if (rebuilt.isErr) {
          return Err(rebuilt.errOrNull!);
        }
      }
      final ctx = services.context;
      final switched = await services.entries.setCurrentVersion(
        assetId,
        versionId,
        hlc: ctx.nextHlc(),
        now: ctx.now(),
      );
      if (switched.isOk) {
        await services.thumbnails.invalidate(assetId);
      }
      return switched;
    });
  });
}

/// Rebuilds an evicted version's bytes by replaying the recipe chain from
/// the ORIGINAL (§10.3). Fails with `VersionNotRematerializable` if any
/// step is non-deterministic.
final class RematerializeVersionUseCase {
  const RematerializeVersionUseCase(this.services);

  final VersionServices services;

  Future<Result<AssetVersion, VaultFailure>> execute(
    AssetId assetId,
    VersionId versionId, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    final loaded = await services.entries.findAsset(assetId);
    return loaded.asyncFlatMap((asset) async {
      final graph = VersionGraph(
        versions: asset.versions,
        currentId: asset.currentVersionId,
      );
      final target = graph[versionId];
      if (target == null) {
        return Err(MissingVersion(versionId));
      }
      if (target.isMaterialized) {
        return Ok(target);
      }
      if (!graph.isRematerializable(versionId)) {
        return Err(VersionNotRematerializable(versionId));
      }
      final chain = graph
          .pathFromOriginal(versionId)
          .where((v) => v.isDerived)
          .map((v) => v.recipe!.ops)
          .toList(growable: false);
      final rebuilt = await services.blobStore
          .openRead(graph.original.blobId!)
          .asyncFlatMap(
            (handle) => services.images.applyChain(
              handle,
              chain: chain,
              progress: progress,
              cancel: cancel,
            ),
          );
      return rebuilt.asyncFlatMap((image) async {
        // The rebuilt bytes must match what was evicted; a mismatch means
        // the processor is not deterministic and the row must stay evicted.
        if (image.meta.plaintextSha256 != target.meta.plaintextSha256) {
          await services.blobStore.purge(image.blobRef.id);
          return Err(VersionNotRematerializable(versionId));
        }
        final attached = await services.entries.rematerializeVersion(
          versionId,
          image.blobRef,
          now: services.context.now(),
        );
        if (attached.isErr) {
          await services.blobStore.purge(image.blobRef.id);
        }
        return attached;
      });
    });
  });
}
