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
import 'package:vault_imaging/vault_imaging.dart';
import 'package:vault_persistence/vault_persistence.dart';
import 'package:vault_storage/vault_storage.dart';

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

  final log = VaultLog(
    sink: kDebugMode ? const ConsoleLogSink() : const DeveloperLogSink(),
    debugEnabled: kDebugMode,
  );
  AppDatabase? db;

  Future<void> closeVault() async {
    await db?.close();
    db = null;
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

      final entries = EntryRepositoryImpl(
        database,
        activeKeyEpoch: activeEpoch,
        crypto: crypto,
      );
      final blobStore = FileBlobStore(
        rootDir: filesRoot,
        crypto: crypto,
        ids: ids,
        activeKeyEpoch: activeEpoch,
      );
      await blobStore.sweepPartialWrites();
      final images = DartImageProcessor(
        source: _PlaintextAdapter(blobStore),
        blobStore: blobStore,
      );
      final thumbnails = ThumbnailCache(
        index: ThumbnailIndexImpl(database),
        entries: entries,
        blobStore: blobStore,
        images: images,
        clock: clock,
        ids: ids,
      );
      final context = VaultContext(
        deviceId: deviceId,
        clock: clock,
        ids: ids,
        random: random,
      );
      final importer = AssetImporter(
        context: context,
        blobStore: blobStore,
        images: images,
      );
      final versionServices = VersionServices(
        context: context,
        entries: entries,
        blobStore: blobStore,
        images: images,
        thumbnails: thumbnails,
      );
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
          switchVersion: SwitchCurrentVersionUseCase(versionServices),
          thumbnails: thumbnails,
          blobStore: blobStore,
        ),
      );
    });
  }

  return AppBoot(
    session: session,
    keyManager: keyManager,
    random: random,
    cryptoBackend: backend,
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
  );
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
