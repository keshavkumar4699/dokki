/// The envelope test suite (§13.4): round-trips across chunk boundaries,
/// the tamper matrix, truncation, reorder, purpose/version/alg rejection,
/// and the engine wrappers.
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vault_crypto/vault_crypto.dart';
import 'package:vault_domain/vault_domain.dart';

import 'support/test_primitive.dart';

final class _SeededRandom implements RandomSource {
  _SeededRandom();

  int _seed = 42;

  @override
  void fillBytes(List<int> out) {
    for (var i = 0; i < out.length; i++) {
      _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
      out[i] = _seed & 0xFF;
    }
  }

  @override
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed % max;
  }
}

EnvelopeCipher _cipher() =>
    EnvelopeCipher(primitive: TestEnvelopePrimitive(), random: _SeededRandom());

List<int> _pattern(int length) =>
    List<int>.generate(length, (int i) => i % 251);

Future<List<int>> _seal(
  EnvelopeCipher cipher,
  List<int> plaintext, {
  int streamChunkSize = 777,
}) async {
  final chunks = <List<int>>[];
  for (var i = 0; i < plaintext.length; i += streamChunkSize) {
    chunks.add(
      plaintext.sublist(
        i,
        i + streamChunkSize > plaintext.length
            ? plaintext.length
            : i + streamChunkSize,
      ),
    );
  }
  final sealed = <int>[];
  await cipher
      .sealStream(
        Stream<List<int>>.fromIterable(chunks),
        keyEpoch: 1,
        purpose: EnvelopePurpose.asset,
      )
      .forEach(sealed.addAll);
  return sealed;
}

Future<List<int>> _open(
  EnvelopeCipher cipher,
  List<int> sealed, {
  int streamChunkSize = 913,
}) async {
  final chunks = <List<int>>[];
  for (var i = 0; i < sealed.length; i += streamChunkSize) {
    chunks.add(
      sealed.sublist(
        i,
        i + streamChunkSize > sealed.length
            ? sealed.length
            : i + streamChunkSize,
      ),
    );
  }
  final opened = <int>[];
  await cipher
      .openStream(
        Stream<List<int>>.fromIterable(chunks),
        expectedPurpose: EnvelopePurpose.asset,
      )
      .forEach(opened.addAll);
  return opened;
}

