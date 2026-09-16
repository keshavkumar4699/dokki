/// The chunk-level crypto primitive behind the envelope.
///
/// Implementations:
/// - `NativeEnvelopePrimitive` (production): Kotlin + Tink, keys held in a
///   native session, never in the Dart heap.
/// - a test-only implementation over `package:cryptography` (in `test/`)
///   so the full envelope suite — tamper matrix, truncation, reorder —
///   runs on any host without Android.
library;

import 'dart:typed_data';

abstract interface class EnvelopePrimitive {
  /// Generates a fresh 32-byte DEK, wraps it under `K_<purpose>(epoch)`,
  /// and binds the raw DEK in the native session.
  Future<BoundDek> generateAndBind({
    required int keyEpoch,
    required int purpose,
  });

  /// Unwraps a DEK under `K_<purpose>(epoch)` and binds it in the session.
  Future<int> bindWrapped({
    required Uint8List wrappedDek,
    required int keyEpoch,
    required int purpose,
  });

  /// Seals the envelope header: computes
  /// `AES-GCM(header_key, nonce=0, aad=headerBytes, plaintext=DEK)`.
  /// Only the native side knows the raw DEK, so the whole computation
  /// happens there; the framing layer supplies [salt] and [aad].
  Future<Uint8List> sealHeader(
    int keyId, {
    required Uint8List salt,
    required Uint8List aad,
  });

  /// Verifies the header tag: decrypts it and compares against the bound
  /// DEK. Throws [TagVerificationFailed] on any mismatch.
  Future<void> verifyHeader(
    int keyId, {
    required Uint8List salt,
    required Uint8List aad,
    required Uint8List tag,
  });

  /// AES-256-GCM on the stream key. Nonce and AAD are supplied by the
  /// framing layer; the implementation must use them verbatim.
  Future<Uint8List> encryptChunk(
    int keyId, {
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List plaintext,
  });

  /// AES-256-GCM open on the stream key. MUST throw [TagVerificationFailed]
  /// on any integrity violation.
  Future<Uint8List> decryptChunk(
    int keyId, {
    required Uint8List salt,
    required Uint8List nonce,
    required Uint8List aad,
    required Uint8List ciphertext,
  });

  /// Releases the session key; the raw DEK is zeroed on the native side.
  Future<void> release(int keyId);
}

/// A freshly generated DEK: wrapped form (persisted in the header + blob
/// row) plus the session-bound key id.
final class BoundDek {
  const BoundDek({required this.wrappedDek, required this.keyId});

  final Uint8List wrappedDek;
  final int keyId;
}

/// Raised when a GCM tag fails — always a tamper signal or a wrong key.
final class TagVerificationFailed implements Exception {
  const TagVerificationFailed();
}
