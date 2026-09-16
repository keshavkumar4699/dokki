/// `SyncEngine`: one full sync cycle (§9.3–§9.8).
///
/// ```
/// seal due local segment → drain uploads → list remote segments
///   → fetch + register new ones → replay them in order → mark applied
///   → enqueue blob downloads → drain again
/// ```
///
/// The engine moves ciphertext exclusively: it never needs the master
/// key, which is why the whole cycle can run in a background WorkManager
/// job without the user present (§7.2, §9.7).
library;

import 'dart:convert';

import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';
import 'merge_reducer.dart';
import 'op_codec.dart';
import 'segment_sealer.dart';
import 'sync_executor.dart';

/// The outcome of one cycle, for status surfaces.
final class SyncCycleReport {
  const SyncCycleReport({
    required this.sealedSegment,
    required this.uploads,
    required this.downloads,
    required this.segmentsApplied,
    required this.conflictsRaised,
    required this.paused,
  });

  final bool sealedSegment;
  final int uploads;
  final int downloads;
  final int segmentsApplied;
  final int conflictsRaised;
  final bool paused;
}

final class SyncEngine {
  const SyncEngine({
    required this.deviceId,
    required this.syncState,
    required this.apply,
    required this.blobStore,
    required this.cloud,
    required this.crypto,
    required this.ids,
    required this.clock,
    required this.random,
    this.retry = const RetryPolicy(),
  });

  final DeviceId deviceId;
  final SyncStateRepository syncState;
  final SyncApplyPort apply;
  final BlobStore blobStore;
  final CloudProvider cloud;
  final CryptoEngine crypto;
  final IdGenerator ids;
  final Clock clock;
  final RandomSource random;
  final RetryPolicy retry;

  static const _logsPrefix = 'v1/logs/';
  static const _blobsPrefix = 'v1/blobs/';

  /// Our device id shortened the same way segment names shorten it (§9.2).
  String get _deviceShort =>
      deviceId.length <= 8 ? deviceId : deviceId.substring(0, 8);

  /// Runs one full cycle. A rate-limit or auth failure ends the cycle
  /// early but is not an error of the cycle itself — the queue just
  /// resumes on the next kick.
  Future<Result<SyncCycleReport, VaultFailure>> syncNow({
    CancellationToken? cancel,
  }) => guardSync('syncNow', () async {
    final sealer = SegmentSealer(
      syncState: syncState,
      blobStore: blobStore,
      clock: clock,
    );
    final executor = SyncExecutor(
      syncState: syncState,
      cloud: cloud,
      blobStore: blobStore,
      retry: retry,
      clock: clock,
      random: random,
    );

    final sealed = unwrapSync(await sealer.sealIfDue(deviceId)) != null;
    final up = unwrapSync(await executor.drain(cancel: cancel));
    if (up.paused) {
      return SyncCycleReport(
        sealedSegment: sealed,
        uploads: up.completed,
        downloads: 0,
        segmentsApplied: 0,
        conflictsRaised: 0,
        paused: true,
      );
    }

    final applied = await _fetchAndReplay(cancel);
    final report = applied.$1;
    final downloadsQueued = applied.$2;
    final down = downloadsQueued
        ? unwrapSync(await executor.drain(cancel: cancel))
        : const DrainReport(completed: 0, rescheduled: 0, paused: false);

    unwrapSync(
      await syncState.updateDeviceCursor(
        id: deviceId,
        lastSeenHlc: null,
        lastSyncedAt: clock.now(),
      ),
    );
    return SyncCycleReport(
      sealedSegment: sealed,
      uploads: up.completed,
      downloads: down.completed,
      segmentsApplied: report.segmentsApplied,
      conflictsRaised: report.conflictsRaised,
      paused: down.paused,
    );
  });

