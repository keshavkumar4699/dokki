/// Entry + asset use cases over in-memory fakes.
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
  late VaultContext context;
  late AssetImporter importer;
  late CreateEntryUseCase createEntry;
  late AddAssetUseCase addAsset;

  setUp(() {
    repo = InMemoryEntryRepository();
    final ids = SequenceIds();
    store = InMemoryBlobStore(ids: ids);
    images = FakeImageProcessor(store);
    context = testContext(ids: ids);
    importer = AssetImporter(
      context: context,
      blobStore: store,
      images: images,
    );
    createEntry = CreateEntryUseCase(
      context: context,
      entries: repo,
      importer: importer,
    );
    addAsset = AddAssetUseCase(
      context: context,
      entries: repo,
      importer: importer,
    );
  });

  tearDown(() => repo.dispose());

  group('CreateEntry', () {
    test('seals the bytes, inspects them, and commits an ORIGINAL', () async {
      final entry = unwrap(
        await createEntry.execute(
          CreateEntryCommand(
            type: EntryType.photo,
            source: sourceOf(1200, 800),
            title: '  Passport  ',
            tags: const ['travel', ' ', 'id'],
          ),
        ),
      );
      expect(entry.title, 'Passport');
      expect(entry.tags, ['travel', 'id']);
      final version = entry.assets.single.currentVersion!;
      expect(version.isOriginal, isTrue);
      expect(version.meta.width, 1200);
      expect(version.meta.height, 800);
      expect(version.meta.plaintextSha256, isNotEmpty);
      expect(store.blobs.containsKey(version.blobId), isTrue);
      expect(EntryInvariants.check(entry).isOk, isTrue);
    });

    test('uses the natural first role per type', () async {
      final id = unwrap(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.id, source: sourceOf(10, 10)),
        ),
      );
      expect(id.assets.single.role, AssetRole.idFront);
      final doc = unwrap(
        await createEntry.execute(
          CreateEntryCommand(
            type: EntryType.document,
            source: sourceOf(10, 10),
          ),
        ),
      );
      expect(doc.assets.single.role, AssetRole.page);
    });

    test('rejects a role the type does not allow before sealing', () async {
      final failure = unwrapErr(
        await createEntry.execute(
          CreateEntryCommand(
            type: EntryType.photo,
            source: sourceOf(10, 10),
            role: AssetRole.page,
          ),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
      expect(store.blobs, isEmpty);
    });

    test('purges the sealed blob when the DB commit fails', () async {
      repo.failNextWrite = const DatabaseFailure('boom');
      final failure = unwrapErr(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.photo, source: sourceOf(10, 10)),
        ),
      );
      expect(failure, isA<DatabaseFailure>());
      expect(store.blobs, isEmpty);
      expect(store.purged, hasLength(1));
    });

    test('a cancelled import surfaces as OperationCancelled', () async {
      final cancel = CancellationToken()..cancel();
      final failure = unwrapErr(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.photo, source: sourceOf(10, 10)),
          cancel: cancel,
        ),
      );
      expect(failure, isA<OperationCancelled>());
    });
  });

  group('AddAsset', () {
    test('appends document pages at the next ordinal', () async {
      final doc = unwrap(
        await createEntry.execute(
          CreateEntryCommand(
            type: EntryType.document,
            source: sourceOf(10, 10),
          ),
        ),
      );
      final page2 = unwrap(
        await addAsset.execute(
          doc.id,
          role: AssetRole.page,
          source: sourceOf(20, 20),
        ),
      );
      expect(page2.ordinal, 1);
      final page3 = unwrap(
        await addAsset.execute(
          doc.id,
          role: AssetRole.page,
          source: sourceOf(30, 30),
        ),
      );
      expect(page3.ordinal, 2);
      final reloaded = unwrap(await repo.findEntry(doc.id));
      expect(reloaded.assets.map((a) => a.ordinal), [0, 1, 2]);
    });

    test('fills ID_BACK once and refuses a second', () async {
      final id = unwrap(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.id, source: sourceOf(10, 10)),
        ),
      );
      unwrap(
        await addAsset.execute(
          id.id,
          role: AssetRole.idBack,
          source: sourceOf(10, 10),
        ),
      );
      final failure = unwrapErr(
        await addAsset.execute(
          id.id,
          role: AssetRole.idBack,
          source: sourceOf(10, 10),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
      // Refused before sealing: 3 blobs (front, back, nothing more).
      expect(store.blobs, hasLength(2));
    });

    test('refuses a PAGE on a PHOTO', () async {
      final photo = unwrap(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.photo, source: sourceOf(10, 10)),
        ),
      );
      final failure = unwrapErr(
        await addAsset.execute(
          photo.id,
          role: AssetRole.page,
          source: sourceOf(10, 10),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
    });
  });

  group('ReorderPages / DeleteAsset', () {
    late VaultEntry doc;

    setUp(() async {
      doc = unwrap(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.document, source: sourceOf(1, 1)),
        ),
      );
      for (final n in [2, 3]) {
        unwrap(
          await addAsset.execute(
            doc.id,
            role: AssetRole.page,
            source: sourceOf(n, n),
          ),
        );
      }
      doc = unwrap(await repo.findEntry(doc.id));
    });

    test('reorder re-packs ordinals', () async {
      final ids = doc.assets.map((a) => a.id).toList();
      final reordered = unwrap(
        await ReorderPagesUseCase(
          context: context,
          entries: repo,
        ).execute(doc.id, [ids[2], ids[0], ids[1]]),
      );
      expect(reordered.assets.map((a) => a.id), [ids[2], ids[0], ids[1]]);
      expect(reordered.assets.map((a) => a.ordinal), [0, 1, 2]);
    });

    test('reorder is refused on a non-document', () async {
      final photo = unwrap(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.photo, source: sourceOf(1, 1)),
        ),
      );
      final failure = unwrapErr(
        await ReorderPagesUseCase(
          context: context,
          entries: repo,
        ).execute(photo.id, [photo.assets.single.id]),
      );
      expect(failure, isA<EntryInvariantViolated>());
    });

    test('deleting a middle page re-packs the rest (I7)', () async {
      final middle = doc.assets[1];
      final after = unwrap(
        await DeleteAssetUseCase(
          context: context,
          entries: repo,
        ).execute(middle.id),
      );
      expect(after.liveAssets, hasLength(2));
      expect(after.liveAssets.map((a) => a.ordinal), [0, 1]);
      expect(repo.tombstones.single.entityId, middle.id);
    });

    test('the last page of a document cannot be deleted', () async {
      final useCase = DeleteAssetUseCase(context: context, entries: repo);
      unwrap(await useCase.execute(doc.assets[0].id));
      unwrap(await useCase.execute(doc.assets[1].id));
      final failure = unwrapErr(await useCase.execute(doc.assets[2].id));
      expect(failure, isA<EntryInvariantViolated>());
    });
  });

  group('UpdateEntryDetails / DeleteEntry', () {
    test('updates only the provided fields', () async {
      final entry = unwrap(
        await createEntry.execute(
          CreateEntryCommand(
            type: EntryType.photo,
            source: sourceOf(1, 1),
            title: 'a',
            note: 'n',
          ),
        ),
      );
      final updated = unwrap(
        await UpdateEntryDetailsUseCase(
          context: context,
          entries: repo,
        ).execute(entry.id, title: 'b', tags: ['x', 'x', ' y ']),
      );
      expect(updated.title, 'b');
      expect(updated.note, 'n');
      expect(updated.tags, ['x', 'y']);
    });

    test('delete writes a tombstone and hides the entry', () async {
      final entry = unwrap(
        await createEntry.execute(
          CreateEntryCommand(type: EntryType.photo, source: sourceOf(1, 1)),
        ),
      );
      unwrap(
        await DeleteEntryUseCase(
          context: context,
          entries: repo,
        ).execute(entry.id),
      );
      expect(unwrap(await repo.listEntries()), isEmpty);
      expect(repo.tombstones.single.entityKind, TombstoneEntityKind.entry);
      // Blobs are NOT purged at stage one (§6.5).
      expect(store.blobs, hasLength(1));
    });
  });
}
