/// `SyncQueuePort`: the wake-up channel from persistence to the sync
/// engine (§3 rule 3, §10.5).
///
/// `vault_persistence` must never call `vault_sync` directly. It inserts
/// `sync_queue` rows inside its transactions and, AFTER commit, calls
/// [kick] on this port. `vault_sync` implements it.
library;

import '../failures/vault_failure.dart';
import '../result.dart';

enum SyncQueueOpType {
  uploadBlob('UPLOAD_BLOB'),
  downloadBlob('DOWNLOAD_BLOB'),
  appendLog('APPEND_LOG'),
  fetchLog('FETCH_LOG'),
  deleteRemote('DELETE_REMOTE'),
  verifyRemote('VERIFY_REMOTE');

  const SyncQueueOpType(this.dbValue);

  final String dbValue;
}

abstract interface class SyncQueuePort {
  /// Wake the scheduler: there is work to do. Fire-and-forget; never
  /// throws; safe to call from any isolate boundary.
  Future<Result<void, VaultFailure>> kick();

  /// Coarse pending-op count for UI badges.
  Future<Result<int, VaultFailure>> pendingCount();

  /// Pauses the whole queue (rate limit, auth failure). New kicks are
  /// ignored until [resume].
  Future<Result<void, VaultFailure>> pause(Duration until);

  Future<Result<void, VaultFailure>> resume();
}
