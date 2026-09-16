/// Export source resolution (§11.3 step 2, §11.7 ladder), the quick /
/// again use cases, presets, and the artifact GC — over in-memory fakes.
library;

import 'package:test/test.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'support/fakes.dart';
import 'support/in_memory_entry_repository.dart';

/// Records what it was asked to run and answers with a canned result.
final class RecordingEngine implements ExportEngine {
  final List<ExportRequest> requests = [];
  final List<bool> retain = [];

  @override
  Future<Result<ExportResult, VaultFailure>> run(
    ExportRequest request, {
    ProgressSink? progress,
    CancellationToken? cancel,
    bool retainArtifact = false,
  }) async {
    requests.add(request);
    retain.add(retainArtifact);
    return Ok(
      ExportResult(
        id: 'x${requests.length}',
        format: request.format,
        actualBytes: 1,
        outWidth: 1,
        outHeight: 1,
        pageCount: 1,
        appliedQuality: 1,
        warnings: const [],
        duration: Duration.zero,
      ),
    );
  }
}

void main() {
  late InMemoryEntryRepository repo;
  late InMemoryBlobStore store;
  late FakeImageProcessor images;
  late VaultContext context;
  late VersionServices services;
  late ExportSourceResolverImpl resolver;
  late CreateEntryUseCase create;

  setUp(() {
    repo = InMemoryEntryRepository();
    final ids = SequenceIds();
    store = InMemoryBlobStore(ids: ids);
    images = FakeImageProcessor(store);
    context = testContext(ids: ids);
    services = VersionServices(
      context: context,
      entries: repo,
      blobStore: store,
      images: images,
      thumbnails: FakeThumbnailProvider(),
    );
    resolver = ExportSourceResolverImpl(
      entries: repo,
      rematerialize: RematerializeVersionUseCase(services),
    );
    create = CreateEntryUseCase(
      context: context,
      entries: repo,
      importer: AssetImporter(
        context: context,
        blobStore: store,
        images: images,
      ),
    );
  });

  tearDown(() => repo.dispose());

  Future<VaultEntry> photo() async => unwrap(
    await create.execute(
      CreateEntryCommand(type: EntryType.photo, source: sourceOf(400, 300)),
    ),
  );

  group('ExportSourceResolverImpl', () {
    test('CurrentOfEntry on an ID yields front then back', () async {
      final id = unwrap(
        await create.execute(
          CreateEntryCommand(type: EntryType.id, source: sourceOf(400, 250)),
        ),
      );
      final withBack = unwrap(
        await AddAssetUseCase(
          context: context,
          entries: repo,
          importer: AssetImporter(
            context: context,
            blobStore: store,
            images: images,
          ),
        ).execute(id.id, role: AssetRole.idBack, source: sourceOf(400, 250)),
      );
      final entry = unwrap(await repo.findEntry(id.id));
      final sources = unwrap(
        await resolver.resolve(CurrentOfEntrySource(entry.id)),
      );
      final roles = [
        for (final s in sources)
          entry.assets.firstWhere((a) => a.id == s.assetId).role,
      ];
      expect(roles, [AssetRole.idFront, AssetRole.idBack]);
      expect(sources.map((s) => s.assetId), contains(withBack.id));
      expect(sources.every((s) => s.warnings.isEmpty), isTrue);
      expect(sources.first.entryId, entry.id);
    });

    test('a materialized version resolves to itself', () async {
      final entry = await photo();
      final version = entry.assets.single.currentVersion!;
      final sources = unwrap(
        await resolver.resolve(SingleVersionSource(version.id)),
      );
      expect(sources.single.versionId, version.id);
      expect(sources.single.requestedVersionId, version.id);
      expect(sources.single.blobId, version.blobId);
      expect(sources.single.warnings, isEmpty);
    });

    test(
      'an evicted deterministic version is rebuilt (+sourceEvicted)',
      () async {
        final entry = await photo();
        var asset = entry.assets.single;
        for (var i = 0; i < 6; i++) {
          asset = unwrap(
            await CommitEditUseCase(
              services,
            ).execute(asset.id, const EditRecipe([RotateOp(1)])),
          );
        }
        final evicted = asset.versions.firstWhere((v) => v.isEvicted);
        final sources = unwrap(
          await resolver.resolve(SingleVersionSource(evicted.id)),
        );
        expect(sources.single.versionId, evicted.id);
        expect(sources.single.warnings, [ExportWarning.sourceEvicted]);
        expect(store.blobs.containsKey(sources.single.blobId), isTrue);
      },
    );

    test('an evicted non-deterministic version falls back to current '
        '(+sourceChanged)', () async {
      final entry = await photo();
      var asset = entry.assets.single;
      Future<void> commit(List<ImageOp> ops) async => asset = unwrap(
        await CommitEditUseCase(services).execute(asset.id, EditRecipe(ops)),
      );
      await commit(const [BackgroundOp(BackgroundSpec(color: 0xFFFFFFFF))]);
      for (var i = 0; i < 5; i++) {
        await commit(const [RotateOp(2)]);
      }
      final evicted = asset.versions.firstWhere((v) => v.seq == 1);
      expect(evicted.isEvicted, isTrue);
      final sources = unwrap(
        await resolver.resolve(SingleVersionSource(evicted.id)),
      );
      expect(sources.single.requestedVersionId, evicted.id);
      expect(sources.single.versionId, asset.currentVersionId);
      expect(sources.single.warnings, [ExportWarning.sourceChanged]);
    });

    test('a missing version is MissingVersion', () async {
      final failure = unwrapErr(
        await resolver.resolve(const SingleVersionSource('nope')),
      );
      expect(failure, isA<MissingVersion>());
    });

    test('IdPair and DocumentPages keep the requested order', () async {
      final a = await photo();
      final b = await photo();
      final va = a.assets.single.currentVersionId;
      final vb = b.assets.single.currentVersionId;
      final pair = unwrap(
        await resolver.resolve(IdPairSource(front: vb, back: va)),
      );
      expect(pair.map((s) => s.versionId), [vb, va]);
      final pages = unwrap(
        await resolver.resolve(DocumentPagesSource([va, vb, va])),
      );
      expect(pages.map((s) => s.versionId), [va, vb, va]);
    });
  });

  group('ExportUseCases', () {
    late RecordingEngine engine;
    late ExportUseCases useCases;

    setUp(() {
      engine = RecordingEngine();
      useCases = ExportUseCases(
        context: context,
        engine: engine,
        entries: repo,
        blobStore: store,
        presets: builtInExportPresets(),
      );
    });

    test('quick export builds the preset request over the entry', () async {
      final entry = await photo();
      unwrap(await useCases.quick(entry.id, presetId: 'email'));
      final request = engine.requests.single;
      expect(request.source, isA<CurrentOfEntrySource>());
      expect(request.format, OutputFormat.jpeg);
      expect(request.quality.targetBytes, EmailFriendlyPreset.targetBytes);
      expect(engine.retain.single, isFalse);
    });

    test('quick export of one version narrows the source', () async {
      final entry = await photo();
      final version = entry.assets.single.currentVersionId;
      unwrap(
        await useCases.quick(
          entry.id,
          presetId: 'full',
          onlyVersion: version,
          retainArtifact: true,
        ),
      );
      final request = engine.requests.single;
      expect(request.source, isA<SingleVersionSource>());
      expect((request.source as SingleVersionSource).versionId, version);
      expect(request.quality.quality, 92);
      expect(engine.retain.single, isTrue);
    });

    test('full quality picks PNG for signatures', () async {
      final signature = unwrap(
        await create.execute(
          CreateEntryCommand(
            type: EntryType.signature,
            source: sourceOf(300, 100),
          ),
        ),
      );
      unwrap(await useCases.quick(signature.id, presetId: 'full'));
      expect(engine.requests.single.format, OutputFormat.png);
    });

    test('an unknown preset is rejected', () async {
      final entry = await photo();
      expect(
        unwrapErr(await useCases.quick(entry.id, presetId: 'nope')),
        isA<InvalidAsset>(),
      );
      expect(engine.requests, isEmpty);
    });

    test('again replays the recorded versions, not today\'s current', () async {
      final entry = await photo();
      final v1 = entry.assets.single.currentVersionId;
      unwrap(
        await repo.recordExport(
          ExportRecord(
            id: 'x1',
            entryId: entry.id,
            request: const ExportRequest(
              source: CurrentOfEntrySource('ignored'),
              format: OutputFormat.jpeg,
              quality: QualitySpec(quality: 70),
            ),
            format: 'JPEG',
            status: 'SUCCESS',
            createdAt: context.now(),
            originDevice: testDevice,
            retainArtifact: true,
            sources: [(versionId: v1, ordinal: 0)],
          ),
        ),
      );
      unwrap(await useCases.again('x1'));
      final replay = engine.requests.single;
      expect(replay.source, isA<SingleVersionSource>());
      expect((replay.source as SingleVersionSource).versionId, v1);
      expect(replay.quality.quality, 70);
      expect(engine.retain.single, isTrue);
    });

    test('replaySource maps recorded versions back onto the source shape', () {
      ExportRecord record(ExportSource source, List<String> versions) =>
          ExportRecord(
            id: 'x',
            entryId: 'e',
            request: ExportRequest(
              source: source,
              format: OutputFormat.pdf,
              quality: const QualitySpec(),
            ),
            format: 'PDF',
            status: 'SUCCESS',
            createdAt: DateTime.utc(2026),
            originDevice: testDevice,
            sources: [
              for (var i = 0; i < versions.length; i++)
                (versionId: versions[i], ordinal: versions.length - 1 - i),
            ],
          );
      // Ordinals are honoured (the list above is stored reversed).
      final pages = ExportUseCases.replaySource(
        record(const DocumentPagesSource(['old']), ['c', 'b', 'a']),
      );
      expect((pages as DocumentPagesSource).pages, ['a', 'b', 'c']);
      final pair = ExportUseCases.replaySource(
        record(const IdPairSource(front: 'old'), ['back', 'front']),
      );
      expect((pair as IdPairSource).front, 'front');
      expect(pair.back, 'back');
      final single = ExportUseCases.replaySource(
        record(const CurrentOfEntrySource('e'), ['only']),
      );
      expect(single, isA<SingleVersionSource>());
      final many = ExportUseCases.replaySource(
        record(const CurrentOfEntrySource('e'), ['b', 'a']),
      );
      expect(many, isA<DocumentPagesSource>());
    });

    test(
      'releaseArtifacts purges non-retained and expired artifacts',
      () async {
        final entry = await photo();
        final v1 = entry.assets.single.currentVersionId;
        final artifact = unwrap(
          await store.write(
            Stream.value(const [1, 2, 3]),
            storageClass: StorageClass.exportArtifact,
            expectedSize: 3,
          ),
        );
        final kept = unwrap(
          await store.write(
            Stream.value(const [4, 5, 6]),
            storageClass: StorageClass.exportArtifact,
            expectedSize: 3,
          ),
        );
        ExportRecord record(String id, BlobRef blob, DateTime? expires) =>
            ExportRecord(
              id: id,
              entryId: entry.id,
              request: const ExportRequest(
                source: CurrentOfEntrySource('e'),
                format: OutputFormat.jpeg,
                quality: QualitySpec(),
              ),
              format: 'JPEG',
              status: 'SUCCESS',
              createdAt: context.now(),
              originDevice: testDevice,
              artifactBlobId: blob.id,
              artifactBlob: blob,
              retainArtifact: expires != null,
              artifactExpiresAt: expires,
              sources: [(versionId: v1, ordinal: 0)],
            );
        unwrap(await repo.recordExport(record('gone', artifact, null)));
        unwrap(
          await repo.recordExport(
            record('kept', kept, context.now().add(const Duration(days: 3))),
          ),
        );
        expect(unwrap(await repo.loadPins(entry.assets.single.id)).pins, [
          Pin(versionId: v1, reason: PinReason.exportRetained, refId: 'kept'),
        ]);

        expect(unwrap(await useCases.releaseArtifacts()), 1);
        expect(store.purged, [artifact.id]);
        expect(
          unwrap(await repo.findExportRecord('gone'))!.artifactBlobId,
          isNull,
        );
        expect(
          unwrap(await repo.findExportRecord('kept'))!.artifactBlobId,
          kept.id,
        );

        // Past the expiry the retained one goes too, pin included.
        (context.clock as FixedClock).advance(const Duration(days: 8));
        expect(unwrap(await useCases.releaseArtifacts()), 1);
        expect(store.purged, [artifact.id, kept.id]);
        expect(
          unwrap(await repo.loadPins(entry.assets.single.id)).pins,
          isEmpty,
        );
      },
    );
  });
}
