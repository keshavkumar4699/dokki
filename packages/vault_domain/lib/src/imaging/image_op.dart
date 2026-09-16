/// The declarative image op set (`EditRecipe` elements, §5.3).
///
/// Ops are serialisable and deterministic unless stated otherwise.
/// Detection is separate from application: an `EdgeDetector` produces a
/// `Quad`, which becomes a `PerspectiveOp`.
library;

import 'dart:convert';

import 'geometry.dart';

/// Denoise strength levels.
enum DenoiseStrength { light, medium, strong }

/// How an image is fitted into a target box.
enum FitMode {
  /// Scale to cover the box; crop overflow.
  cover,

  /// Scale to fit inside the box; leave letterbox space.
  contain,

  /// Ignore aspect ratio and fill the box exactly.
  stretch,

  /// Scale the shorter edge to fit; pad the longer with background.
  pad,
}

/// A named filter preset.
typedef FilterId = String;

/// Parameters for background removal/replacement — the only
/// non-deterministic op in v1.
final class BackgroundSpec {
  const BackgroundSpec({required this.color, this.blurRadius = 0});

  /// Fill color as ARGB.
  final int color;

  /// Optional edge blur in pixels (0 = hard edge).
  final double blurRadius;

  Map<String, Object?> toJson() => {'color': color, 'blurRadius': blurRadius};