  /// Lists remote log segments, downloads the unknown ones, and replays
  /// them in (deviceId, seq) order — the order that keeps every device's
  /// replay deterministic (§9.3).
  Future<(MergeReport, bool)> _fetchAndReplay(CancellationToken? cancel) async {
    final listed = await cloud.list(namePrefix: _logsPrefix);
    if (listed.isErr) {
      return (const MergeReport(0, 0), false);
    }
    var downloadsQueued = false;
    for (final remote in listed.okOrNull!) {
      cancel?.throwIfCancelled();
      final parsed = _parseSegmentName(remote.name);
      if (parsed == null || parsed.deviceIdShort == _deviceShort) {
        continue; // our own segments are local already
      }
      final lastSeq = unwrapSync(
        await syncState.lastAppliedSeq(parsed.deviceIdShort),
      );
      if (parsed.seq <= lastSeq) {
        continue; // T13: refuse to go backwards
      }
      final got = await cloud.get(remote.remoteId);
      if (got.isErr) {
        continue; // a vanished segment skips this round, not the cycle
      }
      // No hash check against the listing here: the provider's checksum
      // is advisory (§9.2); the authoritative integrity check is the
      // envelope's AEAD verification at replay time (T12).
      final blobId = 'seg-${parsed.deviceIdShort}-${parsed.seq}';
      final stored = await blobStore.writeSealed(
        blobId,
        got.okOrNull!,
        storageClass: StorageClass.syncLog,
        expectedCiphertextSha256: '',
        cancel: cancel,
      );
      if (stored.isErr) {
        continue;
      }
      unwrapSync(
        await syncState.upsertRemoteSegment(
          LogSegmentRecord(
            deviceId: parsed.deviceIdShort,
            seq: parsed.seq,
            remoteName: remote.name,
            remoteId: remote.remoteId,
            blobId: blobId,
            opCount: 0,
            sealedAt: remote.modifiedAt,
            uploadedAt: remote.modifiedAt,
          ),
        ),
      );
    }
    // Replay ALL unapplied segments in deterministic order, not just the
    // ones fetched now — an earlier interrupted cycle may have left some.
    final pending = unwrapSync(await syncState.unappliedSegments());
    final reducer = MergeReducer(
      apply: apply,
      syncState: syncState,
      ids: ids,
      clock: clock,
    );
    var appliedCount = 0;
    var conflictCount = 0;
    for (final segment in pending) {
      cancel?.throwIfCancelled();
      final payload = await _readSegmentPayload(segment, cancel);
      if (payload == null) {
        continue;
      }
      final report = unwrapSync(await reducer.replay(payload.ops));
      conflictCount += report.conflictsRaised;
      unwrapSync(
        await syncState.markSegmentApplied(segment, now: clock.now()),
      );
      unwrapSync(
        await syncState.setLastAppliedSeq(
          segment.deviceId,
          segment.seq,
          hlc: payload.ops.isEmpty
              ? Hlc(0, 0, deviceId)
              : payload.ops.last.hlc,
        ),
      );
      appliedCount++;
      // Queue downloads for blobs the merge registered as REMOTE_ONLY.
      for (final op in payload.ops) {
        if (op is AddVersionOp && op.blobId != null) {
          unwrapSync(
            await syncState.enqueueDownloadBlob(
              blobId: op.blobId!,
              remoteName: '$_blobsPrefix${op.blobId}.bin',
              idempotencyKey: 'download:${op.blobId}',
              priority: 100,
              now: clock.now(),
            ),
          );
          downloadsQueued = true;
        }
      }
    }
    return (MergeReport(appliedCount, conflictCount), downloadsQueued);
  }

  /// Decrypts a segment blob and parses its payload.
  Future<SegmentPayload?> _readSegmentPayload(
    LogSegmentRecord segment,
    CancellationToken? cancel,
  ) async {
    final blobId = segment.blobId;
    if (blobId == null) {
      return null;
    }
    final bytes = <int>[];
    final opened = await blobStore.openRead(blobId);
    if (opened.isErr) {
      return null;
    }
    final stream = crypto.openStream(
      blobStore.ciphertextStream(opened.okOrNull!)!,
      expectedPurpose: EnvelopePurpose.logSegment,
    );
    await for (final chunk in stream) {
      cancel?.throwIfCancelled();
      bytes.addAll(chunk);
    }
    return decodeSegmentPayload(utf8.decode(bytes));
  }

  /// `l_<devShort>_<seq7>.bin` → (deviceShort, seq) (§9.2 opaque names).
  ({DeviceId deviceIdShort, int seq})? _parseSegmentName(String name) {
    final match = RegExp(r'^l_([A-Za-z0-9]+)_(\d+)\.bin$').firstMatch(name);
    if (match == null) {
      return null;
    }
    return (deviceIdShort: match[1]!, seq: int.tryParse(match[2]!) ?? 0);
  }
}

/// What the fetch+replay phase did.
final class MergeReport {
  const MergeReport(this.segmentsApplied, this.conflictsRaised);

  final int segmentsApplied;
  final int conflictsRaised;
}

/// Adapts the engine to the domain's `SyncRunner` port, so the
/// application layer can drive cycles without importing this package
/// (§3).
final class SyncEngineRunner implements SyncRunner {
  const SyncEngineRunner(this._engine);

  final SyncEngine _engine;

  @override
  Future<Result<SyncCycleOutcome, VaultFailure>> syncNow({
    CancellationToken? cancel,
  }) => _engine.syncNow(cancel: cancel).map(
    (report) =>
        report.paused ? SyncCycleOutcome.paused : SyncCycleOutcome.done,
  );
}
