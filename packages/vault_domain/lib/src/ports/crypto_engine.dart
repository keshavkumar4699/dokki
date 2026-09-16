/// `CryptoEngine` port: the one entry point for sealing and opening data
/// under the Envelope v1 format (§7.2). Implemented by `vault_crypto`.
library;

import '../failures/vault_failure.dart';
import '../result.dart';
import '../security/envelope_purpose.dart';

abstract interface class CryptoEngine {
  /// Streams [plaintext] into a sealed Envelope-v1 stream. Peak memory is
  /// bounded by the chunk size regardless of input size.
  Stream<List<int>> sealStream(
    Stream<List<int>> plaintext, {
    required int keyEpoch,
    required EnvelopePurpose purpose,
    bool compress = false,
  });

  /// Opens a sealed stream. Fails on ANY integrity violation — reorder,
  /// truncation, or modification — never returns partial plaintext.
  Stream<List<int>> openStream(
    Stream<List<int>> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  });

  /// Seals a small payload (≤ 256 KiB) in memory.
  Future<Result<List<int>, VaultFailure>> sealSmall(
    List<int> plaintext, {
    required int keyEpoch,
    required EnvelopePurpose purpose,
  });

  /// Opens a small payload (≤ 256 KiB) in memory.
  Future<Result<List<int>, VaultFailure>> openSmall(
    List<int> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  });

  /// Verifies a sealed stream end-to-end without materialising plaintext.
  Future<Result<void, VaultFailure>> verifyStream(
    Stream<List<int>> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  });

  /// Hex SHA-256 of the ciphertext stream (integrity + upload idempotency;
  /// never used for key derivation).
  Future<Result<String, VaultFailure>> ciphertextSha256(
    Stream<List<int>> ciphertext,
  );
}
