/// `ExportEngineImpl`: the §11.3 pipeline, orchestrated in Dart.
///
/// Validate → resolve → (raster: decode/raster → size-solve → encode) or
/// (pdf: layout → compose) → seal → record. Steps that touch pixels go
/// through the `RasterEngine` seam; the engine itself never holds a
/// bitmap. Every outcome after resolution — success, failure or
/// cancellation — leaves an `export_records` row, because the history is
/// the product (§11.7).
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:vault_domain/vault_domain.dart';

import 'error_boundary.dart';
import 'layout_engine.dart';
import 'size_solver.dart';
import 'validation.dart';

/// Pipeline stages reported through the `ProgressSink` as `(stage, of)`.
enum ExportStage { validate, resolve, raster, solve, encode, seal, record }

final class ExportEngineImpl implements ExportEngine {
  const ExportEngineImpl({
    required this.entries,
    required this.blobStore,
    required this.raster,
    required this.resolver,
    required this.clock,
    required this.ids,
    required this.deviceId,
    this.pdf,
    this.solver = const SizeSolver(),
    this.layout = const LayoutEngine(),
    this.artifactTtl = const Duration(days: 7),
  });

  final EntryRepository entries;
  final BlobStore blobStore;
  final RasterEngine raster;
  final ExportSourceResolver resolver;

  /// `null` until Phase 6: PDF requests fail validation as unsupported.
  final PdfComposer? pdf;
  final SizeSolver solver;
  final LayoutEngine layout;
  final Clock clock;
  final IdGenerator ids;
  final DeviceId deviceId;

  /// How long a retained artifact lives before GC releases it.
  final Duration artifactTtl;

  Set<OutputFormat> get supportedFormats => {
    OutputFormat.jpeg,
    OutputFormat.png,
    if (pdf != null) OutputFormat.pdf,
  };

  @override
  Future<Result<ExportResult, VaultFailure>> run(
    ExportRequest request, {
    ProgressSink? progress,
    CancellationToken? cancel,
    bool retainArtifact = false,
  }) async {
    final startedAt = clock.now();
    final exportId = ids.newEntityId();
    void stage(ExportStage s) =>
        progress?.call(s.index, ExportStage.values.length);

    stage(ExportStage.validate);
    final validated = validateExportRequest(
      request,
      supportedFormats: supportedFormats,
    );
    if (validated.isErr) {
      return Err(validated.errOrNull!);
    }
    final plan = validated.okOrNull!.plan;

    stage(ExportStage.resolve);
    final resolved = await resolver.resolve(request.source);
    if (resolved.isErr) {
      return Err(resolved.errOrNull!);
    }
    final sources = resolved.okOrNull!;
    if (sources.isEmpty) {
      return const Err(InvalidExportDimensions('nothing to export'));
    }
    final entryId = sources.first.entryId;

    final outcome = await guardExport('run', () async {
      cancel?.throwIfCancelled();
      final warnings = <ExportWarning>{
        for (final source in sources) ...source.warnings,
      };
      if (request.format == OutputFormat.pdf) {
        return _runPdf(request, sources, warnings, progress, cancel);
      }
      if (sources.length > 1) {
        throw const ExportException(
          UnsupportedFormat('multi-image raster export; use pdf'),
        );
      }
      return _runRaster(
        request,
        plan!,
        sources.single,
        warnings,
        stage,
        cancel,
      );
    });

    stage(ExportStage.record);
    final finishedAt = clock.now();
    final duration = finishedAt.difference(startedAt);
    return switch (outcome) {
      Ok(:final value) => _recordSuccess(
        exportId,
        entryId,
        request,
        sources,
        value,
        startedAt,
        duration,
        retainArtifact,
      ),
      Err(:final error) => _recordFailure(
        exportId,
        entryId,
        request,
        sources,
        error,
        startedAt,
        duration,
      ),
    };
  }

  // ── Raster path ─────────────────────────────────────────────────────────

