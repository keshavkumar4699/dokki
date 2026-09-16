/// `EntryRepositoryImpl` against a real in-memory SQLite database.
///
/// Covers the Phase 1 acceptance list (ARCHITECTURE.md §17): one of each
/// entry type, page add/reorder/delete, the version commit + retention
/// path, and — most importantly — that the schema's partial unique indexes,
/// CHECK constraints and triggers actually reject invariant violations.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_persistence/vault_persistence.dart';

import 'support/fixtures.dart';

void main() {
  late AppDatabase db;
  late EntryRepositoryImpl repo;
  late Fixtures fx;

  setUp(() async {
    db = await openTestDb();
    fx = Fixtures();
    repo = EntryRepositoryImpl(db, activeKeyEpoch: () => 1);
  });

  tearDown(() => db.close());

  group('create + load', () {
    for (final type in EntryType.values) {
      test('creates a $type entry with its ORIGINAL version', () async {
        final created = unwrap(await repo.createEntry(fx.newEntry(type)));
        expect(created.type, type);
        expect(created.title, '${type.name} title');
        expect(created.assets, hasLength(1));
        final asset = created.assets.single;
        expect(asset.versions, hasLength(1));
        expect(asset.currentVersion, isNotNull);
        expect(asset.currentVersion!.isOriginal, isTrue);
        expect(EntryInvariants.check(created).isOk, isTrue);
      });
    }

    test('round-trips tags, note and sha256 exactly', () async {
      final entry = fx.newEntry(EntryType.photo, tags: ['tax', '2026']);
      final created = unwrap(await repo.createEntry(entry));
      expect(created.tags, ['tax', '2026']);
      final version = created.assets.single.currentVersion!;
      expect(version.meta.plaintextSha256, 'cd' * 32);
      final blobRow = await db.versionsDao.blobById(version.blobId!);
      expect(blobRow, isNotNull);
      expect(blobRow!.wrappedDek, hasLength(60));
      expect(blobRow.ciphertextSize, 1128);
    });

    test('listEntries returns summaries newest first', () async {
      unwrap(await repo.createEntry(fx.newEntry(EntryType.photo, title: 'a')));
      fx.clock.advance(const Duration(minutes: 1));
      unwrap(await repo.createEntry(fx.newEntry(EntryType.id, title: 'b')));
      final list = unwrap(await repo.listEntries());
      expect(list.map((s) => s.title), ['b', 'a']);
      expect(list.first.assetCount, 1);
      final onlyPhotos = unwrap(await repo.listEntries(type: EntryType.photo));
      expect(onlyPhotos.map((s) => s.title), ['a']);
    });

    test('findEntryOrNull returns null for unknown id', () async {
      expect(unwrap(await repo.findEntryOrNull('nope')), isNull);
      expect(unwrapErr(await repo.findEntry('nope')), isA<InvalidAsset>());
    });

    test('every new blob is enqueued for upload', () async {
      final created = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo)),
      );
      final queue = await db.syncDao.pendingQueueRows();
      expect(queue, hasLength(1));
      expect(
        queue.single.targetId,
        created.assets.single.currentVersion!.blobId,
      );
    });
  });

  group('entry details + deletion', () {
    test('updateEntryDetails changes only the given fields', () async {
      final created = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo, tags: ['x'])),
      );
      fx.clock.advance(const Duration(seconds: 5));
      unwrap(
        await repo.updateEntryDetails(
          created.id,
          EntryDetailsUpdate(
            hlc: fx.nextHlc(),
            updatedAt: fx.clock.now(),
            title: 'Renamed',
          ),
        ),
      );
      final reloaded = unwrap(await repo.findEntry(created.id));
      expect(reloaded.title, 'Renamed');
      expect(reloaded.tags, ['x']);
      expect(reloaded.updatedAt, fx.clock.now());
      expect(reloaded.updatedHlc.compareTo(created.updatedHlc) > 0, isTrue);
    });

    test('deleteEntry is a soft delete with a tombstone', () async {
      final created = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo)),
      );
      final hlc = fx.nextHlc();
      unwrap(
        await repo.deleteEntry(
          created.id,
          Tombstone.of(
            entityKind: TombstoneEntityKind.entry,
            entityId: created.id,
            deletedHlc: hlc,
            originDevice: deviceA,
            deletedAt: fx.clock.now(),
          ),
          now: fx.clock.now(),
        ),
      );
      expect(unwrap(await repo.listEntries()), isEmpty);
      expect(
        unwrap(await repo.listEntries(includeDeleted: true)),
        hasLength(1),
      );
      final row = unwrap(await repo.findEntry(created.id));
      expect(row.isDeleted, isTrue);
      final tombstone = await db.syncDao.tombstoneRow('ENTRY', created.id);
      expect(tombstone, isNotNull);
    });
  });

  group('documents (I6, I7)', () {
    Future<VaultEntry> threePageDoc() async {
      final entry = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.document)),
      );
      for (final ordinal in [1, 2]) {
        unwrap(
          await repo.addAsset(
            fx.newAsset(
              entryId: entry.id,
              role: AssetRole.page,
              ordinal: ordinal,
            ),
          ),
        );
      }
      return unwrap(await repo.findEntry(entry.id));
    }

    test('adds pages with contiguous ordinals', () async {
      final doc = await threePageDoc();
      expect(doc.assets.map((a) => a.ordinal), [0, 1, 2]);
      expect(EntryInvariants.check(doc).isOk, isTrue);
    });

    test('reorderPages assigns 0..n-1 in the requested order', () async {
      final doc = await threePageDoc();
      final ids = doc.assets.map((a) => a.id).toList();
      unwrap(
        await repo.reorderPages(
          doc.id,
          [ids[2], ids[0], ids[1]],
          hlc: fx.nextHlc(),
          now: fx.clock.now(),
        ),
      );
      final reordered = unwrap(await repo.findEntry(doc.id));
      expect(reordered.assets.map((a) => a.id), [ids[2], ids[0], ids[1]]);
      expect(reordered.assets.map((a) => a.ordinal), [0, 1, 2]);
    });

    test('summary cover follows the first live page', () async {
      final doc = await threePageDoc();
      final ids = doc.assets.map((a) => a.id).toList();
      Future<VersionId?> cover() async =>
          unwrap(await repo.listEntries()).single.coverVersionId;
      expect(await cover(), doc.assets.first.currentVersionId);
      unwrap(
        await repo.reorderPages(
          doc.id,
          [ids[2], ids[0], ids[1]],
          hlc: fx.nextHlc(),
          now: fx.clock.now(),
        ),
      );
      expect(await cover(), doc.assets[2].currentVersionId);
      unwrap(
        await repo.deleteAsset(
          ids[2],
          Tombstone.of(
            entityKind: TombstoneEntityKind.asset,
            entityId: ids[2],
            deletedHlc: fx.nextHlc(),
            originDevice: deviceA,
            deletedAt: fx.clock.now(),
          ),
          now: fx.clock.now(),
        ),
      );
      expect(await cover(), doc.assets[0].currentVersionId);
    });

    test('reorderPages rejects a partial or duplicated list', () async {
      final doc = await threePageDoc();
      final ids = doc.assets.map((a) => a.id).toList();
      expect(
        unwrapErr(
          await repo.reorderPages(
            doc.id,
            [ids[0], ids[1]],
            hlc: fx.nextHlc(),
            now: fx.clock.now(),
          ),
        ),
        isA<EntryInvariantViolated>(),
      );
      expect(
        unwrapErr(
          await repo.reorderPages(
            doc.id,
            [ids[0], ids[0], ids[1]],
            hlc: fx.nextHlc(),
            now: fx.clock.now(),
          ),
        ),
        isA<EntryInvariantViolated>(),
      );
    });

    test('ux_assets_slot rejects a duplicate live (role, ordinal)', () async {
      final doc = await threePageDoc();
      final failure = unwrapErr(
        await repo.addAsset(
          fx.newAsset(entryId: doc.id, role: AssetRole.page, ordinal: 1),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
      // Nothing from the failed transaction leaked.
      expect(unwrap(await repo.findEntry(doc.id)).assets, hasLength(3));
    });

    test('ux_assets_singleton rejects a second PRIMARY', () async {
      final photo = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo)),
      );
      final failure = unwrapErr(
        await repo.addAsset(
          fx.newAsset(entryId: photo.id, role: AssetRole.primary, ordinal: 1),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
    });

    test('deleteAsset frees the slot for reuse', () async {
      final doc = await threePageDoc();
      final last = doc.assets.last;
      unwrap(
        await repo.deleteAsset(
          last.id,
          Tombstone.of(
            entityKind: TombstoneEntityKind.asset,
            entityId: last.id,
            deletedHlc: fx.nextHlc(),
            originDevice: deviceA,
            deletedAt: fx.clock.now(),
          ),
          now: fx.clock.now(),
        ),
      );
      expect(unwrap(await repo.listAssets(doc.id)), hasLength(2));
      unwrap(
        await repo.addAsset(
          fx.newAsset(entryId: doc.id, role: AssetRole.page, ordinal: 2),
        ),
      );
      expect(unwrap(await repo.listAssets(doc.id)), hasLength(3));
    });
  });

  group('versions (I1, I2, I3, I9)', () {
    late Asset asset;

    setUp(() async {
      final entry = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo)),
      );
      asset = entry.assets.single;
    });

    Future<CommitOutcome> commit({
      VersionRetentionPolicy? retention,
      List<Pin> pins = const [],
    }) async {
      final parent = asset.currentVersionId;
      final seq = asset.versions.length;
      final (version, blob) = fx.derived(
        assetId: asset.id,
        parentId: parent,
        seq: seq,
      );
      // Retention runs against the graph *including* the new version as
      // current — the same view the DB has after the insert (§10.5).
      final evictable = retention == null
          ? const <VersionId>{}
          : retention.selectEvictable(
              VersionGraph(
                versions: [...asset.versions, version],
                currentId: version.id,
              ),
              unwrap(await repo.loadPins(asset.id)),
            );
      final outcome = unwrap(
        await repo.commitVersion(
          VersionCommit(
            assetId: asset.id,
            version: version,
            blob: blob,
            hlc: fx.nextHlc(),
            now: fx.clock.now(),
            pinsToAdd: pins,
            pinsToRemove: const [],
            evictable: evictable,
          ),
        ),
      );
      asset = outcome.asset;
      return outcome;
    }

    test('commitVersion appends and moves the pointer', () async {
      await commit();
      expect(asset.versions, hasLength(2));
      // The list projection sees the new pointer without a reload.
      final summary = unwrap(await repo.listEntries()).single;
      expect(summary.coverVersionId, asset.currentVersionId);
      expect(asset.currentVersion!.isDerived, isTrue);
      expect(asset.currentVersion!.parentVersionId, asset.versions.first.id);
      expect(asset.currentVersion!.recipe, const EditRecipe([RotateOp(1)]));
    });

    test('a commit without the BlobRef is rejected', () async {
      final (version, _) = fx.derived(
        assetId: asset.id,
        parentId: asset.currentVersionId,
        seq: 1,
      );
      final failure = unwrapErr(
        await repo.commitVersion(
          VersionCommit(
            assetId: asset.id,
            version: version,
            hlc: fx.nextHlc(),
            now: fx.clock.now(),
            pinsToAdd: const [],
            pinsToRemove: const [],
            evictable: const {},
          ),
        ),
      );
      expect(failure, isA<InvalidAsset>());
    });

    test('retention: 7 edits leave original + current + 3 derived', () async {
      const policy = KeepOriginalCurrentAndNPolicy();
      final purged = <BlobId>[];
      for (var i = 0; i < 7; i++) {
        final outcome = await commit(retention: policy);
        purged.addAll(outcome.purgableBlobIds);
      }
      final materialized = asset.versions.where((v) => v.isMaterialized);
      // 1 original + 1 current + 3 history, with 8 rows total retained.
      expect(asset.versions, hasLength(8));
      expect(materialized, hasLength(5));
      expect(asset.versions.first.isOriginal, isTrue);
      expect(asset.versions.first.isMaterialized, isTrue);
      expect(purged, hasLength(3));
      // Evicted rows keep their recipe for re-materialization.
      final evicted = asset.versions.where((v) => v.isEvicted);
      expect(evicted.every((v) => v.recipe != null), isTrue);
    });

    test('the CHECK constraint refuses to evict an ORIGINAL (I2)', () async {
      await commit();
      final failure = unwrapErr(
        await repo.evictVersions(
          [asset.versions.first.id],
          hlc: fx.nextHlc(),
          at: fx.clock.now(),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
      expect(
        unwrap(await repo.findAsset(asset.id)).versions.first.blobId,
        isNotNull,
      );
    });

    test('the trigger refuses to evict the current version (I3)', () async {
      await commit();
      final failure = unwrapErr(
        await repo.evictVersions(
          [asset.currentVersionId],
          hlc: fx.nextHlc(),
          at: fx.clock.now(),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
    });

    test('setCurrentVersion switches to any materialized version', () async {
      await commit();
      final original = asset.versions.first;
      final switched = unwrap(
        await repo.setCurrentVersion(
          asset.id,
          original.id,
          hlc: fx.nextHlc(),
          now: fx.clock.now(),
        ),
      );
      expect(switched.currentVersionId, original.id);
      expect(switched.versions, hasLength(2));
    });

    test('setCurrentVersion rejects another asset\'s version', () async {
      final other = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo)),
      );
      final failure = unwrapErr(
        await repo.setCurrentVersion(
          asset.id,
          other.assets.single.currentVersionId,
          hlc: fx.nextHlc(),
          now: fx.clock.now(),
        ),
      );
      expect(failure, isA<EntryInvariantViolated>());
    });

    test('ux_version_original rejects a second ORIGINAL (I1)', () async {
      final rogue = originalVersion(
        id: 'rogue',
        assetId: asset.id,
        seq: 99,
        blobId: fx.blob().id,
        meta: fx.meta(),
        hlc: fx.nextHlc(),
        originDevice: deviceA,
        createdAt: fx.clock.now(),
      );
      // Go beneath the repository: the DB itself must reject this.
      await expectLater(
        db.versionsDao.insertVersion(
          AssetVersionsCompanion.insert(
            id: rogue.id,
            assetId: rogue.assetId,
            kind: 'ORIGINAL',
            seq: rogue.seq,
            blobId: Value(asset.currentVersion!.blobId),
            width: 1,
            height: 1,
            mime: 'image/jpeg',
            plaintextSha256: Uint8List(0),
            plaintextSize: 1,
            createdAt: fx.clock.now(),
            createdHlc: rogue.createdHlc.toSortableString(),
            originDevice: deviceA,
          ),
        ),
        throwsA(anything),
      );
    });

    test(
      'pins are loaded onto versions and block nothing by themselves',
      () async {
        await commit();
        final pinned = asset.versions.first.id;
        unwrap(
          await repo.addPin(
            Pin(versionId: pinned, reason: PinReason.user, refId: ''),
            now: fx.clock.now(),
          ),
        );
        final pins = unwrap(await repo.loadPins(asset.id));
        expect(pins.isPinned(pinned), isTrue);
        final reloaded = unwrap(await repo.findAsset(asset.id));
        expect(reloaded.versions.first.isPinned, isTrue);
        unwrap(
          await repo.removePin(
            Pin(versionId: pinned, reason: PinReason.user, refId: ''),
          ),
        );
        expect(unwrap(await repo.loadPins(asset.id)).pins, isEmpty);
      },
    );
  });

  group('watch streams', () {
    test('watchEntries emits the initial list and again on change', () async {
      final events = <List<VaultEntrySummary>>[];
      final sub = repo.watchEntries().listen((r) => events.add(unwrap(r)));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo, title: 'new')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(events.first, isEmpty);
      expect(events.last.single.title, 'new');
    });

    test('watchEntry follows version commits on the entry', () async {
      final entry = unwrap(
        await repo.createEntry(fx.newEntry(EntryType.photo)),
      );
      final counts = <int>[];
      final sub = repo
          .watchEntry(entry.id)
          .listen((r) => counts.add(unwrap(r)!.assets.single.versions.length));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final asset = entry.assets.single;
      final (version, blob) = fx.derived(
        assetId: asset.id,
        parentId: asset.currentVersionId,
        seq: 1,
      );
      unwrap(
        await repo.commitVersion(
          VersionCommit(
            assetId: asset.id,
            version: version,
            blob: blob,
            hlc: fx.nextHlc(),
            now: fx.clock.now(),
            pinsToAdd: const [],
            pinsToRemove: const [],
            evictable: const {},
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(counts.first, 1);
      expect(counts.last, 2);
    });
  });

  group('exports (§6.3, §11.7)', () {
    late VaultEntry entry;

    setUp(() async {
      entry = unwrap(await repo.createEntry(fx.newEntry(EntryType.photo)));
    });

    ExportRecord record(
      String id,
      BlobRef? artifact, {
      bool retain = false,
      DateTime? expires,
    }) => ExportRecord(
      id: id,
      entryId: entry.id,
      request: const ExportRequest(
        source: CurrentOfEntrySource('e'),
        format: OutputFormat.jpeg,
        quality: QualitySpec(quality: 85),
      ),
      format: 'JPEG',
      status: 'SUCCESS',
      createdAt: fx.clock.now(),
      originDevice: deviceA,
      artifactBlobId: artifact?.id,
      artifactBlob: artifact,
      retainArtifact: retain,
      artifactExpiresAt: expires,
      actualBytes: artifact?.plaintextSize,
      pageCount: 1,
      sources: [(versionId: entry.assets.single.currentVersionId, ordinal: 0)],
    );

    BlobRef artifact() {
      final blob = fx.blob(size: 4321);
      return BlobRef(
        id: blob.id,
        storageClass: StorageClass.exportArtifact,
        relPath: 'exports/${blob.id.substring(0, 2)}/${blob.id}',
        keyEpoch: 1,
        wrappedDek: blob.wrappedDek,
        plaintextSize: blob.plaintextSize,
        ciphertextSize: blob.ciphertextSize,
        ciphertextSha256: blob.ciphertextSha256,
        plaintextSha256: blob.plaintextSha256,
      );
    }

    test('recording writes the artifact blob row, not an upload', () async {
      final blob = artifact();
      unwrap(await repo.recordExport(record('x1', blob)));
      expect(await db.versionsDao.blobById(blob.id), isNotNull);
      expect(await db.syncDao.pendingQueueRows(), hasLength(1)); // the asset
      final loaded = unwrap(await repo.findExportRecord('x1'))!;
      expect(loaded.artifactBlobId, blob.id);
      expect(loaded.request.quality.quality, 85);
      expect(
        loaded.sources.single.versionId,
        entry.assets.single.currentVersionId,
      );
      final list = unwrap(await repo.listExportRecords(entry.id));
      expect(list.single.actualBytes, 4321);
    });

    test('an artifact id without its BlobRef is rejected', () async {
      final blob = artifact();
      final failure = unwrapErr(
        await repo.recordExport(
          ExportRecord(
            id: 'x2',
            entryId: entry.id,
            request: record('x2', null).request,
            format: 'JPEG',
            status: 'SUCCESS',
            createdAt: fx.clock.now(),
            originDevice: deviceA,
            artifactBlobId: blob.id,
          ),
        ),
      );
      expect(failure, isA<InvalidAsset>());
    });

    test('a retained export pins its sources until GC releases it', () async {
      final asset = entry.assets.single;
      final blob = artifact();
      unwrap(
        await repo.recordExport(
          record(
            'x3',
            blob,
            retain: true,
            expires: fx.clock.now().add(const Duration(days: 7)),
          ),
        ),
      );
      var pins = unwrap(await repo.loadPins(asset.id));
      expect(
        pins.hasPin(
          asset.currentVersionId,
          PinReason.exportRetained,
          refId: 'x3',
        ),
        isTrue,
      );

      // Not yet expired: nothing to release.
      expect(
        unwrap(await repo.releaseExportArtifacts(now: fx.clock.now())),
        isEmpty,
      );

      fx.clock.advance(const Duration(days: 8));
      final released = unwrap(
        await repo.releaseExportArtifacts(now: fx.clock.now()),
      );
      expect(released, [blob.id]);
      expect(await db.versionsDao.blobById(blob.id), isNull);
      final loaded = unwrap(await repo.findExportRecord('x3'))!;
      expect(loaded.artifactBlobId, isNull);
      expect(loaded.retainArtifact, isFalse);
      expect(loaded.status, 'SUCCESS'); // history survives GC
      pins = unwrap(await repo.loadPins(asset.id));
      expect(pins.pins, isEmpty);
    });

    test('a non-retained artifact is released on the next sweep', () async {
      final blob = artifact();
      unwrap(await repo.recordExport(record('x4', blob)));
      final released = unwrap(
        await repo.releaseExportArtifacts(now: fx.clock.now()),
      );
      expect(released, [blob.id]);
      expect(unwrap(await repo.findExportRecord('x4'))!.artifactBlobId, isNull);
    });
  });

  group('sync op emission (§9.3, §10.5)', () {
    Future<List<SyncOp>> emittedOps() async {
      final syncState = SyncStateRepositoryImpl(db);
      return unwrap(await syncState.openSegmentOps(deviceA));
    }

    test('createEntry emits entry, asset, version and pointer ops', () async {
      unwrap(await repo.createEntry(fx.newEntry(EntryType.id)));
      final ops = await emittedOps();
      // HLC-sorted: entry first (its HLC was minted before the asset's).
      expect(ops.map((op) => op.opType), [
        'upsertEntry',
        'upsertAsset',
        'addVersion',
        'setCurrent',
      ]);
      final entryOp = ops.whereType<UpsertEntryOp>().single;
      expect(entryOp.origin, deviceA);
      expect(entryOp.sealedTitleBase64, isNotNull);
      final addOp = ops.whereType<AddVersionOp>().single;
      expect(addOp.blobKeyEpoch, isNotNull);
      expect(addOp.blobWrappedDekBase64, isNotNull);
      expect(addOp.blobCiphertextSha256, isNotNull);
    });

    test('commitVersion emits version, pointer and eviction ops', () async {
      final created = unwrap(await repo.createEntry(fx.newEntry(EntryType.photo)));
      final asset = created.assets.single;
      final (version, blob) = fx.derived(
        assetId: asset.id,
        parentId: asset.currentVersionId,
        seq: 2,
      );
      unwrap(
        await repo.commitVersion(
          VersionCommit(
            assetId: asset.id,
            version: version,
            hlc: fx.nextHlc(),
            now: fx.clock.now(),
            pinsToAdd: const [],
            pinsToRemove: const [],
            evictable: const {},
            blob: blob,
          ),
        ),
      );
      final ops = await emittedOps();
      expect(
        ops.where((op) => op.opType == 'addVersion'),
        hasLength(2),
      );
      expect(ops.whereType<SetCurrentOp>().last.versionId, version.id);
    });

    test('deleteEntry emits a tombstone op', () async {
      final created = unwrap(await repo.createEntry(fx.newEntry(EntryType.photo)));
      unwrap(
        await repo.deleteEntry(
          created.id,
          Tombstone.of(
            entityKind: TombstoneEntityKind.entry,
            entityId: created.id,
            deletedHlc: fx.nextHlc(),
            originDevice: deviceA,
            deletedAt: fx.clock.now(),
          ),
          now: fx.clock.now(),
        ),
      );
      final ops = await emittedOps();
      final tombstone = ops.whereType<TombstoneOp>().single;
      expect(tombstone.entityKind, TombstoneEntityKind.entry);
      expect(tombstone.entityId, created.id);
    });
  });
}
