/// Pipeline step 5 (§11.3, §11.5): pure geometry. Paper → margins → cells
/// → placement. No pixels, no PDF library, deterministic.
library;

import 'dart:math' as math;

import 'package:vault_domain/vault_domain.dart';

import 'validation.dart' show orientedPaperMm;

final class LayoutEngine {
  const LayoutEngine();

  /// Cells per page for [spec]: `(rows, columns)`.
  static ({int rows, int columns}) gridOf(PageLayoutSpec spec) =>
      switch (spec.layout) {
        LayoutMode.single => (rows: 1, columns: 1),
        LayoutMode.sideBySide => (rows: 1, columns: 2),
        LayoutMode.vertical => (rows: 2, columns: 1),
        LayoutMode.grid => (rows: spec.gridRows, columns: spec.gridColumns),
      };

  /// Number of pages needed for [contentCount] items.
  static int pageCount(PageLayoutSpec spec, int contentCount) {
    final grid = gridOf(spec);
    final perPage = grid.rows * grid.columns;
    return (contentCount + perPage - 1) ~/ perPage;
  }

  /// Places [contentSizes] (natural sizes in mm) in render order, filling
  /// each page row by row before starting the next.
  List<PlacedCell> layout(PageLayoutSpec spec, List<SizeMm> contentSizes) {
    final paper = orientedPaperMm(spec);
    final grid = gridOf(spec);
    final m = spec.margins;
    final areaW = paper.width - m.left - m.right;
    final areaH = paper.height - m.top - m.bottom;
    final cellW = (areaW - (grid.columns - 1) * spec.spacingMm) / grid.columns;
    final cellH = (areaH - (grid.rows - 1) * spec.spacingMm) / grid.rows;
    final perPage = grid.rows * grid.columns;

    final placed = <PlacedCell>[];
    for (var i = 0; i < contentSizes.length; i++) {
      final slot = i % perPage;
      final row = slot ~/ grid.columns;
      final column = slot % grid.columns;
      final cellLeft = m.left + column * (cellW + spec.spacingMm);
      final cellTop = m.top + row * (cellH + spec.spacingMm);
      final content = _fitContent(contentSizes[i], cellW, cellH, spec.cellFit);
      final offsetX = spec.centerContent ? (cellW - content.width) / 2 : 0.0;
      final offsetY = spec.centerContent ? (cellH - content.height) / 2 : 0.0;
      placed.add(
        PlacedCell(
          pageIndex: i ~/ perPage,
          frame: RectMm(
            _round(cellLeft + offsetX),
            _round(cellTop + offsetY),
            _round(content.width),
            _round(content.height),
          ),
          contentIndex: i,
        ),
      );
    }
    return placed;
  }

  static SizeMm _fitContent(
    SizeMm content,
    double cellW,
    double cellH,
    CellFit fit,
  ) {
    switch (fit) {
      case CellFit.fillCell:
        return SizeMm(cellW, cellH);
      case CellFit.fitCell:
        if (content.width <= 0 || content.height <= 0) {
          return SizeMm(cellW, cellH);
        }
        final scale = math.min(cellW / content.width, cellH / content.height);
        return SizeMm(content.width * scale, content.height * scale);
      case CellFit.actualSize:
        // Never overflow the cell; shrink proportionally if it would.
        if (content.width <= cellW && content.height <= cellH) {
          return content;
        }
        final scale = math.min(cellW / content.width, cellH / content.height);
        return SizeMm(content.width * scale, content.height * scale);
    }
  }

  /// Three decimals of a millimetre is beyond any printer; rounding keeps
  /// the goldens byte-stable across platforms.
  static double _round(double value) => (value * 1000).round() / 1000;
}
