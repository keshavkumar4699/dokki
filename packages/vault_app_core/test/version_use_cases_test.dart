/// Commit / switch / re-materialize over in-memory fakes (§10).
library;

import 'package:test/test.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'support/fakes.dart';
import 'support/in_memory_entry_repository.dart';

void main() {
  late InMemoryEntryRepository repo;
  late InMemoryBlobStore store;
  late FakeImageProcessor images;
  late FakeThumbnailProvider thumbs;
  late VersionServices services;
  late Asset asset;

  setUp(() async {
    repo = InMemoryEntryRepository();
    final ids = SequenceIds();
    store = InMemoryBlobStore(ids: ids);
    images = FakeImageProcessor(store);
    thumbs = FakeThumbnailProvider();
    final context = testContext(ids: ids);
    services = VersionServices(
      context: context,
      entries: repo,
      blobStore: store,
      images: images,
      thumbnails: thumbs,
    );
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
        CreateEntryCommand(type: EntryType.photo, source: sourceOf(400, 300)),
      ),
    );
    asset = entry.assets.single;
  });

  tearDown(() => repo.dispose());

  Future<Asset> commit(List<ImageOp> ops) async => asset = unwrap(
    await CommitEditUseCase(services).execute(asset.id, EditRecipe(ops)),
  );

  group('CommitEdit', () {
    test('applies ops natively and appends a DERIVED version', () async {
      await commit(const [RotateOp(1)]);
      expect(asset.versions, hasLength(2));
      final current = asset.currentVersion!;
      expect(current.isDerived, isTrue);
      expect(current.parentVersionId, asset.versions.first.id);
      expect(current.meta.width, 300);
      expect(current.meta.height, 400);
      expect(current.recipe, const EditRecipe([RotateOp(1)]));
      expect(images.applied.single, const [RotateOp(1)]);
      expect(thumbs.invalidated, [asset.id]);
    });

    test('an empty recipe is a no-op', () async {
      await commit(const []);
      expect(asset.versions, hasLength(1));
      expect(images.applied, isEmpty);
    });

    test('runs retention and purges evicted blobs after commit', () async {
      for (var i = 0; i < 7; i++) {
        await commit([BrightnessOp(0.1 * (i + 1))]);
      }
      expect(asset.versions, hasLength(8));
      final materialized = asset.versions.where((v) => v.isMaterialized);
      expect(materialized, hasLength(5)); // original + current + 3
      expect(asset.versions.first.isMaterialized, isTrue);
      expect(store.purged, hasLength(3));
      // The oldest three derived versions are the evicted ones.
      expect(asset.versions.where((v) => v.isEvicted).map((v) => v.seq), [
        1,
        2,
        3,
      ]);
      // Their recipes survive for re-materialization.
      expect(
        asset.versions.where((v) => v.isEvicted).every((v) => v.recipe != null),
        isTrue,
      );
    });

    test('pinned versions are never evicted', () async {
      await commit(const [RotateOp(1)]);
      final pinned = asset.currentVersionId;
      unwrap(
        await repo.addPin(
          Pin(versionId: pinned, reason: PinReason.user, refId: ''),
          now: DateTime.utc(2026),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await commit(const [RotateOp(2)]);
      }
      final pinnedVersion = asset.versions.firstWhere((v) => v.id == pinned);
      expect(pinnedVersion.isMaterialized, isTrue);
      expect(pinnedVersion.isPinned, isTrue);
    });

    test('purges the new blob when the commit fails', () async {
      repo.failNextWrite = const DatabaseFailure('boom');
      final failure = unwrapErr(
        await CommitEditUseCase(
          services,
        ).execute(asset.id, const EditRecipe([RotateOp(1)])),
      );
      expect(failure, isA<DatabaseFailure>());
      expect(store.blobs, hasLength(1)); // only the original remains
    });
  });

  group('SwitchCurrentVersion', () {
    test('moves the pointer to a materialized version', () async {
      await commit(const [RotateOp(1)]);
      final original = asset.versions.first;
      final switched = unwrap(
        await SwitchCurrentVersionUseCase(
          services,
        ).execute(asset.id, original.id),
      );
      expect(switched.currentVersionId, original.id);
      expect(thumbs.invalidated.last, asset.id);
    });

    test('re-materializes an evicted deterministic version first', () async {
      for (var i = 0; i < 6; i++) {
        await commit([RotateOp(i.isEven ? 1 : 3)]);
      }
      final evicted = asset.versions.firstWhere((v) => v.isEvicted);
      final chainLength = evicted.seq; // one op per derived step
      final switched = unwrap(
        await SwitchCurrentVersionUseCase(
          services,
        ).execute(asset.id, evicted.id),
      );
      expect(switched.currentVersionId, evicted.id);
      final rebuilt = switched.versions.firstWhere((v) => v.id == evicted.id);
      expect(rebuilt.isMaterialized, isTrue);
      expect(rebuilt.evictedAt, isNull);
      // applyChain replayed exactly the lineage from the original.
      expect(images.applied.last, hasLength(1));
      final (_, _, log) = FakeImageProcessor.decode(
        store.blobs[rebuilt.blobId]!,
      );
      expect('rotate;'.allMatches(log), hasLength(chainLength));
    });

    test('an unknown version is MissingVersion', () async {
      final failure = unwrapErr(
        await SwitchCurrentVersionUseCase(services).execute(asset.id, 'nope'),
      );
      expect(failure, isA<MissingVersion>());
    });
  });

  group('RematerializeVersion', () {
    test('refuses a non-deterministic chain', () async {
      await commit(const [BackgroundOp(BackgroundSpec(color: 0xFFFFFFFF))]);
      await commit(const [RotateOp(1)]);
      for (var i = 0; i < 4; i++) {
        await commit(const [RotateOp(2)]);
      }
      final evictedMl = asset.versions.firstWhere((v) => v.seq == 1);
      expect(evictedMl.isEvicted, isTrue);
      final failure = unwrapErr(
        await RematerializeVersionUseCase(
          services,
        ).execute(asset.id, evictedMl.id),
      );
      expect(failure, isA<VersionNotRematerializable>());
    });

    test('a materialized version is returned as-is', () async {
      await commit(const [RotateOp(1)]);
      final current = asset.currentVersion!;
      final result = unwrap(
        await RematerializeVersionUseCase(
          services,
        ).execute(asset.id, current.id),
      );
      expect(result.id, current.id);
      expect(images.applied, hasLength(1));
    });
  });
}
