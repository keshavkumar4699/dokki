/// Envelope v1 byte format (§7.2 of docs/ARCHITECTURE.md).
///
/// Every sealed file on disk and every blob in Drive uses this one format.
/// Because the local file and the cloud blob are byte-identical, sync never
/// decrypts anything.
///
/// Layout:
/// ```
/// magic           5B  "PVLT1"
/// envelope_ver    1B  0x01
/// alg_id          1B  0x01 = AES-256-GCM-HKDF-STREAMING, 256 KiB chunks
/// flags           1B  bit0 = compressed-before-encryption
/// key_epoch       4B  big-endian uint32
/// purpose         1B  EnvelopePurpose.byte
/// wrapped_dek_len 2B
/// wrapped_dek     var DEK sealed under K_<purpose> of this epoch
/// stream_salt    16B  HKDF salt for the streaming + header keys
/// header_tag     16B  AES-GCM(header_key, nonce=0, aad=header[0..-16],
///                      plaintext=dek)  — authenticates the whole header
/// ```
/// Body chunks (256 KiB plaintext each):
/// ```
/// nonce = stream_salt[0..7] || counter(4B BE) || final(1B)
/// aad   = header_tag || counter(4B BE) || final(1B)
/// ct    = AES-GCM(stream_key, nonce, aad, chunk)
/// ```
/// Keys: `stream_key = HKDF-SHA256(dek, salt, 'dokki/envelope/v1/stream')`,
/// `header_key = HKDF-SHA256(dek, salt, 'dokki/envelope/v1/header')`.
///
/// Why each piece exists:
/// - `header_tag` covers the whole header, so `alg_id`/`key_epoch`/`flags`
///   cannot be downgraded by an attacker who can write the file.
/// - chunking keeps peak memory at ~256 KiB regardless of a 60 MB scan.
/// - the counter in the nonce prevents chunk reordering; the final-chunk
///   flag prevents truncation.
/// - `key_epoch` in the header makes rotation a DEK-rewrap, not a rewrite.
/// - a per-file DEK means compromising one DEK compromises one file.
///
/// This is the STREAM construction (Hoang–Reyhanitabak–Rogaway), used
/// through Tink's AES-GCM primitive with our framing — we never write our
/// own AES-GCM.
library;

import 'dart:typed_data';

import 'package:vault_domain/vault_domain.dart' show EnvelopePurpose;

const String envelopeMagic = 'PVLT1';

const int envelopeVersion = 1;

/// AES-256-GCM-HKDF-STREAMING, 256 KiB chunks.
const int algId = 1;

/// 256 KiB plaintext per chunk.
const int chunkSize = 256 * 1024;

/// Flags byte: bit 0 = compressed-before-encryption.
const int flagCompressed = 0x01;

final class EnvelopeHeader {
  const EnvelopeHeader({
    required this.headerVersion,
    required this.algorithmId,
    required this.compressed,
    required this.keyEpoch,
    required this.purpose,
    required this.wrappedDek,
    required this.streamSalt,
    required this.headerTag,
  });

  final int headerVersion;
  final int algorithmId;
  final bool compressed;
  final int keyEpoch;
  final EnvelopePurpose purpose;
  final Uint8List wrappedDek;
  final Uint8List streamSalt;
  final Uint8List headerTag;

  /// Serialises the header EXCLUDING the tag (the tag's AAD).
  Uint8List bytesWithoutTag() {
    final builder = BytesBuilder(copy: false)
      ..add(Uint8List.fromList(envelopeMagic.codeUnits))
      ..add(
        Uint8List.fromList([
          envelopeVersion,
          algId,
          if (compressed) flagCompressed else 0,
        ]),
      )
      ..add(_uint32(keyEpoch))
      ..add(Uint8List.fromList([purpose.byte]))
      ..add(_uint16(wrappedDek.length))
      ..add(wrappedDek)
      ..add(streamSalt);
    return builder.takeBytes();
  }

  Uint8List toBytes() {
    final builder = BytesBuilder(copy: false)
      ..add(bytesWithoutTag())
      ..add(headerTag);
    return builder.takeBytes();
  }

  static Uint8List _uint32(int value) {
    final bytes = Uint8List(4);
    ByteData.sublistView(bytes).setUint32(0, value);
    return bytes;
  }

  static Uint8List _uint16(int value) {
    final bytes = Uint8List(2);
    ByteData.sublistView(bytes).setUint16(0, value);
    return bytes;
  }

  /// Parses a header from the front of [bytes]. Throws [FormatException]
  /// on any structural violation; does NOT verify the tag (caller does).
  static EnvelopeHeader parse(Uint8List bytes) {
    if (bytes.length < 15) {
      throw const FormatException('Envelope too short for a header');
    }
    final data = ByteData.sublistView(bytes);
    final magic = String.fromCharCodes(bytes.sublist(0, 5));
    if (magic != envelopeMagic) {
      throw const FormatException('Not an envelope: bad magic');
    }
    final version = bytes[5];
    if (version != envelopeVersion) {
      throw FormatException('Unsupported envelope version: $version');
    }
    final alg = bytes[6];
    if (alg != algId) {
      throw FormatException('Unsupported alg_id: $alg');
    }
    final flags = bytes[7];
    final epoch = data.getUint32(8);
    final purposeByte = bytes[12];
    final EnvelopePurpose purpose;
    try {
      purpose = EnvelopePurpose.fromByte(purposeByte);
    } on StateError {
      throw FormatException('Unknown purpose byte: $purposeByte');
    }
    final wrappedLen = data.getUint16(13);
    final saltStart = 15 + wrappedLen;
    if (bytes.length < saltStart + 32) {
      throw const FormatException('Envelope truncated inside header');
    }
    final wrappedDek = bytes.sublist(15, 15 + wrappedLen);
    final salt = bytes.sublist(saltStart, saltStart + 16);
    final tag = bytes.sublist(saltStart + 16, saltStart + 32);
    return EnvelopeHeader(
      headerVersion: version,
      algorithmId: alg,
      compressed: (flags & flagCompressed) != 0,
      keyEpoch: epoch,
      purpose: purpose,
      wrappedDek: wrappedDek,
      streamSalt: salt,
      headerTag: tag,
    );
  }
}
