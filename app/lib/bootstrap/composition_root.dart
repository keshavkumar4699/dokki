/// The ONE place everything meets (§3.1).
///
/// This is the only file in `app/` allowed to import concrete
/// infrastructure packages. It constructs the object graph in two stages:
///
/// 1. [composeBoot] — before unlock. Reads the keyring file (§7.1), picks
///    the key backend, restores lock state. No database yet: the database
///    is SQLCipher-encrypted under `K_db`, which needs the master key.
/// 2. `AppBoot.openVault` — after unlock. Derives `K_db`, opens the
///    database (migrating a Phase-1 plaintext file in place, once), mirrors
///    the keyring into `key_epochs`, and wires the repositories, blob
///    store, image pipeline and use cases.
///
/// Real time, real ids and real randomness are also created only here
/// (§13.2); everything else receives the injected `Clock`, `IdGenerator`
/// and `RandomSource`.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:platform_android/platform_android.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:uuid/uuid.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_crypto/vault_crypto.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_drive/vault_drive.dart';
import 'package:vault_export/vault_export.dart';
import 'package:vault_imaging/vault_imaging.dart';
import 'package:vault_pdf/vault_pdf.dart';
import 'package:vault_persistence/vault_persistence.dart';
import 'package:vault_storage/vault_storage.dart';
import 'package:vault_sync/vault_sync.dart';

import 'app_boot.dart';
import 'app_graph.dart';

export 'app_boot.dart';
export 'app_graph.dart';

final class _SystemClock implements Clock {
  const _SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

final class _UuidIds implements IdGenerator {
  const _UuidIds();

  static const _uuid = Uuid();

  @override
  String newEntityId() => _uuid.v7();

  @override
  String newBlobId() => _uuid.v4();
}

final class _SecureRandom implements RandomSource {
  _SecureRandom() : _random = Random.secure();

  final Random _random;

  @override
  void fillBytes(List<int> out) {
    for (var i = 0; i < out.length; i++) {
      out[i] = _random.nextInt(256);
    }
  }

  @override
  int nextInt(int max) => _random.nextInt(max);
}

/// Adapts the file store's decrypted stream to the imaging package's seam.
final class _PlaintextAdapter implements BlobPlaintextSource {
  const _PlaintextAdapter(this._store);

  final FileBlobStore _store;

  @override
  Stream<List<int>> openPlaintext(BlobHandle handle) =>
      _store.openPlaintext(handle);
}

/// Adapts the file store's layout to the native pipeline's seam: Kotlin
/// reads sealed files by path and writes sealed `.part` files that are
/// committed here with the same atomic rename the Dart write path uses.
final class _SealedFilesAdapter implements SealedBlobFiles {
  const _SealedFilesAdapter(this._store);

  final FileBlobStore _store;

  @override
  Future<SealedInput> resolve(BlobHandle handle) async {
    if (handle is! FileBlobHandle) {
      throw ArgumentError('Not a FileBlobHandle');
    }
    return SealedInput(
      path: _store.paths.absolute(handle.relPath),
      purpose: BlobPaths.purposeFor(handle.storageClass).byte,
    );
  }

  @override
  Future<PendingSealedBlob> allocate(StorageClass storageClass) async {
    final id = _store.ids.newBlobId();
    final relPath = BlobPaths.relPathFor(storageClass, id);
    return PendingSealedBlob(
      id: id,
      storageClass: storageClass,
      relPath: relPath,
      partPath: _store.paths.partFile(relPath),
      purpose: BlobPaths.purposeFor(storageClass).byte,
      keyEpoch: _store.activeKeyEpoch(),
    );
  }

  @override
  Future<BlobRef> commit(PendingSealedBlob pending, SealedFileInfo info) async {
    await File(pending.partPath).rename(_store.paths.absolute(pending.relPath));
    return BlobRef(
      id: pending.id,
      storageClass: pending.storageClass,
      relPath: pending.relPath,
      keyEpoch: info.keyEpoch,
      wrappedDek: info.wrappedDek,
      plaintextSize: info.plaintextSize,
      ciphertextSize: info.ciphertextSize,
      ciphertextSha256: info.ciphertextSha256,
      plaintextSha256: info.plaintextSha256,
    );
  }

