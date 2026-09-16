/// The one place op-log rows are appended (§9.3): the durable
/// `sync_log_ops` buffer plus the open-segment watermarks, inside the
/// caller's transaction.
///
/// Used by `EntryRepositoryImpl` (op emission on every local mutation)
/// and by `SyncStateRepositoryImpl.appendLogOp`.
library;

import 'package:drift/drift.dart';
import 'package:vault_domain/vault_domain.dart';

import '../daos/sync_dao.dart';
import '../database/app_database.dart';

/// Appends [op] to its origin device's open segment, creating the segment
/// row when none is open. MUST be called inside an outer transaction.
Future<void> appendOpRows(SyncDao sync, SyncOp op) async {
  final deviceId = op.origin;
  final hlc = op.hlc.toSortableString();
  final opJson = encodeSyncOp(op);
  final openSegment = await sync.openSegmentRow(deviceId);
  if (openSegment == null) {
    final seq = await sync.maxSegmentSeq(deviceId) + 1;
    await sync.insertSegmentRow(
      SyncLogSegmentsCompanion.insert(
        deviceId: deviceId,
        seq: seq,
        remoteName: segmentRemoteName(deviceId, seq),
        opCount: const Value(1),
        hlcLow: Value(hlc),
        hlcHigh: Value(hlc),
      ),
    );
    await sync.insertOpRow(
      SyncLogOpsCompanion.insert(
        deviceId: deviceId,
        opJson: opJson,
        hlc: hlc,
        seq: seq,
      ),
    );
  } else {
    await sync.appendToOpenSegment(
      deviceId,
      hlcHigh: hlc,
      opCount: openSegment.opCount + 1,
    );
    await sync.insertOpRow(
      SyncLogOpsCompanion.insert(
        deviceId: deviceId,
        opJson: opJson,
        hlc: hlc,
        seq: openSegment.seq,
      ),
    );
  }
}

/// `l_<devShort>_<seq7>.bin` (§9.2: opaque names, no semantics).
String segmentRemoteName(DeviceId deviceId, int seq) {
  final short = deviceId.length <= 8 ? deviceId : deviceId.substring(0, 8);
  return 'l_${short}_${seq.toString().padLeft(7, '0')}.bin';
}
