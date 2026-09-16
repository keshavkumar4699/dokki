/// Pipeline step 2 (§11.3) and the §11.7 "Export Again" strategy, in the
/// application layer because it re-materializes through the version use
/// cases. The user is always told which branch happened, via warnings.
library;

import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import '../versions/version_use_cases.dart';

final class ExportSourceResolverImpl implements ExportSourceResolver {
  const ExportSourceResolverImpl({
    required this.entries,
    required this.rematerialize,
  });

  final EntryRepository entries;
  final RematerializeVersionUseCase rematerialize;

  @override
  Future<Result<List<ResolvedSource>, VaultFailure>> resolve(
    ExportSource source,
  ) => guardUseCase(() async {
    switch (source) {
      case CurrentOfEntrySource(:final entryId):
        return entries.findEntry(entryId).asyncFlatMap(_currentOfEntry);
      case SingleVersionSource(:final versionId):
        return _versions([versionId]);
      case IdPairSource(:final front, :final back):
        return _versions([?front, ?back]);
      case DocumentPagesSource(:final pages):
        return _versions(pages);
    }
  });

  /// Quick export: the current version of every live asset, in the
  /// order the entry presents them (front before back, pages by ordinal).
  Future<Result<List<ResolvedSource>, VaultFailure>> _currentOfEntry(
    VaultEntry entry,
  ) async {
    final assets = entry.liveAssets.toList()
      ..sort((a, b) {
        final byRole = _roleRank(a.role).compareTo(_roleRank(b.role));
        return byRole != 0 ? byRole : a.ordinal.compareTo(b.ordinal);
      });
    final resolved = <ResolvedSource>[];
    for (final asset in assets) {
      final current = asset.currentVersion;
      if (current == null) {
        return Err(MissingVersion(asset.currentVersionId));
      }
      final one = await _resolveVersion(asset, current);
      if (one.isErr) {
        return Err(one.errOrNull!);
      }
      resolved.add(one.okOrNull!);
    }
    return Ok(resolved);
  }

  Future<Result<List<ResolvedSource>, VaultFailure>> _versions(
    List<VersionId> ids,
  ) async {
    final resolved = <ResolvedSource>[];
    for (final id in ids) {
      final version = await entries.findVersion(id);
      if (version.isErr) {
        return Err(version.errOrNull!);
      }
      final found = version.okOrNull;
      if (found == null) {
        return Err(MissingVersion(id));
      }
      final asset = await entries.findAsset(found.assetId);
      if (asset.isErr) {
        return Err(asset.errOrNull!);
      }
      final one = await _resolveVersion(asset.okOrNull!, found);
      if (one.isErr) {
        return Err(one.errOrNull!);
      }
      resolved.add(one.okOrNull!);
    }
    return Ok(resolved);
  }

  /// The §11.7 ladder for one version.
  Future<Result<ResolvedSource, VaultFailure>> _resolveVersion(
    Asset asset,
    AssetVersion version,
  ) async {
    if (version.isMaterialized) {
      return Ok(_from(asset, version, requested: version.id));
    }
    final graph = VersionGraph(
      versions: asset.versions,
      currentId: asset.currentVersionId,
    );
    if (graph.isRematerializable(version.id)) {
      final rebuilt = await rematerialize.execute(asset.id, version.id);
      if (rebuilt.isOk && rebuilt.okOrNull!.isMaterialized) {
        return Ok(
          _from(
            asset,
            rebuilt.okOrNull!,
            requested: version.id,
            warnings: const [ExportWarning.sourceEvicted],
          ),
        );
      }
      // A rebuild that does not reproduce the bytes is treated like a
      // non-deterministic chain: fall through to the current version.
    }
    final current = asset.currentVersion;
    if (current == null || !current.isMaterialized) {
      return Err(MissingVersion(version.id));
    }
    return Ok(
      _from(
        asset,
        current,
        requested: version.id,
        warnings: const [ExportWarning.sourceChanged],
      ),
    );
  }

  static ResolvedSource _from(
    Asset asset,
    AssetVersion version, {
    required VersionId requested,
    List<ExportWarning> warnings = const [],
  }) => ResolvedSource(
    entryId: asset.entryId,
    assetId: asset.id,
    requestedVersionId: requested,
    versionId: version.id,
    blobId: version.blobId!,
    meta: version.meta,
    warnings: warnings,
  );

  static int _roleRank(AssetRole role) => switch (role) {
    AssetRole.primary => 0,
    AssetRole.idFront => 0,
    AssetRole.idBack => 1,
    AssetRole.page => 2,
  };
}
