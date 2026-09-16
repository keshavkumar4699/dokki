/// `EnvelopeCipher`: pure-Dart streaming framing over [EnvelopePrimitive].
///
/// All format logic lives here: header build/parse, chunk layout, nonce
/// and AAD construction, final-chunk flag, truncation detection. The
/// actual AES-GCM ops are delegated to the primitive, so this class is
/// fully testable on any host with a fake primitive (see `test/`).
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:vault_domain/vault_domain.dart'
    show EnvelopePurpose, RandomSource;

import 'envelope_format.dart';
import 'envelope_primitive.dart';

final class EnvelopeCipher {
  EnvelopeCipher({required this.primitive, required this.random});

  final EnvelopePrimitive primitive;
  final RandomSource random;

  /// Seals [plaintext] under `K_<purpose>(epoch)`. Emits the header first,
  /// then 256 KiB ciphertext chunks, always ending with an explicit final
  /// chunk (possibly empty) so truncation is detectable on open.
  Stream<List<int>> sealStream(
    Stream<List<int>> plaintext, {
    required int keyEpoch,
    required EnvelopePurpose purpose,
    bool compress = false,
  }) async* {
    final bound = await primitive.generateAndBind(
      keyEpoch: keyEpoch,
      purpose: purpose.byte,
    );
    final salt = _randomBytes(16);
    final header = await _buildHeader(
      keyId: bound.keyId,
      salt: salt,
      keyEpoch: keyEpoch,
      purpose: purpose,
      wrappedDek: bound.wrappedDek,
      compress: compress,
    );
    yield header;

    final saltPrefix = salt.sublist(0, 7);
    final headerTag = header.sublist(header.length - 16);
    var counter = 0;
    var carry = <int>[];
    await for (final chunk in plaintext) {
      var offset = 0;
      if (carry.isNotEmpty) {
        final need = chunkSize - carry.length;
        if (chunk.length >= need) {
          carry.addAll(chunk.sublist(0, need));
          offset = need;
          yield await _encryptChunk(
            keyId: bound.keyId,
            salt: salt,
            saltPrefix: saltPrefix,
            counter: counter++,
            finalFlag: 0,
            headerTag: headerTag,
            plaintext: carry,
          );
          carry = <int>[];
        } else {
          carry.addAll(chunk);
          continue;
        }
      }
      while (chunk.length - offset >= chunkSize) {
        yield await _encryptChunk(
          keyId: bound.keyId,
          salt: salt,
          saltPrefix: saltPrefix,
          counter: counter++,
          finalFlag: 0,
          headerTag: headerTag,
          plaintext: chunk.sublist(offset, offset + chunkSize),
        );
        offset += chunkSize;
      }
      if (offset < chunk.length) {
        // Copy into a growable list: a Uint8List sublist is fixed-length
        // and the next chunk is appended to it.
        carry = List<int>.of(chunk.sublist(offset));
      }
    }
    // The explicit final chunk: plaintext length is always < chunkSize
    // here (possibly 0), so the final flag is unambiguous.
    yield await _encryptChunk(
      keyId: bound.keyId,
      salt: salt,
      saltPrefix: saltPrefix,
      counter: counter,
      finalFlag: 1,
      headerTag: headerTag,
      plaintext: carry,
    );
  }

  /// Seals a whole small payload (< 256 KiB) in memory. Returns the
  /// wrapped DEK (persist it in the blob row) and the ciphertext bytes.
  Future<SealedBytes> sealSmall(
    List<int> plaintext, {
    required int keyEpoch,
    required EnvelopePurpose purpose,
  }) async {
    final bound = await primitive.generateAndBind(
      keyEpoch: keyEpoch,
      purpose: purpose.byte,
    );
    final salt = _randomBytes(16);
    final header = await _buildHeader(
      keyId: bound.keyId,
      salt: salt,
      keyEpoch: keyEpoch,
      purpose: purpose,
      wrappedDek: bound.wrappedDek,
      compress: false,
    );
    final body = await _encryptChunk(
      keyId: bound.keyId,
      salt: salt,
      saltPrefix: salt.sublist(0, 7),
      counter: 0,
      finalFlag: 1,
      headerTag: header.sublist(header.length - 16),
      plaintext: plaintext,
    );
    return SealedBytes(
      wrappedDek: bound.wrappedDek,
      ciphertext: [...header, ...body],
    );
  }

