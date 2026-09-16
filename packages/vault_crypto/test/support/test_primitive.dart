/// Test-only envelope primitive over `package:cryptography`.
///
/// Implements the SAME key schedule and framing contract as the native
/// Tink bridge so the envelope suite runs on any host:
///   K_<purpose>(epoch) = HKDF(rootKey, salt=∅, 'dokki/test/kek/<epoch>/<purpose>')
///   wrappedDek         = AES-GCM(K_<purpose>(epoch), zero-nonce, dek)
///   stream_key         = HKDF(dek, salt, 'dokki/envelope/v1/stream')
///   header_key         = HKDF(dek, salt, 'dokki/envelope/v1/header')
library;

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:vault_crypto/vault_crypto.dart';

final class TestEnvelopePrimitive implements EnvelopePrimitive {
  TestEnvelopePrimitive({List<int>? rootKey})
    : _rootKey = SecretKey(rootKey ?? List<int>.generate(32, (int i) => i));

  final SecretKey _rootKey;
  final Map<int, SecretKey> _sessionKeys = <int, SecretKey>{};
  int _nextKeyId = 1;

  static final AesGcm _gcm = AesGcm.with256bits();

  Future<SecretKey> _hkdf(
    SecretKey ikm,
    List<int>? salt,
    String info, {
    int length = 32,
  }) => Hkdf(hmac: Hmac.sha256(), outputLength: length).deriveKey(
    secretKey: ikm,
    nonce: salt ?? const <int>[],
    info: info.codeUnits,
  );

  Future<SecretKey> _kekFor(int epoch, int purpose) =>
      _hkdf(_rootKey, null, 'dokki/test/kek/$epoch/$purpose');

  Future<SecretKey> _streamKey(SecretKey dek, Uint8List salt) =>
      _hkdf(dek, salt, 'dokki/envelope/v1/stream');

  Future<SecretKey> _headerKey(SecretKey dek, Uint8List salt) =>
      _hkdf(dek, salt, 'dokki/envelope/v1/header');

  static Uint8List _concat(List<int> a, List<int> b, List<int> c) =>
      Uint8List.fromList([...a, ...b, ...c]);

  @override
  Future<BoundDek> generateAndBind({
    required int keyEpoch,
    required int purpose,
  }) async {
    final dek = await _gcm.newSecretKey();
    final kek = await _kekFor(keyEpoch, purpose);
    final box = await _gcm.encrypt(
      await dek.extractBytes(),
      secretKey: kek,
      nonce: Uint8List(12),
    );
    final wrapped = _concat(box.nonce, box.cipherText, box.mac.bytes);
    final keyId = _nextKeyId++;
    _sessionKeys[keyId] = dek;
    return BoundDek(wrappedDek: wrapped, keyId: keyId);
  }

  @override
  Future<int> bindWrapped({
    required Uint8List wrappedDek,
    required int keyEpoch,
    required int purpose,
  }) async {
    final kek = await _kekFor(keyEpoch, purpose);
    final List<int> dek;
    try {
      dek = await _gcm.decrypt(
        SecretBox(
          wrappedDek.sublist(12, wrappedDek.length - 16),
          nonce: wrappedDek.sublist(0, 12),
          mac: Mac(wrappedDek.sublist(wrappedDek.length - 16)),
        ),
        secretKey: kek,
      );
    } on SecretBoxAuthenticationError {
      throw const TagVerificationFailed();
    }
    final keyId = _nextKeyId++;
    _sessionKeys[keyId] = SecretKey(dek);
    return keyId;
  }

  @override
  Future<Uint8List> sealHeader(
    int keyId, {
    required Uint8List salt,
    required Uint8List aad,
  }) async {
    final dek = _session(keyId);
    final key = await _headerKey(dek, salt);
    // 16-byte tag over EMPTY plaintext. The header key is derived from the
    // DEK itself, so a valid tag already proves possession of the DEK;
    // encrypting the DEK inside its own header adds nothing.
    final box = await _gcm.encrypt(
      const <int>[],
      secretKey: key,
      nonce: Uint8List(12),
      aad: aad,
    );
    return Uint8List.fromList(box.mac.bytes);
  }

  @override
  Future<void> verifyHeader(
    int keyId, {
    required Uint8List salt,
    required Uint8List aad,
    required Uint8List tag,
  }) async {
    final dek = _session(keyId);
    final key = await _headerKey(dek, salt);
    try {
      await _gcm.decrypt(
        SecretBox(const <int>[], nonce: Uint8List(12), mac: Mac(tag)),
        secretKey: key,
        aad: aad,
      );
    } on SecretBoxAuthenticationError {
      throw const TagVerificationFailed();
    }
  }

  @override
  Future<Uint8List> encryptChunk(
    int keyId, {
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List plaintext,
  }) async {
    final key = await _streamKey(_session(keyId), salt);
    final box = await _gcm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    return _concat(box.cipherText, box.mac.bytes, const <int>[]);
  }

  @override
  Future<Uint8List> decryptChunk(
    int keyId, {
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List ciphertext,
  }) async {
    final key = await _streamKey(_session(keyId), salt);
    try {
      final plaintext = await _gcm.decrypt(
        SecretBox(
          ciphertext.sublist(0, ciphertext.length - 16),
          nonce: nonce,
          mac: Mac(ciphertext.sublist(ciphertext.length - 16)),
        ),
        secretKey: key,
        aad: aad,
      );
      return Uint8List.fromList(plaintext);
    } on SecretBoxAuthenticationError {
      throw const TagVerificationFailed();
    }
  }

  @override
  Future<void> release(int keyId) async {
    _sessionKeys.remove(keyId);
  }

  SecretKey _session(int keyId) {
    final key = _sessionKeys[keyId];
    if (key == null) {
      throw StateError('Unknown key id $keyId');
    }
    return key;
  }
}
