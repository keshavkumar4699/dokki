/// Normalised image geometry: points, rects, quads in 0..1 coordinates.
///
/// Recipes store normalised coordinates so a recipe recorded against a
/// 4000 px original still applies to a 1000 px preview (§5.3).
library;

/// A point in normalised 0..1 image coordinates.
final class PointN {
  const PointN(this.x, this.y)
    : assert(x >= 0 && x <= 1, 'x must be in [0,1]'),
      assert(y >= 0 && y <= 1, 'y must be in [0,1]');

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is PointN && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PointN($x, $y)';
}

/// A rectangle in normalised 0..1 coordinates (`left, top, right, bottom`).
final class RectN {
  const RectN(this.left, this.top, this.right, this.bottom)
    : assert(left >= 0 && left <= 1),
      assert(top >= 0 && top <= 1),
      assert(right >= 0 && right <= 1),
      assert(bottom >= 0 && bottom <= 1),
      assert(left < right, 'rect must have positive width'),
      assert(top < bottom, 'rect must have positive height');

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;

  double get height => bottom - top;

  @override
  bool operator ==(Object other) =>
      other is RectN &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'RectN($left, $top, $right, $bottom)';
}

/// A quadrilateral in normalised 0..1 coordinates, corners clockwise from
/// the top-left. Produced by edge detection; consumed by `PerspectiveOp`.
final class Quad {
  const Quad(this.topLeft, this.topRight, this.bottomRight, this.bottomLeft);

  final PointN topLeft;
  final PointN topRight;
  final PointN bottomRight;
  final PointN bottomLeft;

  List<PointN> get corners => [topLeft, topRight, bottomRight, bottomLeft];

  /// The identity quad: the full frame.
  static const fullFrame = Quad(
    PointN(0, 0),
    PointN(1, 0),
    PointN(1, 1),
    PointN(0, 1),
  );

  @override
  bool operator ==(Object other) =>
      other is Quad &&
      other.topLeft == topLeft &&
      other.topRight == topRight &&
      other.bottomRight == bottomRight &&
      other.bottomLeft == bottomLeft;

  @override
  int get hashCode => Object.hash(topLeft, topRight, bottomRight, bottomLeft);

  @override
  String toString() => 'Quad($topLeft, $topRight, $bottomRight, $bottomLeft)';
}
