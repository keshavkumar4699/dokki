/// `VersionGraph`: lineage-aware view over an asset's versions (§10.1).
library;

import '../ids.dart';
import 'asset_version.dart';

final class VersionGraph {
  const VersionGraph({required this.versions, required this.currentId});

  final List<AssetVersion> versions;

  final VersionId currentId;

  AssetVersion get original {
    for (final version in versions) {
      if (version.isOriginal) {
        return version;
      }
    }
    throw StateError('No ORIGINAL version in graph (I1 violated)');
  }

  AssetVersion? get current {
    for (final version in versions) {
      if (version.id == currentId) {
        return version;
      }
    }
    return null;
  }

  AssetVersion? operator [](VersionId id) {
    for (final version in versions) {
      if (version.id == id) {
        return version;
      }
    }
    return null;
  }

  bool contains(VersionId id) => this[id] != null;

  /// The lineage chain from the original to [id], inclusive:
  /// `[original, v1, v2, ..., id]` (§10.3).
  List<AssetVersion> pathFromOriginal(VersionId id) {
    final chain = <AssetVersion>[];
    VersionId? cursor = id;
    final visited = <VersionId>{};
    while (cursor != null) {
      if (!visited.add(cursor)) {
        throw StateError('Cycle in version lineage at $cursor');
      }
      final version = this[cursor];
      if (version == null) {
        throw StateError('Version $cursor not in graph');
      }
      chain.add(version);
      cursor = version.parentVersionId;
    }
    return chain.reversed.toList(growable: false);
  }

  /// All materialized derived versions, newest `seq` first.
  List<AssetVersion> get materializedDerived => _sorted(
    versions.where((AssetVersion v) => v.isDerived && v.isMaterialized),
  );

  /// All derived versions (materialized or not), newest first.
  List<AssetVersion> get allDerived =>
      _sorted(versions.where((AssetVersion v) => v.isDerived));

  static List<AssetVersion> _sorted(Iterable<AssetVersion> source) =>
      source.toList(growable: false)
        ..sort((AssetVersion a, AssetVersion b) => b.seq.compareTo(a.seq));

  /// Whether every step from the original to [id] is deterministic —
  /// i.e. the version can be re-materialized (§10.3).
  bool isRematerializable(VersionId id) {
    final version = this[id];
    if (version == null || !version.canRematerialize) {
      return false;
    }
    return pathFromOriginal(id)
        .where((AssetVersion v) => v.isDerived)
        .every((AssetVersion v) => v.recipeDeterministic);
  }
}
