/// `VaultEntry`: the aggregate root (§5.1).
///
/// All five entry types share this one shape; per-type rules live in
/// `EntryTypeSpec`, not here.
library;

import '../assets/asset.dart';
import '../ids.dart';
import '../sync/hlc.dart';
import 'entry_type.dart';

final class VaultEntry {
  const VaultEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.note,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedHlc,
    required this.originDevice,
    required this.assets,
    this.deletedAt,
    this.hasOpenConflict = false,
  });

  final EntryId id;
  final EntryType type;

  /// Plaintext at the domain layer; the persistence layer seals it under
  /// `K_meta` (§6).
  final String? title;

  final String? note;
  final List<String> tags;
  final DateTime createdAt;

  /// Wall-clock, display only. Causality decisions use [updatedHlc].
  final DateTime updatedAt;

  final Hlc updatedHlc;
  final DeviceId originDevice;
  final DateTime? deletedAt;

  /// True when this entry has an unresolved sync conflict (§9.5).
  final bool hasOpenConflict;

  final List<Asset> assets;

  bool get isDeleted => deletedAt != null;

  bool get isLive => !isDeleted;

  Iterable<Asset> get liveAssets => assets.where((Asset asset) => asset.isLive);

  VaultEntry copyWith({
    String? title,
    String? note,
    List<String>? tags,
    DateTime? updatedAt,
    Hlc? updatedHlc,
    DateTime? deletedAt,
    bool? hasOpenConflict,
    List<Asset>? assets,
  }) => VaultEntry(
    id: id,
    type: type,
    title: title ?? this.title,
    note: note ?? this.note,
    tags: tags ?? this.tags,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedHlc: updatedHlc ?? this.updatedHlc,
    originDevice: originDevice,
    deletedAt: deletedAt ?? this.deletedAt,
    hasOpenConflict: hasOpenConflict ?? this.hasOpenConflict,
    assets: assets ?? this.assets,
  );

  @override
  bool operator ==(Object other) =>
      other is VaultEntry &&
      other.id == id &&
      other.type == type &&
      other.title == title &&
      other.note == note &&
      other.updatedHlc == updatedHlc &&
      other.deletedAt == deletedAt &&
      other.assets.length == assets.length &&
      _sameAssets(other.assets);

  bool _sameAssets(List<Asset> other) {
    for (var i = 0; i < assets.length; i++) {
      if (assets[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, updatedHlc, deletedAt);
}

/// A lightweight projection for list screens — no asset graph, no heavy
/// payloads.
final class VaultEntrySummary {
  const VaultEntrySummary({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.assetCount,
    required this.hasOpenConflict,
    required this.coverVersionId,
  });

  final EntryId id;
  final EntryType type;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int assetCount;
  final bool hasOpenConflict;

  /// The current version of the first live asset (lowest ordinal), so a
  /// list can show a thumbnail without loading the aggregate. `null` only
  /// for an entry whose every asset is deleted.
  final VersionId? coverVersionId;
}
