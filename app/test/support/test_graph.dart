/// Builds an `AppGraph` over the in-memory fakes for widget tests.
library;

import 'package:dokki/bootstrap/app_boot.dart';
import 'package:dokki/bootstrap/app_graph.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'fakes.dart';
import 'in_memory_entry_repository.dart';

final class TestGraph {
  TestGraph({bool hasVault = true, bool unlocked = false})
    : keys = FakeKeyManager(hasVault: hasVault) {
    if (unlocked) {
      keys.unlock(pin: '1234');
    }
    final ids = SequenceIds();
    repo = InMemoryEntryRepository();
    store = InMemoryBlobStore(ids: ids);
    images = FakeImageProcessor(store);
    exportEngine = FakeExportEngine();
    final context = testContext(ids: ids);
    final importer = AssetImporter(
      context: context,
      blobStore: store,
      images: images,
    );
    final services = VersionServices(
      context: context,
      entries: repo,
      blobStore: store,
      images: images,
      thumbnails: FakeThumbnailProvider(),
    );
    session = UnlockSession(keyManager: keys);
    boot = AppBoot(
      session: session,
      keyManager: keys,
      random: SeededRandom(),
      cryptoBackend: CryptoBackend.softwareDev,
      // Like the real one, opening needs the keys: a locked session must
      // never be able to "open" the vault by accident.
      openVault: () async => session.isUnlocked
          ? Ok(graph)
          : const Err(KeyUnavailable(KeyUnavailableReason.vaultLocked)),
      closeVault: () async => closeCount++,
      restoreFromDrive: ({required pin, required recoveryPassphrase}) async =>
          const Ok(null),
    );
    graph = AppGraph(
      context: context,
      queries: VaultQueries(entries: repo),
      createEntry: CreateEntryUseCase(
        context: context,
        entries: repo,
        importer: importer,
      ),
      addAsset: AddAssetUseCase(
        context: context,
        entries: repo,
        importer: importer,
      ),
      reorderPages: ReorderPagesUseCase(context: context, entries: repo),
      deleteAsset: DeleteAssetUseCase(context: context, entries: repo),
      updateEntryDetails: UpdateEntryDetailsUseCase(
        context: context,
        entries: repo,
      ),
      deleteEntry: DeleteEntryUseCase(context: context, entries: repo),
      commitEdit: CommitEditUseCase(services),
      switchVersion: SwitchCurrentVersionUseCase(services),
      thumbnails: FakeThumbnailProvider(),
      blobStore: store,
      exports: ExportUseCases(
        context: context,
        engine: exportEngine,
        entries: repo,
        blobStore: store,
        presets: builtInExportPresets(),
      ),
      prepareShare: (exportId) async => Ok(
        ShareHandle(
          path: 'share/$exportId.bin',
          mimeType: 'application/octet-stream',
          fileName: 'dokki-$exportId.bin',
          discard: () async {},
        ),
      ),
      sync: SyncController(
        runner: FakeSyncRunner(),
        syncState: FakeSyncStateRepository(),
        context: context,
      ),
      syncSetup: SyncSetup(
        keyManager: keys,
        crypto: FakeCryptoEngine(),
        cloud: FakeCloudProvider(),
        activeKeyEpoch: () => 1,
      ),
      syncLink: const FakeSyncLink(),
    );
  }

  final FakeKeyManager keys;
  late final InMemoryEntryRepository repo;
  late final InMemoryBlobStore store;
  late final FakeImageProcessor images;
  late final FakeExportEngine exportEngine;
  late final UnlockSession session;
  late final AppGraph graph;
  late final AppBoot boot;

  /// How many times the app closed the vault (on lock).
  int closeCount = 0;
}
