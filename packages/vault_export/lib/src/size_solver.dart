/// Pipeline step 7 (§11.4): size targeting, honestly.
///
/// Compression cannot hit an exact byte count. `targetBytes` is best
/// effort and reports how close it got; `maxBytes` is a hard constraint
/// and exceeding it is a failure, never a silently returned file.
library;

import 'dart:math' as math;

import 'package:vault_domain/vault_domain.dart';

sealed class SizeOutcome {
  const SizeOutcome();
}

/// Within tolerance of the target (or under the cap, or unconstrained).
final class SizeMet extends SizeOutcome {
  const SizeMet(this.bytes);

  final int bytes;
}

/// Under the cap but outside ±[SizeSolver.tolerance] of the target.
final class SizeApproximate extends SizeOutcome {
  const SizeApproximate({required this.bytes, required this.target});

  final int bytes;
  final int target;
}

/// Even at the quality floor (and after every allowed downscale round)
/// the result exceeds `maxBytes`.
final class SizeUnattainableOutcome extends SizeOutcome {
  const SizeUnattainableOutcome({required this.bestBytes, required this.floor});

  final int bestBytes;
  final int floor;
}

/// What the solver landed on. [raster] may be a downscaled copy of the
/// input; the caller encodes it at [quality].
final class SizeSolution {
  const SizeSolution({
    required this.raster,
    required this.quality,
    required this.bytes,
    required this.outcome,
    required this.qualityFloorReached,
    required this.downscaleRounds,
    required this.probes,
  });

  final PreparedRaster raster;
  final int quality;
  final int bytes;
  final SizeOutcome outcome;
  final bool qualityFloorReached;
  final int downscaleRounds;

  /// Encode-to-count probes spent, for tests and telemetry.
  final int probes;
}

final class SizeSolver {
  const SizeSolver({
    this.defaultQuality = 85,
    this.maxProbes = 7,
    this.maxDownscaleRounds = 3,
    this.tolerance = 0.10,
  });

  final int defaultQuality;

  /// Binary-search budget per downscale round.
  final int maxProbes;

  final int maxDownscaleRounds;

  /// ±fraction of `targetBytes` that still counts as met.
  final double tolerance;

  Future<SizeSolution> solve(
    PreparedRaster input, {
    required OutputFormat format,
    required QualitySpec spec,
    CancellationToken? cancel,
  }) async {
    final target = spec.targetBytes;
    final max = spec.maxBytes;
    // The byte count we aim to stay under: the target if there is one,
    // otherwise the cap; null = no constraint at all.
    final limit = target ?? max;
    final lossy = format != OutputFormat.png;
    final floor = lossy ? spec.minQualityFloor : 100;
    final requested = spec.quality ?? defaultQuality;
    var probes = 0;

    Future<int> measure(PreparedRaster raster, int quality) {
      cancel?.throwIfCancelled();
      probes++;
      return raster.measure(format, lossy ? quality : 100);
    }

    var raster = input;
    var rounds = 0;
    while (true) {
      // ── Probe the requested quality first (§11.4 step 1). ──────────
      final first = await measure(raster, requested);
      if (limit == null) {
        return _solution(raster, requested, first, spec, floor, rounds, probes);
      }
      if (_withinTarget(first, target) || (target == null && first <= max!)) {
        return _solution(raster, requested, first, spec, floor, rounds, probes);
      }

      // ── Binary search quality (step 2), lossy formats only. ────────
      var bestQ = requested;
      var bestBytes = first;
      var haveUnder = first <= limit;
      if (lossy) {
        int lo;
        int hi;
        if (first > limit) {
          lo = floor;
          hi = requested - 1;
        } else {
          // Under target by more than the tolerance and the caller left
          // quality to us: approach the target from below.
          lo = requested + 1;
          hi = spec.quality == null ? 100 : requested;
        }
        var budget = maxProbes - 1;
        while (lo <= hi && budget > 0) {
          final mid = (lo + hi) ~/ 2;
          final bytes = await measure(raster, mid);
          budget--;
          if (bytes <= limit) {
            if (!haveUnder || bytes > bestBytes) {
              bestQ = mid;
              bestBytes = bytes;
              haveUnder = true;
            }
            if (_withinTarget(bytes, target)) {
              break;
            }
            lo = mid + 1;
          } else {
            if (!haveUnder && bytes < bestBytes) {
              bestQ = mid;
              bestBytes = bytes;
            }
            hi = mid - 1;
          }
        }
        if (!haveUnder && bestQ != floor) {
          // The search may have skipped the floor itself.
          final atFloor = await measure(raster, floor);
          if (atFloor < bestBytes) {
            bestQ = floor;
            bestBytes = atFloor;
          }
          haveUnder = atFloor <= limit;
        }
      }
      if (haveUnder) {
        return _solution(raster, bestQ, bestBytes, spec, floor, rounds, probes);
      }

      // ── Floor reached and still over: shrink or give up (step 3). ──
      if (!spec.allowDownscale || rounds >= maxDownscaleRounds) {
        if (max == null || bestBytes <= max) {
          // The cap (if any) holds; only the target was missed. Best
          // effort: return the floor result with a warning.
          return _solution(
            raster,
            bestQ,
            bestBytes,
            spec,
            floor,
            rounds,
            probes,
          );
        }
        return SizeSolution(
          raster: raster,
          quality: bestQ,
          bytes: bestBytes,
          outcome: SizeUnattainableOutcome(bestBytes: bestBytes, floor: floor),
          qualityFloorReached: lossy,
          downscaleRounds: rounds,
          probes: probes,
        );
      }
      final factor = (math.sqrt(limit / bestBytes) * 0.95).clamp(0.05, 0.95);
      raster = await raster.downscale(factor);
      rounds++;
    }
  }

  bool _withinTarget(int bytes, int? target) {
    if (target == null) {
      return false;
    }
    return (bytes - target).abs() <= target * tolerance && bytes <= target;
  }

  SizeSolution _solution(
    PreparedRaster raster,
    int quality,
    int bytes,
    QualitySpec spec,
    int floor,
    int rounds,
    int probes,
  ) {
    final target = spec.targetBytes;
    final max = spec.maxBytes;
    final SizeOutcome outcome;
    if (max != null && bytes > max) {
      outcome = SizeUnattainableOutcome(bestBytes: bytes, floor: floor);
    } else if (target != null && !_withinTarget(bytes, target)) {
      outcome = SizeApproximate(bytes: bytes, target: target);
    } else {
      outcome = SizeMet(bytes);
    }
    return SizeSolution(
      raster: raster,
      quality: quality,
      bytes: bytes,
      outcome: outcome,
      qualityFloorReached:
          floor < 100 && quality <= floor && (target != null || max != null),
      downscaleRounds: rounds,
      probes: probes,
    );
  }
}