  Future<_Produced> _runRaster(
    ExportRequest request,
    RasterPlan plan,
    ResolvedSource source,
    Set<ExportWarning> warnings,
    void Function(ExportStage) stage,
    CancellationToken? cancel,
  ) async {
    stage(ExportStage.raster);
    final handle = _unwrap(await blobStore.openRead(source.blobId));
    final prepared = _unwrap(
      await raster.prepare(handle, plan: plan, cancel: cancel),
    );
    try {
      if (prepared.width > prepared.sourceWidth ||
          prepared.height > prepared.sourceHeight) {
        warnings.add(ExportWarning.upscaledBeyondSource);
      }
      if (plan.fit == FitMode.stretch &&
          plan.width != null &&
          plan.height != null &&
          !_sameAspect(
            prepared.sourceWidth,
            prepared.sourceHeight,
            plan.width!,
            plan.height!,
          )) {
        warnings.add(ExportWarning.aspectRatioAdjusted);
      }

      stage(ExportStage.solve);
      final solution = await solver.solve(
        prepared,
        format: request.format,
        spec: request.quality,
        cancel: cancel,
      );
      try {
        switch (solution.outcome) {
          case SizeUnattainableOutcome(:final bestBytes):
            throw ExportException(
              SizeUnattainable(bestBytes, request.quality.maxBytes!),
            );
          case SizeApproximate():
            warnings.add(ExportWarning.targetSizeMissed);
          case SizeMet():
            break;
        }
        if (solution.qualityFloorReached) {
          warnings.add(ExportWarning.qualityFloorReached);
        }

        stage(ExportStage.encode);
        cancel?.throwIfCancelled();
        final encoded = await solution.raster.encode(
          request.format,
          solution.quality,
        );

        stage(ExportStage.seal);
        final artifact = _unwrap(
          await blobStore.write(
            Stream.value(encoded.bytes),
            storageClass: StorageClass.exportArtifact,
            expectedSize: encoded.bytes.length,
            cancel: cancel,
          ),
        );
        return _Produced(
          artifact: artifact,
          width: encoded.width,
          height: encoded.height,
          pageCount: 1,
          quality: solution.quality,
          dpi: _dpiOf(request.raster),
          warnings: warnings.toList(growable: false),
        );
      } finally {
        if (!identical(solution.raster, prepared)) {
          solution.raster.dispose();
        }
      }
    } finally {
      prepared.dispose();
    }
  }

  // ── PDF path ────────────────────────────────────────────────────────────

