/// DEVELOPMENT-ONLY envelope primitive over `package:cryptography`.
///
/// ⚠ This holds key material in the Dart heap, which the architecture
/// forbids for production (§8.4, M10). It exists so the app runs end to
/// end on any host before the Kotlin/Tink bridge (`platform_android`) is
/// implemented. The composition root must select `NativeEnvelopePrimitive`
/// for release builds; a debug banner surfaces which one is active.
///
/// Key schedule (mirrors what the native side derives from MK, §8.1):
///   K_<purpose>(epoch) = HKDF-SHA256(MK[epoch], info='dokki/kek/v1/<epoch>/<purpose>')
///   wrapped_dek        = nonce(12) || AES-256-GCM(K_<purpose>, dek) || tag(16)
///   stream_key         = HKDF-SHA256(dek, salt, 'dokki/envelope/v1/stream')
///   header_key         = HKDF-SHA256(dek, salt, 'dokki/envelope/v1/header')
library;

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../envelope/envelope_primitive.dart';

final class DartEnvelopePrimitive implements EnvelopePrimitive {
  DartEnvelopePrimitive();

  /// Master keys by epoch, bound at unlock and dropped at lock.
  final Map<int, SecretKey> _masterKeys = <int, SecretKey>{};

  final Map<int, SecretKey> _sessionKeys = <int, SecretKey>{};
  int _nextKeyId = 1;

  static final AesGcm _gcm = AesGcm.with256bits();

  bool get isBound => _masterKeys.isNotEmpty;

  /// Binds the master key for [epoch]. Called by `DartKeyManager.unlock`.
  void bindMasterKey(int epoch, SecretKey masterKey) =>
      _masterKeys[epoch] = masterKey;

  /// Drops every key. Dart cannot zero memory; this is best effort (§8.4).
  void clear() {
    _masterKeys.clear();
    _sessionKeys.clear();
  }

  Future<SecretKey> _hkdf(SecretKey ikm, List<int> salt, String info) => Hkdf(
    hmac: Hmac.sha256(),
    outputLength: 32,
  ).deriveKey(secretKey: ikm, nonce: salt, info: info.codeUnits);

  Future<SecretKey> _kekFor(int epoch, int purpose) {
    final master = _masterKeys[epoch];
    if (master == null) {
      throw StateError('vault locked or no key for epoch $epoch');
    }
    return _hkdf(master, const <int>[], 'dokki/kek/v1/$epoch/$purpose');
  }

  @override
  Future<BoundDek> generateAndBind({
    required int keyEpoch,
    required int purpose,
  }) async {
    final dek = await _gcm.newSecretKey();
    final kek = await _kekFor(keyEpoch, purpose);
    final box = await _gcm.encrypt(await dek.extractBytes(), secretKey: kek);
    final wrapped = Uint8List.fromList([
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
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
    if (wrappedDek.length < 28) {
      throw const TagVerificationFailed();
    }
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

  /// §8.6 rewrap job: unwrap a DEK under `K_<purpose>(fromEpoch)` and
  /// rewrap it under `K_<purpose>(toEpoch)`. Both epochs must be bound.
  Future<Uint8List> rewrap({
    required Uint8List wrappedDek,
    required int fromEpoch,
    required int toEpoch,
    required int purpose,
  }) async {
    final oldKek = await _kekFor(fromEpoch, purpose);
    final List<int> dek;
    try {
      dek = await _gcm.decrypt(
        SecretBox(
          wrappedDek.sublist(12, wrappedDek.length - 16),
          nonce: wrappedDek.sublist(0, 12),
          mac: Mac(wrappedDek.sublist(wrappedDek.length - 16)),
        ),
        secretKey: oldKek,
      );
    } on SecretBoxAuthenticationError {
      throw const TagVerificationFailed();
    }
    final newKek = await _kekFor(toEpoch, purpose);
    final box = await _gcm.encrypt(dek, secretKey: newKek);
    return Uint8List.fromList([
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  @override
  Future<Uint8List> sealHeader(
    int keyId, {
    required Uint8List salt,
    required Uint8List aad,
  }) async {
    final key = await _hkdf(_session(keyId), salt, 'dokki/envelope/v1/header');
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
    final key = await _hkdf(_session(keyId), salt, 'dokki/envelope/v1/header');
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
    final key = await _hkdf(_session(keyId), salt, 'dokki/envelope/v1/stream');
    final box = await _gcm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  @override
  Future<Uint8List> decryptChunk(
    int keyId, {
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List ciphertext,
  }) async {
    if (ciphertext.length < 16) {
      throw const TagVerificationFailed();
    }
    final key = await _hkdf(_session(keyId), salt, 'dokki/envelope/v1/stream');
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