  @override
  Future<void> abandon(PendingSealedBlob pending) async {
    final part = File(pending.partPath);
    if (part.existsSync()) {
      await part.delete();
    }
  }
}

/// Stage 1. Called once from `main()`.
Future<AppBoot> composeBoot() async {
  const clock = _SystemClock();
  const ids = _UuidIds();
  final random = _SecureRandom();

  // ── Storage roots (§7.1): app-private only, never external storage. ──
  final support = await getApplicationSupportDirectory();
  final filesRoot = p.join(support.path, 'vault');
  await Directory(filesRoot).create(recursive: true);
  final dbPath = p.join(support.path, 'vault.db');
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  // The one directory that may hold plaintext, only while a share sheet
  // is up (§7.1). Swept now, on every lock, and after every share.
  final shareCache = ShareCache(
    p.join((await getTemporaryDirectory()).path, 'export_tmp'),
  );
  await shareCache.sweep();

  // ── Keyring: the pre-unlock source of truth for key epochs. ─────────
  final keyring = KeyringFile(rootDir: filesRoot);
  if (!keyring.exists && isPlaintextSqlite(dbPath)) {
    await _migrateLegacyKeyring(dbPath, keyring);
  }

  // ── Key backend. An existing vault dictates it (its wrap algorithm);
  //    a fresh install prefers the Keystore path whenever Kotlin answers.
  final existing = (await keyring.loadEpochs()).getOrElse((_) => const []);
  const nativeBridge = NativeKeyManagerBridge();
  final nativeAvailable = await nativeBridge.isAvailable();
  final wantsNative = existing.isEmpty
      ? nativeAvailable
      : existing.any((e) => e.wrapAlgorithm == KeyManagerImpl.wrapAlgorithm);

  final KeyManager keyManager;
  final EnvelopePrimitive primitive;
  final CryptoBackend backend;
  // The native image pipeline needs the native key session (it decrypts
  // sealed files itself), so it follows the key backend.
  const imagingBridge = NativeImagingBridge();
  final nativeImaging =
      wantsNative && nativeAvailable && await imagingBridge.isAvailable();
  if (wantsNative && nativeAvailable) {
    final native = KeyManagerImpl(
      bridge: nativeBridge,
      epochs: keyring,
      clock: clock,
    );
    await native.restoreState();
    keyManager = native;
    primitive = const NativeEnvelopePrimitive(NativeCryptoBridge());
    backend = CryptoBackend.native;
  } else {
    final devPrimitive = DartEnvelopePrimitive();
    final dev = DartKeyManager(
      epochs: keyring,
      primitive: devPrimitive,
      clock: clock,
      random: random,
    );
    await dev.restoreState();
    keyManager = dev;
    primitive = devPrimitive;
    backend = CryptoBackend.softwareDev;
  }
  final session = UnlockSession(keyManager: keyManager);
  int activeEpoch() => keyManager.activeKeyEpoch ?? 1;
  final crypto = CryptoEngineImpl(
    cipher: EnvelopeCipher(primitive: primitive, random: random),
    activeKeyEpoch: activeEpoch,
  );

  // ── Sync (§9): the cloud provider and Drive auth exist from boot; the
  //    engine is wired per unlocked vault. Nothing here ever sends
  //    plaintext — the provider's `put` only sees sealed bytes (§9.1).
  final driveAuth = GoogleDriveAuth();
  final cloud = GoogleDriveCloudProvider(apiFactory: driveAuth.api);

  final log = VaultLog(
    sink: kDebugMode ? const ConsoleLogSink() : const DeveloperLogSink(),
    debugEnabled: kDebugMode,
  );
  AppDatabase? db;

  Future<void> closeVault() async {
    await db?.close();
    db = null;
    await shareCache.sweep();
  }

  Future<Result<AppGraph, VaultFailure>> openVaultUnlogged() async {
    final dbKey = await keyManager.deriveDbKey();
    return dbKey.asyncFlatMap((key) async {
      if (isPlaintextSqlite(dbPath)) {
        // One-time §6.6 data migration of a Phase-1 vault.
        encryptPlaintextDatabase(dbPath, key);
      }
      final database = AppDatabase(openVaultConnection(dbPath, key: key));
      db = database;
      final mirrored = await _mirrorKeyring(
        keyring,
        KeyEpochRepositoryImpl(database),
      );
      if (mirrored.isErr) {
        await closeVault();
        return Err(mirrored.errOrNull!);
      }
      final syncState = SyncStateRepositoryImpl(database);
      final device = await _ensureDeviceId(syncState, ids, clock);
      if (device.isErr) {
        await closeVault();
        return Err(device.errOrNull!);
      }
      final deviceId = device.okOrNull!;
      final context = VaultContext(
        deviceId: deviceId,
        clock: clock,
        ids: ids,
        random: random,
      );

      final blobStore = FileBlobStore(
        rootDir: filesRoot,
        crypto: crypto,
        ids: ids,
        activeKeyEpoch: activeEpoch,
        headerRewriter: EnvelopeHeaderRewriter(primitive),
      );
      await blobStore.sweepPartialWrites();

      // ── Sync engine + controller (§9): kicks land here after every
      //    commit; cycles run debounced, on app open, and on demand.
      final engine = SyncEngine(
        deviceId: deviceId,
        syncState: syncState,
        apply: SyncApplyRepositoryImpl(database),
        blobStore: blobStore,
        cloud: cloud,
        crypto: crypto,
        ids: ids,
        clock: clock,
        random: random,
      );
      final controller = SyncController(
        runner: SyncEngineRunner(engine),
        syncState: syncState,
        context: context,
      );
      final syncSetup = SyncSetup(
        keyManager: keyManager,
        crypto: crypto,
        cloud: cloud,
        activeKeyEpoch: activeEpoch,
      );

      final entries = EntryRepositoryImpl(
        database,
        activeKeyEpoch: activeEpoch,
        crypto: crypto,
        queuePort: controller,
      );
      final plaintext = _PlaintextAdapter(blobStore);
      final sealedFiles = _SealedFilesAdapter(blobStore);
      final images = nativeImaging
          ? NativeImageProcessor(bridge: imagingBridge, files: sealedFiles)
          : DartImageProcessor(source: plaintext, blobStore: blobStore);
      // Phase 8: the detector lives only behind the native pipeline; with
      // the Dart fallback there is no CV, and the UI hides the action.
      final edgeDetector = nativeImaging
          ? EdgeDetectorImpl(bridge: imagingBridge, files: sealedFiles)
          : null;
      final rasterEngine = nativeImaging
          ? NativeRasterEngine(bridge: imagingBridge, files: sealedFiles)
          : DartRasterEngine(source: plaintext);
      final thumbnails = ThumbnailCache(
        index: ThumbnailIndexImpl(database),
        entries: entries,
        blobStore: blobStore,
        images: images,
        clock: clock,
        ids: ids,
      );
      // §7.6: storage accounting. The import path refuses before writing
      // when the floor is crossed; pressure also trims the thumbnail LRU
      // (fully regenerable) on this open.
      final budget = StorageBudgetImpl(
        paths: blobStore.paths,
        freeSpace: () async {
          final bytes = await const NativeSecurity().freeDiskSpace();
          return bytes < 0 ? null : bytes;
        },
      );
      final importer = AssetImporter(
        context: context,
        blobStore: blobStore,
        images: images,
        budget: budget,
      );
      final versionServices = VersionServices(
        context: context,
        entries: entries,
        blobStore: blobStore,
        images: images,
        thumbnails: thumbnails,
      );
      final exports = ExportUseCases(
        context: context,
        engine: ExportEngineImpl(
          entries: entries,
          blobStore: blobStore,
          raster: rasterEngine,
          resolver: ExportSourceResolverImpl(
            entries: entries,
            rematerialize: RematerializeVersionUseCase(versionServices),
          ),
          clock: clock,
          ids: ids,
          deviceId: deviceId,
          pdf: PdfComposerImpl(source: plaintext),
        ),
        entries: entries,
        blobStore: blobStore,
        presets: builtInExportPresets(),
      );
      // Artifact GC (§11.7): whatever was not retained, or expired, goes
      // with this open. Non-fatal — the history rows survive either way.
      final released = await exports.releaseArtifacts();
      released.fold((_) {}, (failure) {
        log.w('export artifact GC skipped [${failure.code}]');
      });
      // §7.6 pressure: below the floor, thumbnails (fully regenerable)
      // shrink to a small cache before anything else happens.
      final pressure = await budget.check();
      pressure.fold((report) {
        if (report.underPressure) {
          unawaited(thumbnails.trimToBudget(32 * 1024 * 1024));
        }
      }, (_) {});

      Future<Result<ShareHandle, VaultFailure>> prepareShare(
        ExportId exportId,
      ) => exports.record(exportId).asyncFlatMap((record) async {
        final artifact = record?.artifactBlobId;
        if (record == null || artifact == null) {
          return const Err(
            StorageIoFailure('export artifact is no longer available'),
          );
        }
        final format = OutputFormat.fromDbValue(record.format);
        final extension = switch (format) {
          OutputFormat.png => 'png',
          OutputFormat.pdf => 'pdf',
          OutputFormat.webp => 'webp',
          OutputFormat.jpeg || null => 'jpg',
        };
        final mime = switch (format) {
          OutputFormat.png => 'image/png',
          OutputFormat.pdf => 'application/pdf',
          OutputFormat.webp => 'image/webp',
          OutputFormat.jpeg || null => 'image/jpeg',
        };
        // A neutral name: the receiving app sees no title or path.
        final fileName = 'dokki-${exportId.substring(0, 8)}.$extension';
        final path = shareCache.pathFor(fileName);
        return blobStore
            .copyPlaintextTo(artifact, path)
            .map(
              (_) => ShareHandle(
                path: path,
                mimeType: mime,
                fileName: fileName,
                discard: () async => shareCache.discard(path),
              ),
            );
      });

      /// §8.6 key rotation end to end: new master key → rewrap every blob
      /// header → rekey SQLCipher to the new `K_db`. Old epochs stay
      /// readable throughout; the job resumes if the process dies.
      Future<Result<void, VaultFailure>> rotateKeys({
        required String pin,
        required String recoveryPassphrase,
      }) async {
        final rotated = await keyManager.rotate(
          pin: pin,
          recoveryPassphrase: recoveryPassphrase,
        );
        if (rotated.isErr) {
          return rotated;
        }
        final job = KeyRotationJob(
          keyManager: keyManager,
          epochBlobs: BlobEpochRepositoryImpl(database),
          blobStore: blobStore,
          activeKeyEpoch: activeEpoch,
        );
        while (true) {
          final run = await job.run();
          if (run.isErr) {
            return Err(run.errOrNull!);
          }
          if (run.okOrNull!.remaining == 0) {
            break;
          }
        }
        // §8.6 step 5: rekey SQLCipher (small DB, full rewrite is fine).
        final newKey = await keyManager.deriveDbKey();
        if (newKey.isErr) {
          return Err(newKey.errOrNull!);
        }
        await database.customStatement(
          "PRAGMA rekey = \"x'${_hex(newKey.okOrNull!)}'\"",
        );
        return const Ok(null);
      }

      return Ok(
        AppGraph(
          context: context,
          queries: VaultQueries(entries: entries),
          createEntry: CreateEntryUseCase(
            context: context,
            entries: entries,
            importer: importer,
          ),
          addAsset: AddAssetUseCase(
            context: context,
            entries: entries,
            importer: importer,
          ),
          reorderPages: ReorderPagesUseCase(context: context, entries: entries),
          deleteAsset: DeleteAssetUseCase(context: context, entries: entries),
          updateEntryDetails: UpdateEntryDetailsUseCase(
            context: context,
            entries: entries,
          ),
          deleteEntry: DeleteEntryUseCase(context: context, entries: entries),
          commitEdit: CommitEditUseCase(versionServices),
          enhance: edgeDetector == null
              ? null
              : EnhanceAssetUseCase(
                  services: versionServices,
                  detector: edgeDetector,
                ),
          switchVersion: SwitchCurrentVersionUseCase(versionServices),
          thumbnails: thumbnails,
          blobStore: blobStore,
          exports: exports,
          prepareShare: prepareShare,
          sync: controller,
          syncSetup: syncSetup,
          syncLink: _DriveSyncLink(driveAuth, syncSetup),
          rotateKeys: rotateKeys,
          storage: budget,
        ),
      );
    });
  }

  return AppBoot(
    session: session,
    keyManager: keyManager,
    random: random,
    cryptoBackend: backend,
    securitySignals: const NativeSecurity()
        .rootSignals()
        .catchError((_) => const <String>[]),
    openVault: () async {
      final opened = await openVaultUnlogged();
      opened.fold((_) {}, (failure) {
        log
          ..e('openVault failed', failureCode: failure.code)
          // Debug builds only: the cause can name a path (§12.4).
          ..d('openVault cause: ${failure.cause}');
      });
      return opened;
    },
    closeVault: closeVault,
    restoreFromDrive: ({required pin, required recoveryPassphrase}) async {
      final account = await driveAuth.signIn();
      if (account == null) {
        return const Err(SyncAuthRequired());
      }
      final setup = SyncSetup(
        keyManager: keyManager,
        crypto: crypto,
        cloud: cloud,
        activeKeyEpoch: activeEpoch,
      );
      final restored = await setup.restoreKeyring(
        pin: pin,
        recoveryPassphrase: recoveryPassphrase,
      );
      if (restored.isErr) {
        return restored;
      }
      // The vault is now unlocked with the restored MK; opening it is the
      // caller's next step, followed by a sync cycle that replays the log.
      return const Ok(null);
    },
  );
}

/// The composition root's [SyncLink] over the Drive auth (§9.9).
final class _DriveSyncLink implements SyncLink {
  const _DriveSyncLink(this._auth, this._setup);