  Future<_Produced> _runPdf(
    ExportRequest request,
    List<ResolvedSource> sources,
    Set<ExportWarning> warnings,
    ProgressSink? progress,
    CancellationToken? cancel,
  ) async {
    final composer = pdf;
    if (composer == null) {
      throw const ExportException(UnsupportedFormat('application/pdf'));
    }
    final page = request.page!;
    // Natural content sizes at the paper's scale: each image is treated as
    // a rectangle of its own aspect ratio and the layout fits it.
    final sizes = [
      for (final source in sources)
        SizeMm(source.meta.width.toDouble(), source.meta.height.toDouble()),
    ];
    final placements = layout.layout(page, sizes);
    final handles = <BlobHandle>[];
    for (final source in sources) {
      cancel?.throwIfCancelled();
      handles.add(_unwrap(await blobStore.openRead(source.blobId)));
    }

    // §11.4 PDF size targeting, honestly: binary-search JPEG quality, then
    // shrink the effective DPI in rounds. `maxBytes` is a hard constraint
    // and exceeding it fails; `targetBytes` is best effort + a warning.
    final spec = request.quality;
    final target = spec.targetBytes;
    final max = spec.maxBytes;
    final limit = target ?? max;
    final floor = spec.minQualityFloor;
    final requested = spec.quality ?? solver.defaultQuality;
    const initialDpi = 300;

    Future<List<int>> composeAt(int quality, int dpi) async {
      cancel?.throwIfCancelled();
      return _unwrap(
        await composer.compose(
          PdfComposeRequest(
            spec: page,
            placements: placements,
            images: handles,
            quality: quality,
            effectiveDpi: dpi,
            color: request.color,
          ),
          progress: progress,
          cancel: cancel,
        ),
      );
    }

    bool withinTarget(int bytes) =>
        target != null &&
        (bytes - target).abs() <= target * solver.tolerance &&
        bytes <= target;

    final List<int> accepted;
    var acceptedQ = requested;
    var acceptedDpi = initialDpi;

    if (limit == null) {
      accepted = await composeAt(requested, initialDpi);
    } else {
      var dpi = initialDpi;
      var rounds = 0;
      List<int>? chosen;
      while (chosen == null) {
        final first = await composeAt(requested, dpi);
        List<int>? under; // largest bytes ≤ limit (closest from below)
        var underQ = requested;
        var smallest = first; // smallest bytes seen this round
        var smallestQ = requested;
        if (first.length <= limit) {
          // Under the cap; if a target was set and missed by more than
          // the tolerance, that is a warning, not a search (M13).
          under = first;
        } else {
          // Binary search quality in [floor, requested - 1].
          var lo = floor;
          var hi = requested - 1;
          var probes = solver.maxProbes;
          while (lo <= hi && probes > 0) {
            final mid = (lo + hi) ~/ 2;
            final bytes = await composeAt(mid, dpi);
            probes--;
            if (bytes.length < smallest.length) {
              smallest = bytes;
              smallestQ = mid;
            }
            if (bytes.length <= limit) {
              if (under == null || bytes.length > under.length) {
                under = bytes;
                underQ = mid;
              }
              if (withinTarget(bytes.length)) {
                break;
              }
              lo = mid + 1;
            } else {
              hi = mid - 1;
            }
          }
          if (under == null && smallestQ != floor) {
            // The search may have skipped the floor itself.
            final atFloor = await composeAt(floor, dpi);
            if (atFloor.length < smallest.length) {
              smallest = atFloor;
              smallestQ = floor;
            }
            if (atFloor.length <= limit) {
              under = atFloor;
              underQ = floor;
            }
          }
        }
        if (under != null) {
          chosen = under;
          acceptedQ = underQ;
          acceptedDpi = dpi;
          if (target != null && !withinTarget(under.length)) {
            warnings.add(ExportWarning.targetSizeMissed);
          }
          if (first.length > limit && underQ <= floor) {
            warnings.add(ExportWarning.qualityFloorReached);
          }
          break;
        }
        // Nothing at this DPI fits under the limit.
        if (max == null || smallest.length <= max) {
          // Only a best-effort target was missed (or the hard cap holds
          // anyway): return the smallest attempt with a warning (M13).
          chosen = smallest;
          acceptedQ = smallestQ;
          acceptedDpi = dpi;
          warnings
            ..add(ExportWarning.targetSizeMissed)
            ..add(ExportWarning.qualityFloorReached);
          break;
        }
        if (!spec.allowDownscale || rounds >= solver.maxDownscaleRounds) {
          throw ExportException(
            SizeUnattainable(smallest.length, max),
          );
        }
        final shrink = (math.sqrt(limit / smallest.length) * 0.95)
            .clamp(0.05, 0.95);
        final nextDpi = (dpi * shrink).round();
        if (nextDpi >= dpi) {
          throw ExportException(
            SizeUnattainable(smallest.length, max),
          );
        }
        dpi = nextDpi;
        rounds++;
      }
      accepted = chosen;
    }

    final artifact = _unwrap(
      await blobStore.write(
        Stream.value(accepted),
        storageClass: StorageClass.exportArtifact,
        expectedSize: accepted.length,
        cancel: cancel,
      ),
    );
    final paper = orientedPaperMm(page);
    return _Produced(
      artifact: artifact,
      width: paper.width.round(),
      height: paper.height.round(),
      pageCount: LayoutEngine.pageCount(page, sources.length),
      quality: acceptedQ,
      dpi: acceptedDpi,
      warnings: warnings.toList(growable: false),
    );
  }

  // ── Recording (step 8) ──────────────────────────────────────────────────