  static BackgroundSpec fromJson(Map<String, Object?> json) => BackgroundSpec(
    color: (json['color'] as num).toInt(),
    blurRadius: (json['blurRadius'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is BackgroundSpec &&
      other.color == color &&
      other.blurRadius == blurRadius;

  @override
  int get hashCode => Object.hash(color, blurRadius);
}

/// One declarative image operation.
sealed class ImageOp {
  const ImageOp();

  /// Non-deterministic ops (ML) cannot be re-materialized (§5.3).
  bool get deterministic => true;

  /// Stable op tag, used in serialisation.
  String get opType;

  Map<String, Object?> toJson() => {'op': opType};

  static ImageOp fromJson(Map<String, Object?> json) {
    final op = json['op'] as String?;
    return switch (op) {
      'crop' => CropOp.fromJson(json),
      'perspective' => PerspectiveOp.fromJson(json),
      'rotate' => RotateOp.fromJson(json),
      'brightness' => BrightnessOp.fromJson(json),
      'contrast' => ContrastOp.fromJson(json),
      'exposure' => ExposureOp.fromJson(json),
      'sharpen' => SharpenOp.fromJson(json),
      'denoise' => DenoiseOp.fromJson(json),
      'resize' => ResizeOp.fromJson(json),
      'filter' => FilterOp.fromJson(json),
      'background' => BackgroundOp.fromJson(json),
      _ => throw FormatException('Unknown ImageOp type: $op'),
    };
  }

  /// Parses a serialised recipe; throws [FormatException] on corrupt data.
  static List<ImageOp> listFromJson(String json) =>
      (jsonDecode(json) as List<Object?>)
          .map(
            (Object? item) => ImageOp.fromJson(
              (item as Map<Object?, Object?>).cast<String, Object?>(),
            ),
          )
          .toList(growable: false);
}

/// Crops to a normalised rectangle.
final class CropOp extends ImageOp {
  const CropOp(this.rect);

  @override
  String get opType => 'crop';

  final RectN rect;

  @override
  Map<String, Object?> toJson() => {
    'op': opType,
    'rect': {
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    },
  };

  static CropOp fromJson(Map<String, Object?> json) {
    final rect = (json['rect'] as Map<Object?, Object?>)
        .cast<String, Object?>();
    return CropOp(
      RectN(
        (rect['left'] as num).toDouble(),
        (rect['top'] as num).toDouble(),
        (rect['right'] as num).toDouble(),
        (rect['bottom'] as num).toDouble(),
      ),
    );
  }

  @override
  bool operator ==(Object other) => other is CropOp && other.rect == rect;

  @override
  int get hashCode => Object.hash(opType, rect);
}

/// Perspective-corrects to the given quadrilateral.
final class PerspectiveOp extends ImageOp {
  const PerspectiveOp(this.quad);

  @override
  String get opType => 'perspective';

  final Quad quad;

  @override
  Map<String, Object?> toJson() => {
    'op': opType,
    'quad': {
      for (var i = 0; i < 4; i++)
        'p$i': {'x': quad.corners[i].x, 'y': quad.corners[i].y},
    },
  };

  static PerspectiveOp fromJson(Map<String, Object?> json) {
    final quad = (json['quad'] as Map<Object?, Object?>)
        .cast<String, Object?>();
    PointN point(String key) {
      final p = (quad[key] as Map<Object?, Object?>).cast<String, Object?>();
      return PointN((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
    }

    return PerspectiveOp(
      Quad(point('p0'), point('p1'), point('p2'), point('p3')),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PerspectiveOp && other.quad == quad;

  @override
  int get hashCode => Object.hash(opType, quad);
}

/// Rotates by a number of 90° turns, clockwise.
final class RotateOp extends ImageOp {
  const RotateOp(this.quarterTurns);

  @override
  String get opType => 'rotate';

  final int quarterTurns;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'quarterTurns': quarterTurns};

  static RotateOp fromJson(Map<String, Object?> json) =>
      RotateOp((json['quarterTurns'] as num).toInt());

  @override
  bool operator ==(Object other) =>
      other is RotateOp && other.quarterTurns == quarterTurns;

  @override
  int get hashCode => Object.hash(opType, quarterTurns);
}

/// Adds a brightness delta in `[-1, 1]`.
final class BrightnessOp extends ImageOp {
  const BrightnessOp(this.delta);

  @override
  String get opType => 'brightness';

  final double delta;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'delta': delta};

  static BrightnessOp fromJson(Map<String, Object?> json) =>
      BrightnessOp((json['delta'] as num).toDouble());

  @override
  bool operator ==(Object other) =>
      other is BrightnessOp && other.delta == delta;

  @override
  int get hashCode => Object.hash(opType, delta);
}

/// Multiplies contrast by a factor (1.0 = unchanged).
final class ContrastOp extends ImageOp {
  const ContrastOp(this.factor);

  @override
  String get opType => 'contrast';

  final double factor;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'factor': factor};

  static ContrastOp fromJson(Map<String, Object?> json) =>
      ContrastOp((json['factor'] as num).toDouble());

  @override
  bool operator ==(Object other) =>
      other is ContrastOp && other.factor == factor;

  @override
  int get hashCode => Object.hash(opType, factor);
}

/// Adjusts exposure in EV stops.
final class ExposureOp extends ImageOp {
  const ExposureOp(this.ev);

  @override
  String get opType => 'exposure';

  final double ev;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'ev': ev};

  static ExposureOp fromJson(Map<String, Object?> json) =>
      ExposureOp((json['ev'] as num).toDouble());

  @override
  bool operator ==(Object other) => other is ExposureOp && other.ev == ev;

  @override
  int get hashCode => Object.hash(opType, ev);
}

/// Sharpens by an amount in `[0, 1]`.
final class SharpenOp extends ImageOp {
  const SharpenOp(this.amount);

  @override
  String get opType => 'sharpen';

  final double amount;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'amount': amount};

  static SharpenOp fromJson(Map<String, Object?> json) =>
      SharpenOp((json['amount'] as num).toDouble());

  @override
  bool operator ==(Object other) =>
      other is SharpenOp && other.amount == amount;

  @override
  int get hashCode => Object.hash(opType, amount);
}

/// Denoises at a strength level.
final class DenoiseOp extends ImageOp {
  const DenoiseOp(this.strength);

  @override
  String get opType => 'denoise';

  final DenoiseStrength strength;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'strength': strength.name};

  static DenoiseOp fromJson(Map<String, Object?> json) => DenoiseOp(
    DenoiseStrength.values.firstWhere(
      (DenoiseStrength s) => s.name == json['strength'],
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is DenoiseOp && other.strength == strength;

  @override
  int get hashCode => Object.hash(opType, strength);
}

/// Resizes; at most one dimension may be null (aspect preserved).
final class ResizeOp extends ImageOp {
  const ResizeOp({this.width, this.height, required this.fit});

  @override
  String get opType => 'resize';

  final int? width;
  final int? height;
  final FitMode fit;

  @override
  Map<String, Object?> toJson() => {
    'op': opType,
    'width': width,
    'height': height,
    'fit': fit.name,
  };

  static ResizeOp fromJson(Map<String, Object?> json) => ResizeOp(
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    fit: FitMode.values.firstWhere((FitMode f) => f.name == json['fit']),
  );

  @override
  bool operator ==(Object other) =>
      other is ResizeOp &&
      other.width == width &&
      other.height == height &&
      other.fit == fit;

  @override
  int get hashCode => Object.hash(opType, width, height, fit);
}

/// Applies a named filter preset.
final class FilterOp extends ImageOp {
  const FilterOp(this.id);

  @override
  String get opType => 'filter';

  final FilterId id;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'id': id};

  static FilterOp fromJson(Map<String, Object?> json) =>
      FilterOp(json['id'] as String);

  @override
  bool operator ==(Object other) => other is FilterOp && other.id == id;

  @override
  int get hashCode => Object.hash(opType, id);
}

/// Background removal/replacement. NON-deterministic: an evicted version
/// with this op cannot be re-materialized (§10.3).
final class BackgroundOp extends ImageOp {
  const BackgroundOp(this.spec);

  @override
  String get opType => 'background';

  @override
  bool get deterministic => false;

  final BackgroundSpec spec;

  @override
  Map<String, Object?> toJson() => {'op': opType, 'spec': spec.toJson()};

  static BackgroundOp fromJson(Map<String, Object?> json) => BackgroundOp(
    BackgroundSpec.fromJson(
      (json['spec'] as Map<Object?, Object?>).cast<String, Object?>(),
    ),
  );

  @override
  bool operator ==(Object other) => other is BackgroundOp && other.spec == spec;

  @override
  int get hashCode => Object.hash(opType, spec);
}
