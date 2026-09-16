/// `FileBlobStore` against a temp directory with the real envelope cipher
/// over the Dart primitive: atomic writes, opaque layout, sealed at rest,
/// tamper rejection, and the GC sweep.
library;

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
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

void main() {
  late Directory root;
  late FileBlobStore store;
  late DartEnvelopePrimitive primitive;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dokki_blobs_');
    primitive = DartEnvelopePrimitive()
      ..bindMasterKey(1, SecretKey(List<int>.generate(32, (i) => i)));
    final cipher = EnvelopeCipher(primitive: primitive, random: _Random());
    store = FileBlobStore(
      rootDir: root.path,
      crypto: CryptoEngineImpl(cipher: cipher, activeKeyEpoch: () => 1),
      ids: _Ids(),
      activeKeyEpoch: () => 1,
    );
  });

  tearDown(() => root.delete(recursive: true));

  final secret = utf8.encode('PASSPORT-NUMBER-X1234567 ' * 200);

  Future<BlobRef> writeSecret({StorageClass cls = StorageClass.asset}) async {
    final result = await store.write(
      Stream.fromIterable([secret.sublist(0, 1000), secret.sublist(1000)]),
      storageClass: cls,
      expectedSize: secret.length,
    );
    return result.fold((ref) => ref, (f) => throw StateError('$f ${f.cause}'));
  }

  test('write seals to blobs/<fanout>/<id> with an opaque name', () async {
    final ref = await writeSecret();
    expect(ref.relPath, 'blobs/ab/${ref.id}');
    expect(ref.plaintextSize, secret.length);
    expect(ref.ciphertextSize, greaterThan(secret.length));
    expect(ref.keyEpoch, 1);
    expect(ref.wrappedDek, isNotEmpty);
    expect(ref.plaintextSha256, hasLength(64));
    expect(ref.ciphertextSha256, hasLength(64));
    final file = File(p.join(root.path, 'blobs', 'ab', ref.id));
    expect(file.existsSync(), isTrue);
    expect(File('${file.path}.part').existsSync(), isFalse);
  });

  test('no plaintext byte of user content exists on disk', () async {
    await writeSecret();
    for (final entity in root.listSync(recursive: true)) {
      if (entity is File) {
        final bytes = entity.readAsBytesSync();
        expect(
          latin1.decode(bytes, allowInvalid: true),
          isNot(contains('PASSPORT')),
        );
        expect(bytes.sublist(0, 5), 'PVLT1'.codeUnits);
      }
    }
  });

  test('openRead + openPlaintext round-trips the bytes', () async {
    final ref = await writeSecret();
    final handle = (await store.openRead(ref.id)).okOrNull!;
    expect(handle.token, ref.id);
    final out = <int>[];
    await store.openPlaintext(handle).forEach(out.addAll);
    expect(out, secret);
  });

  test('copyPlaintextTo writes the decrypted file atomically', () async {
    final ref = await writeSecret(cls: StorageClass.exportArtifact);
    final cache = ShareCache(p.join(root.path, 'export_tmp'));
    final target = cache.pathFor('share.jpg');
    final written = (await store.copyPlaintextTo(ref.id, target)).okOrNull!;
    expect(written, secret.length);
    expect(File(target).readAsBytesSync(), secret);
    expect(File('$target.part').existsSync(), isFalse);

    // The cache is the only place plaintext may live, and it is swept.
    expect((await cache.discard(target)).isOk, isTrue);
    expect(File(target).existsSync(), isFalse);
    File(cache.pathFor('left-over.png')).writeAsBytesSync(const [1, 2]);
    expect((await cache.sweep()).okOrNull, 1);
    expect(Directory(cache.directory).listSync(), isEmpty);
    // Anything outside the cache is refused.
    final outside = p.join(root.path, 'blobs', 'x');
    expect((await cache.discard(outside)).errOrNull, isA<InvalidAsset>());
  });

  test('copyPlaintextTo of an unknown blob is CorruptFile', () async {
    final result = await store.copyPlaintextTo(
      'nope',
      p.join(root.path, 'export_tmp', 'x'),
    );
    expect(result.errOrNull, isA<CorruptFile>());
  });

  test('readSmall honours its cap', () async {
    final ref = await writeSecret();
    final small = await store.readSmall(ref.id, maxBytes: 100);
    expect(small.errOrNull, isA<InvalidAsset>());
    final full = await store.readSmall(ref.id);
    expect(full.okOrNull, secret);
  });

  test(
    'a flipped ciphertext byte is DecryptionFailed(tamperSuspected)',
    () async {
      final ref = await writeSecret();
      final file = File(p.join(root.path, 'blobs', 'ab', ref.id));
      final bytes = file.readAsBytesSync();
      bytes[bytes.length - 40] ^= 0x01;
      file.writeAsBytesSync(bytes);
      final verified = await store.verify(ref.id);
      final failure = verified.errOrNull;
      expect(failure, isA<DecryptionFailed>());
      expect((failure! as DecryptionFailed).tamperSuspected, isTrue);
      final read = await store.readSmall(ref.id);
      expect(read.isErr, isTrue);
    },
  );

  test('purge removes the file; exists reports it', () async {
    final ref = await writeSecret();
    expect((await store.exists(ref.id)).okOrNull, isTrue);
    expect((await store.purge(ref.id)).isOk, isTrue);
    expect((await store.exists(ref.id)).okOrNull, isFalse);
    expect((await store.openRead(ref.id)).errOrNull, isA<CorruptFile>());
  });

  test(
    'thumbnails live under thumbs/ and are sealed with purpose THUMB',
    () async {
      final ref = await writeSecret(cls: StorageClass.thumbnail);
      expect(ref.relPath, startsWith('thumbs/'));
      final header = EnvelopeHeader.parse(
        File(p.join(root.path, 'thumbs', 'ab', ref.id)).readAsBytesSync(),
      );
      expect(header.purpose, EnvelopePurpose.thumbnail);
      // The handle carries the class so the right K_<purpose> is used.
      final handle = (await store.openRead(ref.id)).okOrNull! as FileBlobHandle;
      expect(handle.storageClass, StorageClass.thumbnail);
      final out = <int>[];
      await store.openPlaintext(handle).forEach(out.addAll);
      expect(out, secret);
    },
  );

  test('a failed write leaves no .part file behind', () async {
    final result = await store.write(
      Stream<List<int>>.error(const FileSystemException('disk gone')),
      storageClass: StorageClass.asset,
      expectedSize: 10,
    );
    expect(result.errOrNull, isA<StorageIoFailure>());
    final leftovers = root.listSync(recursive: true).whereType<File>();
    expect(leftovers, isEmpty);
  });

  test('a cancelled write is OperationCancelled and leaves nothing', () async {
    final token = CancellationToken();
    final result = await store.write(
      Stream<List<int>>.fromIterable([
        [1, 2, 3],
        [4, 5, 6],
      ]).map((c) {
        token.cancel();
        return c;
      }),
      storageClass: StorageClass.asset,
      expectedSize: 6,
      cancel: token,
    );
    expect(result.errOrNull, isA<OperationCancelled>());
    expect(root.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('sweepPartialWrites removes crash leftovers only', () async {
    final ref = await writeSecret();
    final orphan = File(p.join(root.path, 'blobs', 'zz', 'dead.part'))
      ..createSync(recursive: true)
      ..writeAsStringSync('half');
    final swept = await store.sweepPartialWrites();
    expect(swept.okOrNull, 1);
    expect(orphan.existsSync(), isFalse);
    expect((await store.exists(ref.id)).okOrNull, isTrue);
    expect((await store.listBlobIds()).okOrNull, {ref.id});
  });

  test('a locked primitive cannot read what it wrote', () async {
    final ref = await writeSecret();
    primitive.clear();
    final read = await store.readSmall(ref.id);
    expect(read.errOrNull, isA<KeyUnavailable>());
  });
}
