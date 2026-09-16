/// §8.6 step 4: rewrites an envelope header under a new key epoch.
///
/// Rotation is a metadata-only pass: the header is re-sealed (new epoch,
/// rewrapped DEK, fresh header tag) while the body — the bulk of every
/// file — is copied byte-for-byte. This is what makes rotation practical
/// at all (M9): rewrapping a few thousand short DEKs instead of
/// re-encrypting a multi-gigabyte vault.
library;

import 'dart:typed_data';

import 'package:vault_domain/vault_domain.dart';

import '../error_boundary.dart';
import 'envelope_format.dart';
import 'envelope_primitive.dart';

final class EnvelopeHeaderRewriter {
  const EnvelopeHeaderRewriter(this.primitive);

  final EnvelopePrimitive primitive;

  /// Parses [headerBytes] and returns the header re-sealed under
  /// [toEpoch]: same DEK (rewrapped, never exposed), same salt and flags,
  /// a fresh header tag proving possession of the DEK. [rewrapDek] is the
  /// key backend's DEK rewrap (native session or dev primitive).
  Future<Result<Uint8List, VaultFailure>> rewrap(
    Uint8List headerBytes, {
    required int toEpoch,
    required Future<Uint8List> Function(Uint8List wrappedDek, int purpose)
    rewrapDek,
  }) => guardCrypto('rewrapHeader', () async {
    final header = EnvelopeHeader.parse(headerBytes);
    final newWrapped = await rewrapDek(
      header.wrappedDek,
      header.purpose.byte,
    );
    final keyId = await primitive.bindWrapped(
      wrappedDek: newWrapped,
      keyEpoch: toEpoch,
      purpose: header.purpose.byte,
    );
    try {
      EnvelopeHeader build(Uint8List tag) => EnvelopeHeader(
        headerVersion: header.headerVersion,
        algorithmId: header.algorithmId,
        compressed: header.compressed,
        keyEpoch: toEpoch,
        purpose: header.purpose,
        wrappedDek: newWrapped,
        streamSalt: header.streamSalt,
        headerTag: tag,
      );
      final tag = await primitive.sealHeader(
        keyId,
        salt: header.streamSalt,
        aad: build(Uint8List(16)).bytesWithoutTag(),
      );
      return build(tag).toBytes();
    } finally {
      await primitive.release(keyId);
    }
  });

  /// The byte length of a v1 header for [headerBytes]'s `wrapped_dek_len`.
  static int headerLength(Uint8List headerBytes) {
    if (headerBytes.length < 15) {
      throw const FormatException('Envelope too short for a header');
    }
    final dekLen = ByteData.sublistView(headerBytes).getUint16(13);
    return 15 + dekLen + 32;
  }
}
