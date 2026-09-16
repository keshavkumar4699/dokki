/// Conflict records (§9.5).
///
/// The `conflicts` table and `ResolveConflictOp` exist from day one even
/// though the manual-resolution UI comes later: the data model must record
/// conflicts or the eventual UI has nothing to show.
library;

import '../ids.dart';
import 'hlc.dart';

enum ConflictKind {
  assetCurrent('ASSET_CURRENT'),
  entryField('ENTRY_FIELD'),
  assetSet('ASSET_SET'),
  pageOrder('PAGE_ORDER'),
  tombstoneVsEdit('TOMBSTONE_VS_EDIT');

  const ConflictKind(this.dbValue);

  final String dbValue;

  static ConflictKind? fromDbValue(String value) {
    for (final kind in ConflictKind.values) {
      if (kind.dbValue == value) {
        return kind;
      }
    }
    return null;
  }
}

enum ConflictResolution {
  keepLocal,
  keepRemote,
  keepBoth,
  auto;

  static ConflictResolution? fromName(String name) {
    for (final r in ConflictResolution.values) {
      if (r.name == name) {
        return r;
      }
    }
    return null;
  }
}

/// Which side provisionally wins while the conflict is open.
enum ConflictWinner { local, remote }

final class Conflict {
  const Conflict({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.localStateJson,
    required this.remoteStateJson,
    required this.provisionalWinner,
    required this.detectedAt,
    required this.detectedHlc,
    this.resolvedAt,
    this.resolution,
    this.resolvedByDevice,
  });

  final ConflictId id;
  final ConflictKind kind;
  final String entityId;
  final String localStateJson;
  final String remoteStateJson;
  final ConflictWinner provisionalWinner;
  final DateTime detectedAt;
  final Hlc detectedHlc;
  final DateTime? resolvedAt;
  final ConflictResolution? resolution;
  final DeviceId? resolvedByDevice;

  bool get isOpen => resolvedAt == null;

  Conflict resolve(
    ConflictResolution resolution, {
    required DateTime at,
    required DeviceId byDevice,
  }) => Conflict(
    id: id,
    kind: kind,
    entityId: entityId,
    localStateJson: localStateJson,
    remoteStateJson: remoteStateJson,
    provisionalWinner: provisionalWinner,
    detectedAt: detectedAt,
    detectedHlc: detectedHlc,
    resolvedAt: at,
    resolution: resolution,
    resolvedByDevice: byDevice,
  );
}