  /// Opens a sealed stream, verifying integrity end-to-end.
  ///
  /// Throws [FormatException] on ANY violation — bad magic, version, alg,
  /// reorder, truncation, or tag mismatch — and never yields partial
  /// plaintext.
  Stream<List<int>> openStream(
    Stream<List<int>> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  }) async* {
    final iterator = StreamIterator<List<int>>(ciphertext);
    // Whatever happens below, the source subscription is cancelled so a
    // failed open never leaves a file handle behind.
    try {
      yield* _openWith(iterator, expectedPurpose: expectedPurpose);
    } finally {
      await iterator.cancel();
    }
  }

  Stream<List<int>> _openWith(
    StreamIterator<List<int>> iterator, {
    required EnvelopePurpose expectedPurpose,
  }) async* {
    final read = await _readHeader(iterator);
    final headerBytes = read.header;
    final header = EnvelopeHeader.parse(headerBytes);
    if (header.purpose != expectedPurpose) {
      throw const FormatException('Envelope purpose mismatch');
    }
    final keyId = await primitive.bindWrapped(
      wrappedDek: header.wrappedDek,
      keyEpoch: header.keyEpoch,
      purpose: header.purpose.byte,
    );
    try {
      await primitive.verifyHeader(
        keyId,
        salt: header.streamSalt,
        aad: headerBytes.sublist(0, headerBytes.length - 16),
        tag: header.headerTag,
      );

      final saltPrefix = header.streamSalt.sublist(0, 7);
      final headerTag = header.headerTag;
      final buffered = <int>[...read.leftover];

      // Reassembles one envelope chunk from arbitrarily-sized stream
      // chunks. A chunk of exactly chunkSize+16 bytes is non-final; a
      // shorter one (only possible at end of stream) is final.
      Future<List<int>> nextEnvelopeChunk() async {
        while (buffered.length < chunkSize + 16) {
          if (!await iterator.moveNext()) {
            if (buffered.isEmpty) {
              throw const FormatException('Truncated: missing final chunk');
            }
            final rest = List<int>.of(buffered);
            buffered.clear();
            return rest;
          }
          buffered.addAll(iterator.current);
        }
        final full = buffered.sublist(0, chunkSize + 16);
        buffered.removeRange(0, chunkSize + 16);
        return full;
      }

      var counter = 0;
      while (true) {
        final current = await nextEnvelopeChunk();
        final finalFlag = current.length < chunkSize + 16 ? 1 : 0;
        final plaintext = await primitive.decryptChunk(
          keyId,
          salt: header.streamSalt,
          nonce: _chunkNonce(saltPrefix, counter, finalFlag),
          aad: _chunkAad(headerTag, counter, finalFlag),
          ciphertext: Uint8List.fromList(current),
        );
        if (finalFlag == 0 && plaintext.length != chunkSize) {
          throw const FormatException('Non-final chunk has invalid size');
        }
        yield plaintext;
        counter++;
        if (finalFlag == 1) {
          // Nothing may follow the final chunk.
          if (buffered.isNotEmpty || await iterator.moveNext()) {
            throw const FormatException('Data after final chunk');
          }
          return;
        }
      }
    } finally {
      // TagVerificationFailed propagates as-is: it is the tamper signal the
      // error boundary turns into DecryptionFailed(tamperSuspected) (T12).
      await primitive.release(keyId);
    }
  }

  /// Opens a whole small payload in memory.
  Future<List<int>> openSmall(
    List<int> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  }) async {
    final buffer = <int>[];
    await openStream(
      Stream<List<int>>.value(ciphertext),
      expectedPurpose: expectedPurpose,
    ).forEach(buffer.addAll);
    return buffer;
  }

  Future<Uint8List> _buildHeader({
    required int keyId,
    required Uint8List salt,
    required int keyEpoch,
    required EnvelopePurpose purpose,
    required Uint8List wrappedDek,
    required bool compress,
  }) async {
    final withoutTag = EnvelopeHeader(
      headerVersion: envelopeVersion,
      algorithmId: algId,
      compressed: compress,
      keyEpoch: keyEpoch,
      purpose: purpose,
      wrappedDek: wrappedDek,
      streamSalt: salt,
      headerTag: Uint8List(16),
    ).bytesWithoutTag();
    final tag = await primitive.sealHeader(keyId, salt: salt, aad: withoutTag);
    return EnvelopeHeader(
      headerVersion: envelopeVersion,
      algorithmId: algId,
      compressed: compress,
      keyEpoch: keyEpoch,
      purpose: purpose,
      wrappedDek: wrappedDek,
      streamSalt: salt,
      headerTag: tag,
    ).toBytes();
  }

  Future<Uint8List> _encryptChunk({
    required int keyId,
    required Uint8List salt,
    required Uint8List saltPrefix,
    required int counter,
    required int finalFlag,
    required Uint8List headerTag,
    required List<int> plaintext,
  }) => primitive.encryptChunk(
    keyId,
    salt: salt,
    nonce: _chunkNonce(saltPrefix, counter, finalFlag),
    aad: _chunkAad(headerTag, counter, finalFlag),
    plaintext: Uint8List.fromList(plaintext),
  );

  Uint8List _chunkNonce(Uint8List saltPrefix, int counter, int finalFlag) {
    final nonce = Uint8List(12)..setRange(0, 7, saltPrefix);
    ByteData.sublistView(nonce).setUint32(7, counter);
    nonce[11] = finalFlag;
    return nonce;
  }

  Uint8List _chunkAad(Uint8List headerTag, int counter, int finalFlag) {
    final aad = Uint8List(21)..setRange(0, 16, headerTag);
    ByteData.sublistView(aad).setUint32(16, counter);
    aad[20] = finalFlag;
    return aad;
  }

  Uint8List _randomBytes(int length) {
    final out = Uint8List(length);
    random.fillBytes(out);
    return out;
  }

  Future<_HeaderRead> _readHeader(StreamIterator<List<int>> iterator) async {
    final buffer = <int>[];
    while (buffer.length < 15) {
      if (!await iterator.moveNext()) {
        throw const FormatException('Truncated: no complete header');
      }
      buffer.addAll(iterator.current);
    }
    final data = ByteData.sublistView(Uint8List.fromList(buffer));
    final wrappedLen = data.getUint16(13);
    final total = 15 + wrappedLen + 32;
    while (buffer.length < total) {
      if (!await iterator.moveNext()) {
        throw const FormatException('Truncated: header incomplete');
      }
      buffer.addAll(iterator.current);
    }
    return _HeaderRead(
      header: Uint8List.fromList(buffer.sublist(0, total)),
      leftover: buffer.sublist(total),
    );
  }
}

/// The result of reading an envelope header: the header bytes plus any
/// body bytes that arrived in the same stream chunk.
final class _HeaderRead {
  const _HeaderRead({required this.header, required this.leftover});

  final Uint8List header;
  final List<int> leftover;
}

/// The result of an in-memory seal.
final class SealedBytes {
  const SealedBytes({required this.wrappedDek, required this.ciphertext});

  final Uint8List wrappedDek;
  final List<int> ciphertext;
}
