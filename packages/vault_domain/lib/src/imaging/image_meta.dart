/// Dimensions and integrity metadata for one version's plaintext (§5.3).
library;

final class ImageMeta {
  const ImageMeta({
    required this.width,
    required this.height,
    required this.mime,
    required this.plaintextSha256,
    required this.byteSize,
  });

  final int width;
  final int height;
  final String mime;

  /// Hex SHA-256 of the *plaintext*, used to verify re-materialization.
  final String plaintextSha256;

  final int byteSize;

  ImageMeta copyWith({
    int? width,
    int? height,
    String? mime,
    String? plaintextSha256,
    int? byteSize,
  }) => ImageMeta(
    width: width ?? this.width,
    height: height ?? this.height,
    mime: mime ?? this.mime,
    plaintextSha256: plaintextSha256 ?? this.plaintextSha256,
    byteSize: byteSize ?? this.byteSize,
  );

  @override
  bool operator ==(Object other) =>
      other is ImageMeta &&
      other.width == width &&
      other.height == height &&
      other.mime == mime &&
      other.plaintextSha256 == plaintextSha256 &&
      other.byteSize == byteSize;

  @override
  int get hashCode =>
      Object.hash(width, height, mime, plaintextSha256, byteSize);
}
