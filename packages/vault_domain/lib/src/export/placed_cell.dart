/// Layout engine outputs: pure geometry, no pixels (§11.5).
library;

import 'export_request.dart';

/// A size in millimetres.
final class SizeMm {
  const SizeMm(this.width, this.height);

  final double width;
  final double height;

  double get aspectRatio => width / height;

  @override
  bool operator ==(Object other) =>
      other is SizeMm && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'SizeMm($width, $height)';
}

/// A rectangle in millimetres.
final class RectMm {
  const RectMm(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;

  double get bottom => top + height;

  @override
  bool operator ==(Object other) =>
      other is RectMm &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'RectMm($left, $top, $width, $height)';
}

/// One cell of the layout: where a piece of content goes.
final class PlacedCell {
  const PlacedCell({
    required this.pageIndex,
    required this.frame,
    required this.contentIndex,
  });

  /// 0-based page within the output document.
  final int pageIndex;

  /// Frame on the page, in millimetres, relative to the paper's top-left.
  final RectMm frame;

  /// Index into the content list passed to the layout engine.
  final int contentIndex;

  Map<String, Object?> toJson() => {
    'pageIndex': pageIndex,
    'frame': {
      'left': frame.left,
      'top': frame.top,
      'width': frame.width,
      'height': frame.height,
    },
    'contentIndex': contentIndex,
  };

  static PlacedCell fromJson(Map<String, Object?> json) {
    final frame = (json['frame'] as Map<Object?, Object?>)
        .cast<String, Object?>();
    return PlacedCell(
      pageIndex: (json['pageIndex'] as num).toInt(),
      frame: RectMm(
        (frame['left'] as num).toDouble(),
        (frame['top'] as num).toDouble(),
        (frame['width'] as num).toDouble(),
        (frame['height'] as num).toDouble(),
      ),
      contentIndex: (json['contentIndex'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlacedCell &&
      other.pageIndex == pageIndex &&
      other.frame == frame &&
      other.contentIndex == contentIndex;

  @override
  int get hashCode => Object.hash(pageIndex, frame, contentIndex);

  @override
  String toString() => 'PlacedCell(p$pageIndex, $frame, #$contentIndex)';
}

/// The layout request handed to the geometry engine.
final class LayoutInput {
  const LayoutInput({required this.spec, required this.contentSizes});

  final PageLayoutSpec spec;

  /// Natural content sizes in millimetres, in render order.
  final List<SizeMm> contentSizes;
}
