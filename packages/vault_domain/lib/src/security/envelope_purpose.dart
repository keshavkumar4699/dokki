/// The envelope `purpose` byte (§7.2).
///
/// Each purpose derives its own wrapping key `K_<purpose>` from the master
/// key, so a DEK wrapped for thumbnails cannot be presented as an asset.
library;

enum EnvelopePurpose {
  asset(1),
  thumbnail(2),
  exportArtifact(3),
  logSegment(4),
  keyring(5),

  /// Column-level metadata (`title_enc`, `note_enc`, `tags_enc`) sealed
  /// under `K_meta` (§6).
  meta(6);

  const EnvelopePurpose(this.byte);

  /// The on-disk value in the envelope header.
  final int byte;

  static EnvelopePurpose fromByte(int byte) =>
      EnvelopePurpose.values.firstWhere((EnvelopePurpose p) => p.byte == byte);
}
