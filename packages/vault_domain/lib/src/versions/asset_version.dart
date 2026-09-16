/// `AssetVersion`: one immutable version of one asset's bytes (§5.3).
library;

import '../ids.dart';
import '../imaging/image_meta.dart';
import '../sync/hlc.dart';
import 'edit_recipe.dart';
import 'version_kind.dart';

final class AssetVersion {
  const AssetVersion({
    required this.id,
    required this.assetId,
    required this.parentVersionId,
    required this.kind,
    required this.seq,
    required this.blobId,
    required this.recipe,
    required this.recipeDeterministic,
    required this.meta,
    required this.createdAt,
    required this.createdHlc,
    required this.originDevice,
    this.evictedAt,
    this.isPinned = false,
  });

  final VersionId id;
  final AssetId assetId;

  /// `null` iff [kind] is [VersionKind.original] (invariant I4).
  final VersionId? parentVersionId;

  final VersionKind kind;

  /// Monotonic per asset, gap-tolerant.
  final int seq;

  /// `null` ⇒ binary evicted; the row (and recipe) is retained (I2, §10.3).
  final BlobId? blobId;

  /// Ops applied to the parent; `null` for originals.
  final EditRecipe? recipe;

  /// False for ML ops ⇒ cannot re-materialize.
  final bool recipeDeterministic;

  final ImageMeta meta;

  final DateTime createdAt;

  final Hlc createdHlc;

  final DeviceId originDevice;

  final DateTime? evictedAt;

  /// Derived from `version_pins` at load time; not persisted on the row.
  final bool isPinned;

  bool get isOriginal => kind == VersionKind.original;

  bool get isDerived => kind == VersionKind.derived;

  bool get isMaterialized => blobId != null;

  bool get isEvicted => evictedAt != null || blobId == null;

  bool get canRematerialize =>
      isEvicted && recipeDeterministic && recipe != null && !isOriginal;

  /// Sentinel: distinguishes "leave unchanged" from "set to null" in
  /// [copyWith]. Soft eviction MUST be able to null `blobId` (§10.3), and
  /// the plain `??` idiom cannot express that.
  static const Object _unset = Object();

  /// Pass `null` explicitly for [blobId] or [evictedAt] to clear them.
  AssetVersion copyWith({
    Object? blobId = _unset,
    Object? evictedAt = _unset,
    bool? isPinned,
  }) => AssetVersion(
    id: id,
    assetId: assetId,
    parentVersionId: parentVersionId,
    kind: kind,
    seq: seq,
    blobId: identical(blobId, _unset) ? this.blobId : blobId as BlobId?,
    recipe: recipe,
    recipeDeterministic: recipeDeterministic,
    meta: meta,
    createdAt: createdAt,
    createdHlc: createdHlc,
    originDevice: originDevice,
    evictedAt: identical(evictedAt, _unset)
        ? this.evictedAt
        : evictedAt as DateTime?,
    isPinned: isPinned ?? this.isPinned,
  );

  @override
  bool operator ==(Object other) =>
      other is AssetVersion &&
      other.id == id &&
      other.parentVersionId == parentVersionId &&
      other.kind == kind &&
      other.seq == seq &&
      other.blobId == blobId &&
      other.meta == meta &&
      other.createdHlc == createdHlc &&
      other.evictedAt == evictedAt;

  @override
  int get hashCode => Object.hash(id, seq, blobId, createdHlc);
}
