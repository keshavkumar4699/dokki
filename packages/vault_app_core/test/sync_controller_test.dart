/// `SyncController` tests: debounce, overlap protection, pause/resume,
/// and the pending/conflict status surface.
library;

import 'package:test/test.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'support/fakes.dart';

final class _FakeRunner implements SyncRunner {
  int calls = 0;
  SyncCycleOutcome outcome = SyncCycleOutcome.done;
  VaultFailure? failure;
  Duration delay = Duration.zero;

  @override
  Future<Result<SyncCycleOutcome, VaultFailure>> syncNow({
    CancellationToken? cancel,
  }) async {
    calls++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final failure = this.failure;
    if (failure != null) {
      return Err(failure);
    }
    return Ok(outcome);
  }
}

final class _FakeSyncState implements SyncStateRepository {
  int pending = 0;
  List<Conflict> conflicts = [];

  @override
  Future<Result<List<SyncQueueItem>, VaultFailure>> pendingOps() async =>
      Ok([
        for (var i = 0; i < pending; i++)
          SyncQueueItem(
            id: i,
            opType: SyncQueueOpType.uploadBlob,
            targetKind: 'BLOB',
            targetId: 'b$i',
            idempotencyKey: 'k$i',
            priority: 100,
            state: SyncQueueState.pending,
            attempts: 0,
            nextAttemptAt: DateTime.utc(2026),
            createdAt: DateTime.utc(2026),
          ),
      ]);

  @override
  Future<Result<List<Conflict>, VaultFailure>> openConflicts() async =>
      Ok(conflicts);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _FakeRunner runner;
  late _FakeSyncState syncState;
  late SyncController controller;

  setUp(() {
    runner = _FakeRunner();
    syncState = _FakeSyncState();
    controller = SyncController(
      runner: runner,
      syncState: syncState,
      context: testContext(),
      debounce: const Duration(milliseconds: 20),
    );
  });

  tearDown(() => controller.dispose());

  test('a burst of kicks produces one debounced cycle', () async {
    await controller.kick();
    await controller.kick();
    await controller.kick();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(runner.calls, 1);
  });

  test('syncNow runs immediately and reports the outcome', () async {
    final result = await controller.syncNow();
    expect(result.isOk, isTrue);
    expect(runner.calls, 1);
  });

  test('a kick mid-cycle schedules exactly one follow-up', () async {
    runner.delay = const Duration(milliseconds: 40);
    final first = controller.syncNow();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await controller.kick();
    await first;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(runner.calls, 2);
  });

  test('a paused outcome backs the queue off', () async {
    runner.outcome = SyncCycleOutcome.paused;
    await controller.syncNow();
    await controller.kick();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(runner.calls, 1, reason: 'kick ignored while paused');
  });

  test('resume re-enables scheduling', () async {
    await controller.pause(const Duration(days: 1));
    await controller.resume();
    await controller.kick();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(runner.calls, 1);
  });

  test('status exposes pending ops, conflicts and the last error', () async {
    syncState
      ..pending = 3
      ..conflicts = [
        Conflict(
          id: 'ASSET_CURRENT:a1',
          kind: ConflictKind.assetCurrent,
          entityId: 'a1',
          localStateJson: '{}',
          remoteStateJson: '{}',
          provisionalWinner: ConflictWinner.local,
          detectedAt: DateTime.utc(2026),
          detectedHlc: const Hlc(1, 0, 'd'),
        ),
      ];
    runner.failure = const SyncTransportFailure(httpStatus: 500);
    await controller.syncNow();
    final status = await controller.watchStatus().first.timeout(
      const Duration(seconds: 5),
    );
    expect(status.pendingOps, 3);
    expect(status.openConflicts, 1);
    expect(status.lastError, isA<SyncTransportFailure>());
  });

  test('pendingCount reads the queue length', () async {
    syncState.pending = 7;
    expect((await controller.pendingCount()).okOrNull, 7);
  });
}
