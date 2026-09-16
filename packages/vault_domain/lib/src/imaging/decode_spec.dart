/// How a source image should be decoded (§11.3 step 3).
///
/// A 4000×3000 source for a 600×400 output decodes at 1/4 via
/// `inSampleSize` — never decode full, then shrink.
library;

final class DecodeSpec {
  const DecodeSpec({required this.targetMaxPixels, this.preferredMime});

  /// Ceiling on decoded pixels (default 40 MP — R2 mitigation).
  final int targetMaxPixels;

  /// Re-encode hint; `null` keeps the source format where possible.
  final String? preferredMime;

  static const thumbnail = DecodeSpec(targetMaxPixels: 1024 * 1024);

  static const preview = DecodeSpec(targetMaxPixels: 4 * 1024 * 1024);

  static const fullResolution = DecodeSpec(targetMaxPixels: 40 * 1024 * 1024);
}
