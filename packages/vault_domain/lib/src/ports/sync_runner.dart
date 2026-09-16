/// `SyncRunner`: the narrow surface the application layer drives one sync
/// cycle through (§5.5 `SyncController`). `vault_sync` implements it;
/// `vault_app_core` never imports the engine (§3).
library;

import '../failures/vault_failure.dart';
import '../result.dart';
import 'blob_store.dart' show CancellationToken;

/// How a cycle ended, at the granularity the scheduler needs.
enum SyncCycleOutcome {
  /// Everything drained and replayed.
  done,

  /// The cloud asked us to back off (429/auth): resume on the next kick
  /// or the scheduler's own cadence, not immediately (§9.7).
  paused,
}

abstract interface class SyncRunner {
  /// Runs one full cycle: seal due segments → drain uploads → fetch and
  /// replay remote segments → queue and drain downloads.
  Future<Result<SyncCycleOutcome, VaultFailure>> syncNow({
    CancellationToken? cancel,
  });
}