void main() {
  group('round-trip (P9)', () {
    test(
      'many small Uint8List chunks are concatenated into one seal',
      () async {
        // Regression: a fixed-length sublist used as the carry buffer threw
        // on the second chunk. File streams arrive exactly like this.
        final cipher = _cipher();
        final plaintext = _pattern(5000);
        final chunks = <List<int>>[
          for (var i = 0; i < plaintext.length; i += 1000)
            Uint8List.fromList(plaintext.sublist(i, i + 1000)),
        ];
        final sealed = <int>[];
        await cipher
            .sealStream(
              Stream<List<int>>.fromIterable(chunks),
              keyEpoch: 1,
              purpose: EnvelopePurpose.asset,
            )
            .forEach(sealed.addAll);
        expect(await _open(cipher, sealed), plaintext);
      },
    );

    for (final size in [
      0,
      1,
      255,
      chunkSize - 1,
      chunkSize,
      chunkSize + 1,
      3 * chunkSize + 12345,
    ]) {
      test('size $size', () async {
        final cipher = _cipher();
        final plaintext = _pattern(size);
        final sealed = await _seal(cipher, plaintext);
        expect(await _open(cipher, sealed), plaintext);
      });
    }

    test(
      'sealSmall/openSmall round-trips with self-contained wrapped DEK',
      () async {
        final cipher = _cipher();
        final sealed = await cipher.sealSmall(
          _pattern(5000),
          keyEpoch: 1,
          purpose: EnvelopePurpose.keyring,
        );
        // A DIFFERENT cipher instance (fresh native session) can open it:
        // the wrapped DEK travels in the header.
        final other = _cipher();
        final opened = await other.openSmall(
          sealed.ciphertext,
          expectedPurpose: EnvelopePurpose.keyring,
        );
        expect(opened, _pattern(5000));
      },
    );
  });

  group('tamper matrix (P10)', () {
    Future<List<int>> sealedFor() async {
      final sealed = await _seal(_cipher(), _pattern(chunkSize + 5000));
      return sealed;
    }

    /// Byte offset of the first body byte, parsed from the header.
    int bodyStartOf(List<int> sealed) {
      final header = EnvelopeHeader.parse(
        Uint8List.fromList(sealed.sublist(0, 200)),
      );
      return header.wrappedDek.length + 15 + 32;
    }

    Future<void> expectTamperFailure(
      List<int> sealed,
      int Function(int offset) mutate,
    ) async {
      final mutated = List<int>.of(sealed);
      final offset = mutate(sealed.length);
      mutated[offset] ^= 0x01;
      await expectLater(_open(_cipher(), mutated), throwsA(isA<Exception>()));
    }

    test('magic', () async => expectTamperFailure(await sealedFor(), (_) => 0));
    test('envelope version', () async {
      final sealed = await sealedFor();
      final mutated = List<int>.of(sealed)..[5] = 0x02;
      await expectLater(_open(_cipher(), mutated), throwsFormatException);
    });
    test('alg_id', () async {
      final sealed = await sealedFor();
      final mutated = List<int>.of(sealed)..[6] = 0x77;
      await expectLater(_open(_cipher(), mutated), throwsFormatException);
    });
    test(
      'key_epoch',
      () async => expectTamperFailure(await sealedFor(), (_) => 8),
    );
    test(
      'wrapped_dek',
      () async => expectTamperFailure(await sealedFor(), (_) => 20),
    );
    test('stream_salt', () async {
      final sealed = await sealedFor();
      await expectTamperFailure(sealed, (_) => bodyStartOf(sealed) - 32 + 3);
    });
    test('header_tag', () async {
      final sealed = await sealedFor();
      await expectTamperFailure(sealed, (_) => bodyStartOf(sealed) - 1);
    });
    test('chunk 0 ciphertext', () async {
      final sealed = await sealedFor();
      await expectTamperFailure(sealed, (_) => bodyStartOf(sealed) + 100);
    });
    test('chunk 0 tag', () async {
      final sealed = await sealedFor();
      await expectTamperFailure(
        sealed,
        (_) => bodyStartOf(sealed) + chunkSize + 8,
      );
    });
    test('last chunk tag', () async {
      final sealed = await sealedFor();
      await expectTamperFailure(sealed, (_) => sealed.length - 2);
    });
  });

  group('truncation', () {
    Future<void> expectTruncationFailure(int cut) async {
      final sealed = await _seal(_cipher(), _pattern(chunkSize + 1234));
      final truncated = sealed.sublist(0, sealed.length - cut);
      await expectLater(_open(_cipher(), truncated), throwsA(isA<Exception>()));
    }

    test(
      'remove the final chunk entirely',
      () => expectTruncationFailure(1234 + 16),
    );
    test('remove the final tag', () => expectTruncationFailure(1));
    test('truncate mid-chunk', () => expectTruncationFailure(500));
    test('truncate inside the header', () async {
      final sealed = await _seal(_cipher(), _pattern(100));
      await expectLater(
        _open(_cipher(), sealed.sublist(0, 10)),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('reorder', () {
    test('swapping chunk 1 and 2 fails', () async {
      final sealed = await _seal(_cipher(), _pattern(3 * chunkSize + 100));
      final header = EnvelopeHeader.parse(
        Uint8List.fromList(sealed.sublist(0, 200)),
      );
      final bodyStart = header.wrappedDek.length + 15 + 32;
      final chunk0 = sealed.sublist(bodyStart, bodyStart + chunkSize + 16);
      final chunk1 = sealed.sublist(
        bodyStart + chunkSize + 16,
        bodyStart + 2 * (chunkSize + 16),
      );
      final rest = sealed.sublist(bodyStart + 2 * (chunkSize + 16));
      final reordered = [
        ...sealed.sublist(0, bodyStart),
        ...chunk1,
        ...chunk0,
        ...rest,
      ];
      await expectLater(_open(_cipher(), reordered), throwsA(isA<Exception>()));
    });
  });

  group('header policy rejections', () {
    test('purpose mismatch fails', () async {
      final sealed = await _seal(_cipher(), _pattern(100));
      expect(await _open(_cipher(), sealed), isA<List<int>>());
      // Same bytes opened as a DIFFERENT purpose must fail.
      await expectLater(() async {
        await for (final _ in _cipher().openStream(
          Stream<List<int>>.value(sealed),
          expectedPurpose: EnvelopePurpose.thumbnail,
        )) {}
      }, throwsFormatException);
    });
  });

  group('CryptoEngineImpl', () {
    test('sealSmall/openSmall return Result values', () async {
      final engine = CryptoEngineImpl(
        cipher: _cipher(),
        activeKeyEpoch: () => 1,
      );
      final sealed = await engine.sealSmall(
        _pattern(3000),
        keyEpoch: 1,
        purpose: EnvelopePurpose.logSegment,
      );
      expect(sealed.isOk, isTrue);
      final opened = await engine.openSmall(
        sealed.okOrNull!,
        expectedPurpose: EnvelopePurpose.logSegment,
      );
      expect(opened.okOrNull, _pattern(3000));
    });

    test('openSmall of tampered data returns Err(DecryptionFailed)', () async {
      final engine = CryptoEngineImpl(
        cipher: _cipher(),
        activeKeyEpoch: () => 1,
      );
      final sealed = await engine.sealSmall(
        _pattern(3000),
        keyEpoch: 1,
        purpose: EnvelopePurpose.logSegment,
      );
      final tampered = List<int>.of(sealed.okOrNull!)..[100] ^= 0xFF;
      final opened = await engine.openSmall(
        tampered,
        expectedPurpose: EnvelopePurpose.logSegment,
      );
      expect(opened.isErr, isTrue);
      final failure = opened.errOrNull;
      expect(failure, isA<DecryptionFailed>());
      // T12: a failed GCM tag is a tamper signal, never a plain format error.
      expect((failure! as DecryptionFailed).tamperSuspected, isTrue);
    });

    test('ciphertextSha256 is stable and hex', () async {
      final engine = CryptoEngineImpl(
        cipher: _cipher(),
        activeKeyEpoch: () => 1,
      );
      final sealed = await engine.sealSmall(
        _pattern(100),
        keyEpoch: 1,
        purpose: EnvelopePurpose.keyring,
      );
      final hash = await engine.ciphertextSha256(
        Stream<List<int>>.value(sealed.okOrNull!),
      );
      expect(hash.isOk, isTrue);
      expect(hash.okOrNull, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('verifyStream passes on intact data, fails on tampered', () async {
      final engine = CryptoEngineImpl(
        cipher: _cipher(),
        activeKeyEpoch: () => 1,
      );
      final sealed = await engine.sealSmall(
        _pattern(2000),
        keyEpoch: 1,
        purpose: EnvelopePurpose.exportArtifact,
      );
      final good = await engine.verifyStream(
        Stream<List<int>>.value(sealed.okOrNull!),
        expectedPurpose: EnvelopePurpose.exportArtifact,
      );
      expect(good.isOk, isTrue);
      final tampered = List<int>.of(sealed.okOrNull!)..[200] ^= 0x01;
      final bad = await engine.verifyStream(
        Stream<List<int>>.value(tampered),
        expectedPurpose: EnvelopePurpose.exportArtifact,
      );
      expect(bad.isErr, isTrue);
      expect(bad.errOrNull, isA<DecryptionFailed>());
    });
  });
}