  Future<Result<ExportResult, VaultFailure>> _recordSuccess(
    ExportId exportId,
    EntryId entryId,
    ExportRequest request,
    List<ResolvedSource> sources,
    _Produced produced,
    DateTime createdAt,
    Duration duration,
    bool retainArtifact,
  ) async {
    final record = ExportRecord(
      id: exportId,
      entryId: entryId,
      request: request,
      format: request.format.dbValue,
      layout: request.page?.layout.dbValue,
      paperSize: request.page?.paper.name.toUpperCase(),
      outWidth: produced.width,
      outHeight: produced.height,
      dpi: produced.dpi,
      quality: produced.quality,
      targetBytes: request.quality.targetBytes,
      maxBytes: request.quality.maxBytes,
      actualBytes: produced.artifact.plaintextSize,
      pageCount: produced.pageCount,
      status: ExportStatus.success.dbValue,
      warningsJson: jsonEncode([for (final w in produced.warnings) w.name]),
      durationMs: duration.inMilliseconds,
      artifactBlobId: produced.artifact.id,
      artifactBlob: produced.artifact,
      retainArtifact: retainArtifact,
      artifactExpiresAt: retainArtifact ? createdAt.add(artifactTtl) : null,
      createdAt: createdAt,
      originDevice: deviceId,
      sources: _sourceRows(sources),
    );
    final stored = await entries.recordExport(record);
    if (stored.isErr) {
      // An unrecorded artifact is an orphan; don't leave it on disk.
      await blobStore.purge(produced.artifact.id);
      return Err(stored.errOrNull!);
    }
    return Ok(
      ExportResult(
        id: exportId,
        artifactBlobId: produced.artifact.id,
        format: request.format,
        actualBytes: produced.artifact.plaintextSize,
        outWidth: produced.width,
        outHeight: produced.height,
        effectiveDpi: produced.dpi,
        pageCount: produced.pageCount,
        appliedQuality: produced.quality,
        warnings: produced.warnings,
        duration: duration,
      ),
    );
  }

  Future<Result<ExportResult, VaultFailure>> _recordFailure(
    ExportId exportId,
    EntryId entryId,
    ExportRequest request,
    List<ResolvedSource> sources,
    VaultFailure failure,
    DateTime createdAt,
    Duration duration,
  ) async {
    final cancelled = failure is OperationCancelled;
    await entries.recordExport(
      ExportRecord(
        id: exportId,
        entryId: entryId,
        request: request,
        format: request.format.dbValue,
        layout: request.page?.layout.dbValue,
        paperSize: request.page?.paper.name.toUpperCase(),
        targetBytes: request.quality.targetBytes,
        maxBytes: request.quality.maxBytes,
        status:
            (cancelled ? ExportStatus.cancelled : ExportStatus.failed).dbValue,
        failureCode: cancelled ? null : failure.code,
        durationMs: duration.inMilliseconds,
        createdAt: createdAt,
        originDevice: deviceId,
        sources: _sourceRows(sources),
      ),
    );
    return Err(failure);
  }

  static List<({String versionId, int ordinal})> _sourceRows(
    List<ResolvedSource> sources,
  ) => [
    for (var i = 0; i < sources.length; i++)
      (versionId: sources[i].versionId, ordinal: i),
  ];

  static int? _dpiOf(RasterSpec? raster) =>
      raster == null || raster.unit == DimensionUnit.px ? null : raster.dpi;

  static bool _sameAspect(int w1, int h1, int w2, int h2) =>
      ((w1 / h1) - (w2 / h2)).abs() < 0.01;

  static T _unwrap<T>(Result<T, VaultFailure> result) => result.fold(
    (value) => value,
    (failure) => throw ExportException(failure),
  );
}

final class _Produced {
  const _Produced({
    required this.artifact,
    required this.width,
    required this.height,
    required this.pageCount,
    required this.quality,
    required this.dpi,
    required this.warnings,
  });

  final BlobRef artifact;
  final int width;
  final int height;
  final int pageCount;
  final int quality;
  final int? dpi;
  final List<ExportWarning> warnings;
}
