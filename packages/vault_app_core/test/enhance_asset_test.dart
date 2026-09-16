/// `EnhanceAssetUseCase` (Phase 8): detection → perspective commit, and
/// the honest failure when no confident quad exists.
library;

import 'package:test/test.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'support/fakes.dart';
import 'support/in_memory_entry_repository.dart';

final class _FakeEdgeDetector implements EdgeDetector {
  Quad? quad;
  int calls = 0;

  @override
  Future<Result<Quad?, VaultFailure>> detect(
    BlobHandle source, {
    ProgressSink? progress,
  }) async {
    calls++;
    return Ok(quad);
  }
}

void main() {
  late InMemoryEntryRepository repo;
  late InMemoryBlobStore store;
  late FakeImageProcessor images;
  late _FakeEdgeDetector detector;
  late VersionServices services;
  late EnhanceAssetUseCase enhance;
  late Asset asset;

  setUp(() async {
    repo = InMemoryEntryRepository();
    final ids = SequenceIds();
    store = InMemoryBlobStore(ids: ids);
    images = FakeImageProcessor(store);
    detector = _FakeEdgeDetector();
    final context = testContext(ids: ids);
    services = VersionServices(
      context: context,
      entries: repo,
      blobStore: store,
      images: images,
      thumbnails: FakeThumbnailProvider(),
    );
    enhance = EnhanceAssetUseCase(services: services, detector: detector);
    final entry = unwrap(
      await CreateEntryUseCase(
        context: context,
        entries: repo,
        importer: AssetImporter(
          context: context,
          blobStore: store,
          images: images,
        ),
      ).execute(
        CreateEntryCommand(type: EntryType.document, source: sourceOf(400, 300)),
      ),
    );
    asset = entry.assets.single;
  });

  tearDown(() => repo.dispose());

  test('a detected quad commits a perspective-corrected derived version', () async {
    detector.quad = const Quad(
      PointN(0.1, 0.1),
      PointN(0.9, 0.05),
      PointN(0.95, 0.9),
      PointN(0.05, 0.95),
    );
    final updated = unwrap(await enhance.execute(asset.id));
    expect(detector.calls, 1);
    expect(updated.versions, hasLength(2));
    final derived = updated.currentVersion!;
    expect(derived.isOriginal, isFalse);
    expect(derived.parentVersionId, asset.currentVersionId);
    expect(derived.recipe!.ops.single, isA<PerspectiveOp>());
    final op = derived.recipe!.ops.single as PerspectiveOp;
    expect(op.quad.topLeft, const PointN(0.1, 0.1));
    expect(updated.currentVersionId, derived.id);
  });

  test('no confident quad is an honest failure, not a silent no-op', () async {
    detector.quad = null;
    final result = await enhance.execute(asset.id);
    expect(result.errOrNull, isA<ImageProcessingFailed>());
    // Nothing was committed: the pointer and history are untouched.
    final reloaded = unwrap(await repo.findAsset(asset.id));
    expect(reloaded.versions, hasLength(1));
    expect(reloaded.currentVersionId, asset.currentVersionId);
  });
}
