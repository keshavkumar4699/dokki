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
