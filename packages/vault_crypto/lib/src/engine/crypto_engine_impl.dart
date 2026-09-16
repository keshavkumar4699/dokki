/// `CryptoEngine` implementation over the envelope cipher.
///
/// Used for metadata-scale payloads (titles, notes, log segments, keyring
/// blobs, thumbnails, export artifacts). Full-resolution asset bytes flow
/// through the NATIVE image pipeline instead — plaintext never enters the
/// Dart heap at full resolution (§8.4).
library;

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:vault_domain/vault_domain.dart';

import '../envelope/envelope_cipher.dart';
import '../error_boundary.dart';

final class CryptoEngineImpl implements CryptoEngine {
  CryptoEngineImpl({required this.cipher, required this.activeKeyEpoch});

  final EnvelopeCipher cipher;

  /// The epoch to seal new data under; provided by the `KeyManager`.
  final int Function() activeKeyEpoch;

  @override
  Stream<List<int>> sealStream(
    Stream<List<int>> plaintext, {
    required int keyEpoch,
    required EnvelopePurpose purpose,
    bool compress = false,
  }) => cipher.sealStream(
    plaintext,
    keyEpoch: keyEpoch,
    purpose: purpose,
    compress: compress,
  );

  @override
  Stream<List<int>> openStream(
    Stream<List<int>> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  }) => cipher.openStream(ciphertext, expectedPurpose: expectedPurpose);

  @override
  Future<Result<List<int>, VaultFailure>> sealSmall(
    List<int> plaintext, {
    required int keyEpoch,
    required EnvelopePurpose purpose,
  }) => guardCrypto('sealSmall', () async {
    final sealed = await cipher.sealSmall(
      plaintext,
      keyEpoch: keyEpoch,
      purpose: purpose,
    );
    return sealed.ciphertext;
  });

  @override
  Future<Result<List<int>, VaultFailure>> openSmall(
    List<int> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  }) => guardCrypto(
    'openSmall',
    () => cipher.openSmall(ciphertext, expectedPurpose: expectedPurpose),
  );

  @override
  Future<Result<void, VaultFailure>> verifyStream(
    Stream<List<int>> ciphertext, {
    required EnvelopePurpose expectedPurpose,
  }) => guardCrypto('verifyStream', () async {
    await for (final _ in cipher.openStream(
      ciphertext,
      expectedPurpose: expectedPurpose,
    )) {
      // Discard: verification is a side effect of opening.
    }
  });

  @override
  Future<Result<String, VaultFailure>> ciphertextSha256(
    Stream<List<int>> ciphertext,
  ) => guardCrypto('ciphertextSha256', () async {
    final digest = AccumulatorSink<Digest>();
    final output = sha256.startChunkedConversion(digest);
    await ciphertext.forEach(output.add);
    output.close();
    return digest.events.single.toString();
  });
}
