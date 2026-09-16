/// Envelope-v1 crypto primitives, executed natively (Tink AES-GCM, HKDF).
///
/// Chunk-level AES-256-GCM with OUR framing (counter in the nonce, final
/// flag, authenticated header) — documented in docs/ARCHITECTURE.md §7.2.
/// The Dart side never holds the streaming key; it only references keys by
/// an opaque [keyId] bound inside the Kotlin session.
///
/// Protocol for `dokki/vault_crypto` (all byte arrays base64):
///   generateAndBind {epoch, purpose}            → { wrappedDek, keyId }
///   bindWrappedDek  {wrappedDek, epoch, purpose} → { keyId }
///   gcmEncrypt      {keyId, salt, nonce, aad, plaintext} → { ciphertext }
///   gcmDecrypt      {keyId, salt, nonce, aad, ciphertext} → { plaintext }
///   gcmHeaderEncrypt/gcmHeaderDecrypt {keyId, salt, aad, pt/ct}
///   releaseKey      {keyId}
///
/// Any integrity violation surfaces as `NativeTagVerificationFailed`.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'error_boundary.dart';

final class NativeCryptoBridge {
  const NativeCryptoBridge();

  static const MethodChannel _channel = MethodChannel('dokki/vault_crypto');

  /// Generates a fresh 32-byte DEK, wraps it under `K_<purpose>(epoch)`,
  /// and binds the raw DEK in the Kotlin session.
  Future<NativeDek> generateAndBind({
    required int keyEpoch,
    required int purpose,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('generateAndBind', {
        'epoch': keyEpoch,
        'purpose': purpose,
      }),
    );
    return NativeDek(
      wrappedDek: _bytes(result!['wrappedDek']),
      keyId: result['keyId']! as int,
    );
  }

  /// Binds an existing wrapped DEK: Kotlin unwraps it under
  /// `K_<purpose>(epoch)` and holds the raw DEK.
  Future<int> bindWrappedDek({
    required Uint8List wrappedDek,
    required int keyEpoch,
    required int purpose,
  }) async {
    final keyId = await guardChannel(
      () => _channel.invokeMethod<int>('bindWrappedDek', {
        'wrappedDek': _b64(wrappedDek),
        'epoch': keyEpoch,
        'purpose': purpose,
      }),
    );
    return keyId!;
  }

  Future<Uint8List> encrypt({
    required int keyId,
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List plaintext,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('gcmEncrypt', {
        'keyId': keyId,
        'salt': _b64(salt),
        'nonce': _b64(nonce),
        'aad': _b64(aad),
        'plaintext': _b64(plaintext),
      }),
    );
    return _bytes(result!['ciphertext']);
  }

  Future<Uint8List> decrypt({
    required int keyId,
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List ciphertext,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('gcmDecrypt', {
        'keyId': keyId,
        'salt': _b64(salt),
        'nonce': _b64(nonce),
        'aad': _b64(aad),
        'ciphertext': _b64(ciphertext),
      }),
    );
    return _bytes(result!['plaintext']);
  }

  Future<void> releaseKey(int keyId) async {
    await guardChannel(
      () => _channel.invokeMethod<void>('releaseKey', {'keyId': keyId}),
    );
  }

  /// Header sealing: the Kotlin side derives `header_key = HKDF(dek, salt,
  /// 'dokki/envelope/v1/header')` and computes
  /// `AES-GCM(header_key, nonce=0, aad, plaintext=dek)` — binding the DEK
  /// and the header bytes together. Only the native side knows the DEK.
  Future<Uint8List> sealHeader({
    required int keyId,
    required Uint8List salt,
    required Uint8List aad,
  }) async {
    final result = await guardChannel(
      () => _channel.invokeMapMethod<String, Object?>('gcmHeaderEncrypt', {
        'keyId': keyId,
        'salt': _b64(salt),
        'aad': _b64(aad),
      }),
    );
    return _bytes(result!['tag']);
  }

  /// Verifies a header tag: decrypts it and compares with the bound DEK.
  /// Throws `NativeTagVerificationFailed` on any mismatch.
  Future<void> verifyHeader({
    required int keyId,
    required Uint8List salt,
    required Uint8List aad,
    required Uint8List tag,
  }) async {
    await guardChannel(
      () => _channel.invokeMethod<void>('gcmHeaderDecrypt', {
        'keyId': keyId,
        'salt': _b64(salt),
        'aad': _b64(aad),
        'tag': _b64(tag),
      }),
    );
  }

  static String _b64(Uint8List bytes) => base64Encode(bytes);

  static Uint8List _bytes(Object? value) => base64Decode(value! as String);
}

/// A freshly generated DEK: the wrapped form (persisted in the blob row and
/// the envelope header) plus the session-bound key id.
final class NativeDek {
  const NativeDek({required this.wrappedDek, required this.keyId});

  final Uint8List wrappedDek;
  final int keyId;
}
