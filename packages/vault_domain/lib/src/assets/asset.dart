/// `Asset`: one visual unit inside an entry (§5.1).
///
/// The current version is a *pointer on the asset*, never on the entry —
/// that is what makes ID front/back and N-page documents work (M7).
library;

import '../ids.dart';
import '../sync/hlc.dart';
import '../versions/asset_version.dart';
import 'asset_role.dart';

final class Asset {
  const Asset({
    required this.id,
    required this.entryId,
    required this.role,
    required this.ordinal,
    required this.currentVersionId,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedHlc,
    required this.originDevice,
    required this.versions,
    this.deletedAt,
    this.hasOpenConflict = false,
  });

  final AssetId id;
  final EntryId entryId;
  final AssetRole role;

  /// Meaningful only for `DOCUMENT` pages; 0 otherwise.
  final int ordinal;

  /// Points at a materialized version of THIS asset (invariant I3).
  final VersionId currentVersionId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final Hlc updatedHlc;
  final DeviceId originDevice;
  final DateTime? deletedAt;

  /// True when this asset has an unresolved `ASSET_CURRENT` conflict.
  final bool hasOpenConflict;

  final List<AssetVersion> versions;

  bool get isLive => deletedAt == null;

  AssetVersion? get currentVersion {
    for (final version in versions) {
      if (version.id == currentVersionId) {
        return version;
      }
    }
    return null;
  }

  /// Live versions in descending `seq` order.
  List<AssetVersion> get versionHistory {
    final live =
        versions
            .where((AssetVersion v) => v.blobId != null)
            .toList(growable: false)
          ..sort((AssetVersion a, AssetVersion b) => b.seq.compareTo(a.seq));
    return live;
  }

  Asset copyWith({
    int? ordinal,
    VersionId? currentVersionId,
    DateTime? updatedAt,
    Hlc? updatedHlc,
    DateTime? deletedAt,
    bool? hasOpenConflict,
    List<AssetVersion>? versions,
  }) => Asset(
    id: id,
    entryId: entryId,
    role: role,
    ordinal: ordinal ?? this.ordinal,
    currentVersionId: currentVersionId ?? this.currentVersionId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    originDevice: originDevice,
    deletedAt: deletedAt ?? this.deletedAt,
    hasOpenConflict: hasOpenConflict ?? this.hasOpenConflict,
    versions: versions ?? this.versions,
  );

  @override
  bool operator ==(Object other) =>
      other is Asset &&
      other.id == id &&
      other.role == role &&
      other.ordinal == ordinal &&
      other.currentVersionId == currentVersionId &&
      other.deletedAt == deletedAt &&
      other.hasOpenConflict == hasOpenConflict &&
      other.updatedHlc == updatedHlc;

  @override
  int get hashCode => Object.hash(id, currentVersionId, updatedHlc);
}

/// Pure page-ordering helpers for `DOCUMENT` entries (invariant I7).
extension DocumentPageOrder on List<Asset> {
  bool get hasContiguousOrdinals {
    final pages = [...this]
      ..sort((Asset a, Asset b) => a.ordinal.compareTo(b.ordinal));
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].ordinal != i) {
        return false;
      }
    }
    return true;
  }

  /// Reorders pages to match [orderedIds]. Every id must be present exactly
  /// once; ordinals are reassigned to `0..n-1`.
  List<Asset> reorderTo(List<AssetId> orderedIds) {
    if (orderedIds.length != length) {
      throw ArgumentError(
        'Reorder list length ${orderedIds.length} != page count $length',
      );
    }
    final byId = {for (final page in this) page.id: page};
    final ordered = <Asset>[];
    for (final id in orderedIds) {
      final page = byId.remove(id);
      if (page == null) {
        throw ArgumentError('Unknown or duplicate page id $id');
      }
      ordered.add(page.copyWith(ordinal: ordered.length));
    }
    return ordered;
  }
}
