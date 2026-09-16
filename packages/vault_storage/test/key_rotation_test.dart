/// §8.6 end to end: create vault → rotate → rewrap every blob header →
/// the vault still opens its bytes, now under the new epoch.
///
/// Uses the dev (pure-Dart) key backend so the whole rotation runs
/// in-process; the native path shares the same `KeyManager` contract.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_crypto/vault_crypto.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_storage/vault_storage.dart';

final class _Ids implements IdGenerator {
  int _n = 0;

  @override
  String newEntityId() => 'e${++_n}';

  @override
  String newBlobId() => 'ab${(++_n).toString().padLeft(6, '0')}-blob';
}

final class _Random implements RandomSource {
  int _seed = 99;

  @override
  void fillBytes(List<int> out) {
    for (var i = 0; i < out.length; i++) {
      _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
      out[i] = _seed & 0xFF;
    }
  }

  @override
  int nextInt(int max) =>
      (_seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF) % max;
}

final class _FixedClock implements Clock {
  DateTime _now = DateTime.utc(2026);

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

/// In-memory `BlobEpochRepository` over the written refs.
final class _EpochBlobs implements BlobEpochRepository {
  final Map<String, BlobEpochRef> rows = {};
  final Map<String, List<int>> wrapped = {};

  @override
  Future<Result<int, VaultFailure>> countBelowEpoch(int epoch) async =>
      Ok(rows.values.where((r) => r.keyEpoch < epoch).length);

  @override
  Future<Result<List<BlobEpochRef>, VaultFailure>> listBelowEpoch(
    int epoch, {
    int limit = 200,
  }) async => Ok([
    for (final ref in rows.values)
      if (ref.keyEpoch < epoch) ref,
  ]);

  @override
  Future<Result<void, VaultFailure>> updateBlobEpoch(
    BlobId blobId, {
    required int toEpoch,
    required List<int> wrappedDek,
  }) async {
    final existing = rows[blobId]!;
    rows[blobId] = BlobEpochRef(
      id: blobId,
      purpose: existing.purpose,
      keyEpoch: toEpoch,
    );
    wrapped[blobId] = wrappedDek;
    return const Ok(null);
  }
}

void main() {
  late Directory root;
  late KeyringFile keyring;
  late DartKeyManager keyManager;
  late FileBlobStore store;
  late _EpochBlobs epochBlobs;
  late KeyRotationJob job;
  final clock = _FixedClock();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dokki_rotate_');
    keyring = KeyringFile(rootDir: root.path);
    final primitive = DartEnvelopePrimitive();
    keyManager = DartKeyManager(
      epochs: keyring,
      primitive: primitive,
      clock: clock,
      random: _Random(),
    );
    await keyManager.createVault(pin: '1234', recoveryPassphrase: 'correct horse battery staple');
    epochBlobs = _EpochBlobs();
    final cipher = EnvelopeCipher(primitive: primitive, random: _Random());
    store = FileBlobStore(
      rootDir: root.path,
      crypto: CryptoEngineImpl(
        cipher: cipher,
        activeKeyEpoch: () => keyManager.activeKeyEpoch ?? 1,
      ),
      ids: _Ids(),
      activeKeyEpoch: () => keyManager.activeKeyEpoch ?? 1,
      headerRewriter: EnvelopeHeaderRewriter(primitive),
    );
    job = KeyRotationJob(
      keyManager: keyManager,
      epochBlobs: epochBlobs,
      blobStore: store,
      activeKeyEpoch: () => keyManager.activeKeyEpoch ?? 1,
    );
  });

  tearDown(() => root.delete(recursive: true));

  Future<BlobRef> writeSecret(List<int> bytes) async {
    final result = await store.write(
      Stream.value(bytes),
      storageClass: StorageClass.asset,
      expectedSize: bytes.length,
    );
    return result.fold((ref) {
      epochBlobs.rows[ref.id] = BlobEpochRef(
        id: ref.id,
        purpose: EnvelopePurpose.asset,
        keyEpoch: ref.keyEpoch,
      );
      epochBlobs.wrapped[ref.id] = ref.wrappedDek;
      return ref;
    }, (f) => throw StateError('$f ${f.cause}'));
  }

  test('rotation rewraps every header; bytes still open under the new epoch', () async {
    final secrets = [
      utf8.encode('passport-front ' * 100),
      utf8.encode('passport-back ' * 100),
      utf8.encode('signature ' * 100),
    ];
    final refs = [for (final s in secrets) await writeSecret(s)];
    expect(refs.every((r) => r.keyEpoch == 1), isTrue);

    // §8.6 steps 1–3: new master key, old epoch retired but readable.
    final rotated = await keyManager.rotate(
      pin: '1234',
      recoveryPassphrase: 'correct horse battery staple',
    );
    expect(rotated.isOk, isTrue, reason: '${rotated.errOrNull}');
    expect(keyManager.activeKeyEpoch, 2);

    // §8.6 step 4: the job rewrites every header.
    final report = (await job.run()).okOrNull!;
    expect(report.rewrapped, 3);
    expect(report.remaining, 0);
    expect(
      epochBlobs.rows.values.every((r) => r.keyEpoch == 2),
      isTrue,
      reason: 'every blob row moved to the new epoch',
    );

    // The bytes still open — the DEK is the same, rewrapped (§8.6 M9).
    for (var i = 0; i < refs.length; i++) {
      final read = await store.readSmall(refs[i].id, maxBytes: 64 * 1024);
      expect(read.okOrNull, secrets[i], reason: refs[i].id);
      // The row's wrapped DEK matches the file header's.
      final headerBytes = await File(
        p.join(root.path, refs[i].relPath.replaceAll('/', p.separator)),
      ).openRead(0, 512).fold<List<int>>([], (b, c) => b..addAll(c));
      final header = EnvelopeHeader.parse(Uint8List.fromList(headerBytes));
      expect(header.keyEpoch, 2);
      expect(header.wrappedDek, epochBlobs.wrapped[refs[i].id]);
    }

    // A new blob seals under epoch 2 from here on.
    final fresh = await writeSecret(utf8.encode('new scan ' * 100));
    expect(fresh.keyEpoch, 2);
  });

  test('rotation with a wrong PIN fails before anything is stored', () async {
    final before = (await keyring.loadEpochs()).okOrNull!;
    final result = await keyManager.rotate(
      pin: '9999',
      recoveryPassphrase: 'correct horse battery staple',
    );
    expect(result.isErr, isTrue);
    expect(
      (await keyring.loadEpochs()).okOrNull,
      hasLength(before.length),
      reason: 'no partial epoch survives a wrong PIN',
    );
  });
}
