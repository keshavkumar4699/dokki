/// `SyncController` (§5.5, §9): the application-layer owner of sync
/// cycles. Implements `SyncQueuePort` so persistence can wake it after
/// every commit without ever calling the engine (§3 rule 3).
///
/// Kicks are debounced: a burst of edits produces one cycle, not forty.
/// A cycle is never overlapped; a kick that lands mid-cycle is remembered
/// and runs right after.
library;

import 'dart:async';

import 'package:vault_domain/vault_domain.dart';

import '../context/vault_context.dart';

/// Coarse status for UI surfaces (last cycle, pending work, conflicts).
final class SyncStatus {
  const SyncStatus({
    required this.enabled,
    required this.running,
    required this.pendingOps,
    required this.openConflicts,
    this.lastCycleAt,
    this.lastError,
  });

  final bool enabled;
  final bool running;
  final int pendingOps;
  final int openConflicts;
  final DateTime? lastCycleAt;
  final VaultFailure? lastError;
}

final class SyncController implements SyncQueuePort {
  SyncController({
    required this.runner,
    required this.syncState,
    required this.context,
    this.debounce = const Duration(seconds: 5),
  });

  final SyncRunner runner;
  final SyncStateRepository syncState;
  final VaultContext context;
  final Duration debounce;

  final _status = StreamController<SyncStatus>.broadcast();
  Timer? _scheduled;
  bool _running = false;
  bool _kickDuringRun = false;
  bool _paused = false;
  DateTime? _lastCycleAt;
  VaultFailure? _lastError;

  // ── Status ─────────────────────────────────────────────────────────────

  Stream<SyncStatus> watchStatus() async* {
    yield await _snapshot();
    yield* _status.stream;
  }

  Future<SyncStatus> _snapshot() async {
    final pending = (await syncState.pendingOps()).getOrElse((_) => const []);
    final conflicts = (await syncState.openConflicts()).getOrElse(
      (_) => const [],
    );
    return SyncStatus(
      enabled: true,
      running: _running,
      pendingOps: pending.length,
      openConflicts: conflicts.length,
      lastCycleAt: _lastCycleAt,
      lastError: _lastError,
    );
  }

  Future<void> _emit() async => _status.add(await _snapshot());

  // ── Cycles ─────────────────────────────────────────────────────────────

  /// Runs one full cycle now. Concurrent callers share the in-flight run.
  Future<Result<SyncCycleOutcome, VaultFailure>> syncNow() async {
    if (_running) {
      _kickDuringRun = true;
      return const Err(SyncTransportFailure());
    }
    _running = true;
    _scheduled?.cancel();
    _scheduled = null;
    await _emit();
    final report = await runner.syncNow();
    _running = false;
    report.fold((outcome) {
      _lastCycleAt = context.now();
      _lastError = null;
      if (outcome == SyncCycleOutcome.paused) {
        // The cloud asked for a back-off: hold kicks for a beat (§9.7).
        unawaited(pause(const Duration(minutes: 1)));
      }
    }, (f) => _lastError = f);
    await _emit();
    if (_kickDuringRun && !_paused) {
      _kickDuringRun = false;
      _schedule();
    }
    return report;
  }

  void _schedule() {
    _scheduled?.cancel();
    _scheduled = Timer(debounce, () => unawaited(syncNow()));
  }

  // ── SyncQueuePort ──────────────────────────────────────────────────────

  /// Persistence calls this after every commit (§10.5). Debounced; never
  /// throws; safe from any isolate boundary.
  @override
  Future<Result<void, VaultFailure>> kick() async {
    if (_paused) {
      return const Ok(null);
    }
    if (_running) {
      _kickDuringRun = true;
      return const Ok(null);
    }
    _schedule();
    return const Ok(null);
  }

  @override
  Future<Result<int, VaultFailure>> pendingCount() =>
      syncState.pendingOps().map((ops) => ops.length);

  /// Pauses the queue (rate limit, auth failure). Kicks are ignored
  /// until [resume].
  @override
  Future<Result<void, VaultFailure>> pause(Duration until) async {
    _paused = true;
    _scheduled?.cancel();
    Timer(until, resume);
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> resume() async {
    _paused = false;
    _schedule();
    return const Ok(null);
  }

  Future<void> dispose() async {
    _scheduled?.cancel();
    await _status.close();
  }
}