  final GoogleDriveAuth _auth;
  final SyncSetup _setup;

  @override
  Future<CloudAuthState> authState() async =>
      await _auth.account() == null
      ? CloudAuthState.signedOut
      : CloudAuthState.signedIn;

  @override
  Future<Result<void, VaultFailure>> connect({required DeviceId deviceId}) async {
    final account = await _auth.signIn();
    if (account == null) {
      return const Err(SyncAuthRequired());
    }
    // §9.9 step 2: the keyring is what makes a wiped device recoverable.
    return _setup.uploadKeyring(deviceId: deviceId);
  }

  @override
  Future<Result<void, VaultFailure>> disconnect() async {
    await _auth.signOut();
    return const Ok(null);
  }
}

/// A vault created before the keyring file existed kept its epochs in the
/// (then plaintext) `key_epochs` table. Copy them out once; the database
/// is encrypted right after, on the first unlock.
Future<void> _migrateLegacyKeyring(String dbPath, KeyringFile keyring) async {
  final legacy = AppDatabase(openVaultConnection(dbPath));
  try {
    final rows = await KeyEpochRepositoryImpl(legacy).loadEpochs();
    for (final epoch in rows.getOrElse((_) => const [])) {
      await keyring.insertEpoch(epoch);
    }
  } finally {
    await legacy.close();
  }
}

/// `blobs.key_epoch` references `key_epochs`, so the table must carry
/// every epoch the keyring knows. The file stays the source of truth.
Future<Result<void, VaultFailure>> _mirrorKeyring(
  KeyringFile keyring,
  KeyEpochRepositoryImpl table,
) => keyring.loadEpochs().asyncFlatMap((rows) async {
  for (final epoch in rows) {
    final stored = await table.insertEpoch(epoch);
    if (stored.isErr) {
      return stored;
    }
  }
  return const Ok(null);
});

/// Lowercase hex for SQLCipher raw-key pragmas (the DB key is already
/// derived; `x'…'` makes SQLCipher use it raw, §8.1).
String _hex(List<int> bytes) => [
  for (final b in bytes) b.toRadixString(16).padLeft(2, '0'),
].join();

/// Reads the self device id from `devices`, creating it on first launch.
Future<Result<DeviceId, VaultFailure>> _ensureDeviceId(
  SyncStateRepositoryImpl syncState,
  IdGenerator ids,
  Clock clock,
) => syncState.listDevices().asyncFlatMap((devices) async {
  final self = devices.where((d) => d.isSelf).firstOrNull;
  if (self != null) {
    return Ok(self.id);
  }
  final id = ids.newBlobId();
  final created = await syncState.ensureSelfDevice(
    id: id,
    label: Platform.localHostname,
    now: clock.now(),
  );
  return created.map((_) => id);
});
