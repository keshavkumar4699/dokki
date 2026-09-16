/// What the presentation layer hands a use case when the user picks or
/// captures an image: a re-openable byte stream plus its size.
///
/// The bytes are read exactly once, straight into the `BlobStore`, which
/// seals them and reports plaintext/ciphertext digests. The UI never sees
/// a `Uint8List` of the full image (M10).
library;

final class ImportSource {
  const ImportSource({
    required this.open,
    required this.byteSize,
    this.mimeHint,
    this.displayName,
  });

  /// Opens a fresh read of the bytes. Must be safe to call more than once.
  final Stream<List<int>> Function() open;

  final int byteSize;

  /// The picker's idea of the MIME type; the image processor's `inspect`
  /// is authoritative.
  final String? mimeHint;

  /// A user-facing name (e.g. the picked file name), used only as a title
  /// suggestion. Never persisted as a path.
  final String? displayName;
}
