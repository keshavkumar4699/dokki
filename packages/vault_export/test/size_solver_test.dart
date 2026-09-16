/// The size solver against a synthetic encoder with a known curve
/// (§11.4, §13.7): every branch of the contract, without a real codec.
library;

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_export/vault_export.dart';

import 'support/fakes.dart';

void main() {
  const solver = SizeSolver();
  // 1000 × 800 → 800 000 px; JPEG bytes = 800 000 × (0.02 + 0.0098 q):
  // q85 = 682 400, q40 (floor) = 329 600, q100 = 800 000.
  CurveRaster raster() => CurveRaster(width: 1000, height: 800);

  test(
    'no constraint: one probe at the requested (default 85) quality',
    () async {
      final r = raster();
      final s = await solver.solve(
        r,
        format: OutputFormat.jpeg,
        spec: const QualitySpec(),
      );
      expect(s.quality, 85);
      expect(s.bytes, 682400);
      expect(s.outcome, isA<SizeMet>());
      expect(s.probes, 1);
      expect(r.probedQualities, [85]);
    },
  );

  test('target within tolerance at the first probe is met', () async {
    final s = await solver.solve(
      raster(),
      format: OutputFormat.jpeg,
      spec: const QualitySpec(targetBytes: 700000),
    );
    expect(s.quality, 85);
    expect(s.outcome, isA<SizeMet>());
    expect(s.probes, 1);
  });

  test('target below the default quality is found by searching down', () async {
    final s = await solver.solve(
      raster(),
      format: OutputFormat.jpeg,
      spec: const QualitySpec(targetBytes: 400000),
    );
    // q48 → 392 320 (within 10 % under 400 000).
    expect(s.bytes, lessThanOrEqualTo(400000));
    expect(s.bytes, greaterThanOrEqualTo(360000));
    expect(s.outcome, isA<SizeMet>());
    expect(s.probes, lessThanOrEqualTo(7));
    expect(s.downscaleRounds, 0);
  });

  test('unspecified quality approaches a large target from below', () async {
    final s = await solver.solve(
      raster(),
      format: OutputFormat.jpeg,
      spec: const QualitySpec(targetBytes: 790000),
    );
    expect(s.quality, greaterThan(85));
    expect(s.bytes, lessThanOrEqualTo(790000));
    expect(s.bytes, greaterThanOrEqualTo(711000));
    expect(s.outcome, isA<SizeMet>());
  });

  test('an explicit quality is never exceeded to chase a target', () async {
    final s = await solver.solve(
      raster(),
      format: OutputFormat.jpeg,
      spec: const QualitySpec(quality: 60, targetBytes: 790000),
    );
    expect(s.quality, 60);
    expect(s.outcome, isA<SizeApproximate>());
  });

  test('maxBytes under the floor without downscale is unattainable', () async {
    final r = raster();
    final s = await solver.solve(
      r,
      format: OutputFormat.jpeg,
      spec: const QualitySpec(maxBytes: 300000, allowDownscale: false),
    );
    expect(s.outcome, isA<SizeUnattainableOutcome>());
    final outcome = s.outcome as SizeUnattainableOutcome;
    expect(outcome.floor, 40);
    expect(outcome.bestBytes, 329600);
    expect(s.qualityFloorReached, isTrue);
    expect(r.probedQualities, contains(40));
  });

  test(
    'maxBytes under the floor with downscale shrinks until it fits',
    () async {
      final s = await solver.solve(
        raster(),
        format: OutputFormat.jpeg,
        spec: const QualitySpec(maxBytes: 300000),
      );
      expect(s.outcome, isA<SizeMet>());
      expect(s.bytes, lessThanOrEqualTo(300000));
      expect(s.downscaleRounds, greaterThanOrEqualTo(1));
      expect(s.raster.width, lessThan(1000));
    },
  );

  test(
    'a missed target under an honoured cap is approximate, not failed',
    () async {
      final s = await solver.solve(
        raster(),
        format: OutputFormat.jpeg,
        spec: const QualitySpec(
          targetBytes: 300000,
          maxBytes: 700000,
          allowDownscale: false,
        ),
      );
      expect(s.outcome, isA<SizeApproximate>());
      expect(s.bytes, lessThanOrEqualTo(700000));
      expect(s.quality, 40);
      expect(s.qualityFloorReached, isTrue);
    },
  );

  test(
    'png ignores quality: a target it cannot meet without shrinking',
    () async {
      final r = raster();
      final s = await solver.solve(
        r,
        format: OutputFormat.png,
        spec: const QualitySpec(targetBytes: 500000, allowDownscale: false),
      );
      expect(r.probedQualities, [100]);
      expect(s.outcome, isA<SizeApproximate>());
      expect(s.qualityFloorReached, isFalse);
    },
  );

  test('png with a cap and downscale shrinks to fit', () async {
    final s = await solver.solve(
      raster(),
      format: OutputFormat.png,
      spec: const QualitySpec(maxBytes: 500000),
    );
    expect(s.outcome, isA<SizeMet>());
    expect(s.bytes, lessThanOrEqualTo(500000));
    expect(s.raster.width, lessThan(1000));
  });

  test('probe budget holds per round', () async {
    final r = raster();
    await solver.solve(
      r,
      format: OutputFormat.jpeg,
      spec: const QualitySpec(targetBytes: 333333, allowDownscale: false),
    );
    expect(r.probedQualities.length, lessThanOrEqualTo(8));
  });

  test('cancellation unwinds between probes', () async {
    final token = CancellationToken()..cancel();
    expect(
      () => solver.solve(
        raster(),
        format: OutputFormat.jpeg,
        spec: const QualitySpec(targetBytes: 100),
        cancel: token,
      ),
      throwsA(isA<OperationCancelledException>()),
    );
  });
}
