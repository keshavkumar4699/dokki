/// `ExportEngineImpl` end to end over fakes: validation, resolution
/// warnings, size targeting, sealing, recording of every outcome, and
/// the artifact retention flags (§11.3, §11.7).
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_export/vault_export.dart';

import 'support/fakes.dart';

void main() {
  late MemBlobStore store;
  late RecordingEntries entries;
  late FakeRasterEngine raster;
  late FixedClock clock;

  ExportEngineImpl engine({
    List<ResolvedSource>? sources,
    VaultFailure? resolveFailure,
  }) => ExportEngineImpl(
    entries: entries,
    blobStore: store,
    raster: raster,
    resolver: CannedResolver(sources ?? [resolved()], failure: resolveFailure),
    clock: clock,
    ids: SequenceIds(),
    deviceId: 'device-a',
  );

  setUp(() {
    store = MemBlobStore()..blobs['blob-src'] = List.filled(10, 1);
    entries = RecordingEntries();
    raster = FakeRasterEngine();
    clock = FixedClock(DateTime.utc(2026, 9, 16, 12));
  });

  const jpegOriginal = ExportRequest(
    source: CurrentOfEntrySource('entry-1'),
    format: OutputFormat.jpeg,
    quality: QualitySpec(quality: 90),
  );

  test('quick jpeg export seals an artifact and records SUCCESS', () async {
    final result = await engine().run(jpegOriginal);
    final ok = result.okOrNull!;
    expect(ok.format, OutputFormat.jpeg);
    expect(ok.appliedQuality, 90);
    expect(ok.outWidth, 1000);
    expect(ok.outHeight, 800);
    expect(ok.pageCount, 1);
    expect(ok.warnings, isEmpty);
    expect(store.classes[ok.artifactBlobId], StorageClass.exportArtifact);
    expect(store.blobs[ok.artifactBlobId]!.length, ok.actualBytes);

    final record = entries.records.single;
    expect(record.id, ok.id);
    expect(record.entryId, 'entry-1');
    expect(record.status, 'SUCCESS');
    expect(record.format, 'JPEG');
    expect(record.artifactBlobId, ok.artifactBlobId);
    expect(record.artifactBlob, isNotNull);
    expect(record.retainArtifact, isFalse);
    expect(record.artifactExpiresAt, isNull);
    expect(record.sources, [(versionId: 'v-1', ordinal: 0)]);
    expect(record.quality, 90);
    expect(record.warningsJson, '[]');
    expect(record.originDevice, 'device-a');
  });

  test('retained artifacts get an expiry a TTL after creation', () async {
    final result = await engine().run(jpegOriginal, retainArtifact: true);
    expect(result.isOk, isTrue);
    final record = entries.records.single;
    expect(record.retainArtifact, isTrue);
    expect(record.artifactExpiresAt, clock.now().add(const Duration(days: 7)));
  });

  test('a raster spec sizes the output and reports upscaling', () async {
    const request = ExportRequest(
      source: SingleVersionSource('v-1'),
      format: OutputFormat.png,
      quality: QualitySpec(),
      raster: RasterSpec(width: 2000, fit: FitMode.contain),
    );
    final result = await engine().run(request);
    final ok = result.okOrNull!;
    expect(raster.lastPlan!.width, 2000);
    expect(raster.lastPlan!.height, isNull);
    expect(ok.warnings, contains(ExportWarning.upscaledBeyondSource));
    expect(ok.effectiveDpi, isNull);
  });

  test('physical units convert through dpi and record it', () async {
    const request = ExportRequest(
      source: SingleVersionSource('v-1'),
      format: OutputFormat.jpeg,
      quality: QualitySpec(),
      // Passport photo: 35 × 45 mm at 300 dpi = 413 × 531 px.
      raster: RasterSpec(
        width: 35,
        height: 45,
        unit: DimensionUnit.mm,
        dpi: 300,
      ),
    );
    final result = await engine().run(request);
    expect(result.isOk, isTrue, reason: '${result.errOrNull}');
    expect(raster.lastPlan!.width, 413);
    expect(raster.lastPlan!.height, 531);
    expect(result.okOrNull!.effectiveDpi, 300);
    expect(entries.records.single.dpi, 300);
  });

  test(
    'a 200 KB target on a large source lands within 10 % or says why',
    () async {
      // 1000 × 800 at q40 is 329 600 bytes: the target needs a downscale.
      const request = ExportRequest(
        source: CurrentOfEntrySource('entry-1'),
        format: OutputFormat.jpeg,
        quality: QualitySpec(targetBytes: 200000),
      );
      final ok = (await engine().run(request)).okOrNull!;
      expect(ok.actualBytes, lessThanOrEqualTo(200000));
      expect(ok.actualBytes, greaterThanOrEqualTo(180000));
      expect(ok.outWidth, lessThan(1000));
      expect(ok.warnings, isNot(contains(ExportWarning.targetSizeMissed)));
    },
  );

  test(
    'maxBytes that cannot be met is a failure, recorded as FAILED',
    () async {
      const request = ExportRequest(
        source: CurrentOfEntrySource('entry-1'),
        format: OutputFormat.jpeg,
        quality: QualitySpec(maxBytes: 1000, allowDownscale: false),
      );
      final result = await engine().run(request);
      final failure = result.errOrNull;
      expect(failure, isA<SizeUnattainable>());
      expect((failure! as SizeUnattainable).maxBytes, 1000);
      expect(
        store.classes.values,
        isNot(contains(StorageClass.exportArtifact)),
      );
      final record = entries.records.single;
      expect(record.status, 'FAILED');
      expect(record.failureCode, 'SIZE_UNATTAINABLE');
      expect(record.artifactBlobId, isNull);
      expect(record.maxBytes, 1000);
    },
  );

  test('a missed best-effort target is a warning, not a failure', () async {
    const request = ExportRequest(
      source: CurrentOfEntrySource('entry-1'),
      format: OutputFormat.jpeg,
      quality: QualitySpec(targetBytes: 1000, allowDownscale: false),
    );
    final ok = (await engine().run(request)).okOrNull!;
    expect(ok.warnings, contains(ExportWarning.targetSizeMissed));
    expect(ok.warnings, contains(ExportWarning.qualityFloorReached));
    expect(ok.appliedQuality, 40);
    expect(
      jsonDecode(entries.records.single.warningsJson!),
      containsAll(['targetSizeMissed', 'qualityFloorReached']),
    );
  });

  test('resolver warnings flow into the result', () async {
    final ok = (await engine(
      sources: [
        resolved(warnings: const [ExportWarning.sourceChanged]),
      ],
    ).run(jpegOriginal)).okOrNull!;
    expect(ok.warnings, contains(ExportWarning.sourceChanged));
  });

  test('validation failures are not recorded', () async {
    const bad = ExportRequest(
      source: CurrentOfEntrySource('entry-1'),
      format: OutputFormat.jpeg,
      quality: QualitySpec(quality: 0),
    );
    expect((await engine().run(bad)).errOrNull, isA<InvalidExportDimensions>());
    expect(entries.records, isEmpty);
  });

  test('every validation rule rejects its input', () {
    Result<ValidatedRequest, VaultFailure> v(ExportRequest r) =>
        validateExportRequest(
          r,
          supportedFormats: {OutputFormat.jpeg, OutputFormat.png},
        );
    const src = SingleVersionSource('v');
    expect(
      v(
        const ExportRequest(
          source: src,
          format: OutputFormat.webp,
          quality: QualitySpec(),
        ),
      ).errOrNull,
      isA<UnsupportedFormat>(),
    );
    expect(
      v(
        const ExportRequest(
          source: DocumentPagesSource([]),
          format: OutputFormat.jpeg,
          quality: QualitySpec(),
        ),
      ).errOrNull,
      isA<InvalidExportDimensions>(),
    );
    expect(
      v(
        const ExportRequest(
          source: src,
          format: OutputFormat.jpeg,
          quality: QualitySpec(),
          raster: RasterSpec(width: 30000),
        ),
      ).errOrNull,
      isA<InvalidExportDimensions>(),
    );
    expect(
      v(
        const ExportRequest(
          source: src,
          format: OutputFormat.jpeg,
          quality: QualitySpec(),
          raster: RasterSpec(width: 100, unit: DimensionUnit.mm),
        ),
      ).errOrNull,
      isA<InvalidExportDimensions>(),
    );
    expect(
      v(
        const ExportRequest(
          source: src,
          format: OutputFormat.jpeg,
          quality: QualitySpec(targetBytes: 10, maxBytes: 5),
        ),
      ).errOrNull,
      isA<InvalidExportDimensions>(),
    );
    // PNG + hard cap + no downscale fails immediately (§11.4).
    expect(
      v(
        const ExportRequest(
          source: src,
          format: OutputFormat.png,
          quality: QualitySpec(maxBytes: 5000, allowDownscale: false),
        ),
      ).errOrNull,
      isA<SizeUnattainable>(),
    );
    expect(
      v(
        const ExportRequest(
          source: src,
          format: OutputFormat.jpeg,
          quality: QualitySpec(),
          page: PageLayoutSpec(paper: PaperSize.a4),
        ),
      ).errOrNull,
      isA<InvalidExportDimensions>(),
    );
  });

  test('pdf is unsupported until a composer is wired', () async {
    const request = ExportRequest(
      source: CurrentOfEntrySource('entry-1'),
      format: OutputFormat.pdf,
      quality: QualitySpec(),
      page: PageLayoutSpec(paper: PaperSize.a4),
    );
    expect((await engine().run(request)).errOrNull, isA<UnsupportedFormat>());
  });

  group('pdf path (§11.3, §11.4)', () {
    late FakePdfComposer pdf;

    ExportEngineImpl pdfEngine({
      List<ResolvedSource>? sources,
      int baseBytes = 20000,
    }) {
      pdf = FakePdfComposer(baseBytes: baseBytes);
      return ExportEngineImpl(
        entries: entries,
        blobStore: store,
        raster: raster,
        resolver: CannedResolver(sources ?? [resolved()]),
        clock: clock,
        ids: SequenceIds(),
        deviceId: 'device-a',
        pdf: pdf,
      );
    }

    const a4Single = ExportRequest(
      source: CurrentOfEntrySource('entry-1'),
      format: OutputFormat.pdf,
      quality: QualitySpec(),
      page: PageLayoutSpec(paper: PaperSize.a4),
    );

    test('an id pair composes side-by-side on one A4 page', () async {
      const request = ExportRequest(
        source: IdPairSource(front: 'v-1', back: 'v-2'),
        format: OutputFormat.pdf,
        quality: QualitySpec(quality: 90),
        page: PageLayoutSpec(paper: PaperSize.a4, layout: LayoutMode.sideBySide),
      );
      final ok = (await pdfEngine(
        sources: [resolved(), resolved(versionId: 'v-2')],
      ).run(request)).okOrNull!;
      expect(ok.format, OutputFormat.pdf);
      expect(ok.pageCount, 1);
      expect(ok.appliedQuality, 90);
      expect(ok.effectiveDpi, 300);
      expect(pdf.lastRequest!.placements, hasLength(2));
      expect(pdf.lastRequest!.images, hasLength(2));
      final record = entries.records.single;
      expect(record.status, 'SUCCESS');
      expect(record.format, 'PDF');
      expect(record.layout, 'SIDE_BY_SIDE');
      expect(record.paperSize, 'A4');
      expect(record.sources, hasLength(2));
    });

    test('an unconstrained pdf composes exactly once at defaults', () async {
      final ok = (await pdfEngine().run(a4Single)).okOrNull!;
      expect(pdf.probes, [(quality: 85, effectiveDpi: 300)]);
      expect(ok.warnings, isEmpty);
      expect(store.classes[ok.artifactBlobId], StorageClass.exportArtifact);
    });

    test('quality and colour flow into the compose request', () async {
      const request = ExportRequest(
        source: CurrentOfEntrySource('entry-1'),
        format: OutputFormat.pdf,
        quality: QualitySpec(quality: 55),
        page: PageLayoutSpec(paper: PaperSize.a5),
        color: ColorSpec(grayscale: true),
      );
      await pdfEngine().run(request);
      expect(pdf.probes.single.quality, 55);
      expect(pdf.lastRequest!.color.grayscale, isTrue);
    });

    test('a quality search lands a 10 KB target within tolerance', () async {
      const request = ExportRequest(
        source: CurrentOfEntrySource('entry-1'),
        format: OutputFormat.pdf,
        quality: QualitySpec(targetBytes: 10000),
        page: PageLayoutSpec(paper: PaperSize.a4),
      );
      final ok = (await pdfEngine().run(request)).okOrNull!;
      expect(ok.actualBytes, lessThanOrEqualTo(10000));
      expect(ok.actualBytes, greaterThanOrEqualTo(9000));
      expect(ok.warnings, isNot(contains(ExportWarning.targetSizeMissed)));
      expect(pdf.probes.length, greaterThan(1));
    });

    test('dpi downscale rounds engage when the quality floor is not enough', () async {
      const request = ExportRequest(
        source: CurrentOfEntrySource('entry-1'),
        format: OutputFormat.pdf,
        quality: QualitySpec(maxBytes: 6000),
        page: PageLayoutSpec(paper: PaperSize.a4),
      );
      final ok = (await pdfEngine().run(request)).okOrNull!;
      expect(ok.actualBytes, lessThanOrEqualTo(6000));
      expect(ok.effectiveDpi, lessThan(300));
      expect(ok.appliedQuality, lessThan(85));
      expect(
        pdf.probes.where((p) => p.effectiveDpi < 300),
        isNotEmpty,
      );
    });

    test('maxBytes that cannot be met is a hard failure, recorded', () async {
      const request = ExportRequest(
        source: CurrentOfEntrySource('entry-1'),
        format: OutputFormat.pdf,
        quality: QualitySpec(maxBytes: 1000, allowDownscale: false),
        page: PageLayoutSpec(paper: PaperSize.a4),
      );
      final result = await pdfEngine().run(request);
      expect(result.errOrNull, isA<SizeUnattainable>());
      expect(entries.records.single.status, 'FAILED');
      expect(entries.records.single.failureCode, 'SIZE_UNATTAINABLE');
      expect(store.classes.values, isNot(contains(StorageClass.exportArtifact)));
    });

    test('a missed best-effort target warns instead of failing', () async {
      const request = ExportRequest(
        source: CurrentOfEntrySource('entry-1'),
        format: OutputFormat.pdf,
        quality: QualitySpec(targetBytes: 4000),
        page: PageLayoutSpec(paper: PaperSize.a4),
      );
      final ok = (await pdfEngine().run(request)).okOrNull!;
      expect(ok.warnings, contains(ExportWarning.targetSizeMissed));
      expect(ok.warnings, contains(ExportWarning.qualityFloorReached));
      expect(ok.actualBytes, greaterThan(4000));
    });

    test('a composer failure is recorded as FAILED', () async {
      pdf = FakePdfComposer(failure: const PdfGenerationFailed(pageIndex: 0));
      final broken = ExportEngineImpl(
        entries: entries,
        blobStore: store,
        raster: raster,
        resolver: CannedResolver([resolved()]),
        clock: clock,
        ids: SequenceIds(),
        deviceId: 'device-a',
        pdf: pdf,
      );
      final result = await broken.run(a4Single);
      expect(result.errOrNull, isA<PdfGenerationFailed>());
      expect(entries.records.single.status, 'FAILED');
      expect(entries.records.single.failureCode, 'PDF_GENERATION_FAILED');
    });
  });

  test('two images in a raster format need pdf; recorded as FAILED', () async {
    final result = await engine(
      sources: [
        resolved(),
        resolved(versionId: 'v-2'),
      ],
    ).run(jpegOriginal);
    expect(result.errOrNull, isA<UnsupportedFormat>());
    expect(entries.records.single.status, 'FAILED');
    expect(entries.records.single.sources, hasLength(2));
  });

  test('a resolver failure surfaces unchanged and unrecorded', () async {
    final result = await engine(
      resolveFailure: const MissingVersion('v-9'),
    ).run(jpegOriginal);
    expect(result.errOrNull, isA<MissingVersion>());
    expect(entries.records, isEmpty);
  });

  test('cancellation records CANCELLED and leaves no artifact', () async {
    final token = CancellationToken()..cancel();
    final result = await engine().run(jpegOriginal, cancel: token);
    expect(result.errOrNull, isA<OperationCancelled>());
    expect(entries.records.single.status, 'CANCELLED');
    expect(entries.records.single.failureCode, isNull);
    expect(store.classes.values, isNot(contains(StorageClass.exportArtifact)));
  });

  test('a record that fails to persist purges its orphaned artifact', () async {
    entries.failNextRecord = const DatabaseFailure('disk full');
    final result = await engine().run(jpegOriginal);
    expect(result.errOrNull, isA<DatabaseFailure>());
    expect(store.purged, hasLength(1));
    expect(store.classes.keys, isNot(contains(store.purged.single)));
  });

  test('rasters are disposed after use', () async {
    await engine().run(jpegOriginal);
    expect(raster.lastRaster!.disposed, isTrue);
  });

  test('progress reports the stages in order', () async {
    final stages = <int>[];
    await engine().run(jpegOriginal, progress: (done, _) => stages.add(done));
    expect(stages, [0, 1, 2, 3, 4, 5, 6]);
  });
}
