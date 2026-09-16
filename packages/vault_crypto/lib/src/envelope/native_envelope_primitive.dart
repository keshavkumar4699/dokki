/// Production primitive: delegates every op to the Kotlin/Tink bridge.
library;

import 'dart:typed_data';

import 'package:platform_android/platform_android.dart';

import '../error_boundary.dart';
import 'envelope_primitive.dart';

final class NativeEnvelopePrimitive implements EnvelopePrimitive {
  const NativeEnvelopePrimitive(this.bridge);

  final NativeCryptoBridge bridge;

  @override
  Future<BoundDek> generateAndBind({
    required int keyEpoch,
    required int purpose,
  }) async {
    final dek = await bridge.generateAndBind(
      keyEpoch: keyEpoch,
      purpose: purpose,
    );
    return BoundDek(wrappedDek: dek.wrappedDek, keyId: dek.keyId);
  }

  @override
  Future<int> bindWrapped({
    required Uint8List wrappedDek,
    required int keyEpoch,
    required int purpose,
  }) => bridge.bindWrappedDek(
    wrappedDek: wrappedDek,
    keyEpoch: keyEpoch,
    purpose: purpose,
  );

  @override
  Future<Uint8List> sealHeader(
    int keyId, {
    required Uint8List salt,
    required Uint8List aad,
  }) => bridge.sealHeader(keyId: keyId, salt: salt, aad: aad);

  @override
  Future<void> verifyHeader(
    int keyId, {
    required Uint8List salt,
    required Uint8List aad,
    required Uint8List tag,
  }) => guardAead(
    () => bridge.verifyHeader(keyId: keyId, salt: salt, aad: aad, tag: tag),
  );

  @override
  Future<Uint8List> encryptChunk(
    int keyId, {
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List plaintext,
  }) => bridge.encrypt(
    keyId: keyId,
    salt: salt,
    nonce: nonce,
    aad: aad,
    plaintext: plaintext,
  );

  @override
  Future<Uint8List> decryptChunk(
    int keyId, {
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List ciphertext,
  }) => guardAead(
    () => bridge.decrypt(
      keyId: keyId,
      salt: salt,
      nonce: nonce,
      aad: aad,
      ciphertext: ciphertext,
    ),
  );

  @override
  Future<void> release(int keyId) => bridge.releaseKey(keyId);
}
