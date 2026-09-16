/// Layout goldens (§13.7): byte-exact JSON of the placed cells. Pure
/// geometry — no image, no PDF library, no device.
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_export/vault_export.dart';

String golden(List<PlacedCell> cells) =>
    jsonEncode([for (final c in cells) c.toJson()]);

void main() {
  const engine = LayoutEngine();

  test('single A4 portrait, fitCell, centred: a landscape ID fills width', () {
    const spec = PageLayoutSpec(paper: PaperSize.a4);
    final cells = engine.layout(spec, const [SizeMm(85.6, 53.98)]);
    // Printable area 190 × 277; scale = 190/85.6 = 2.2196…; height 119.81.
    expect(
      golden(cells),
      '[{"pageIndex":0,"frame":{"left":10.0,"top":88.592,"width":190.0,'
      '"height":119.815},"contentIndex":0}]',
    );
  });

  test('side-by-side ID on A4 with 10 mm margins and 8 mm spacing', () {
    const spec = PageLayoutSpec(
      paper: PaperSize.a4,
      layout: LayoutMode.sideBySide,
    );
    final cells = engine.layout(spec, const [
      SizeMm(85.6, 53.98),
      SizeMm(85.6, 53.98),
    ]);
    // Cells: (190 - 8) / 2 = 91 mm wide, 277 mm tall; card scales to 91 mm.
    expect(cells, hasLength(2));
    expect(cells[0].pageIndex, 0);
    expect(cells[1].pageIndex, 0);
    expect(cells[0].frame.left, 10);
    expect(cells[1].frame.left, 10 + 91 + 8);
    expect(cells[0].frame.width, 91);
    expect(cells[0].frame.height, closeTo(57.385, 0.001));
    expect(cells[0].frame.top, cells[1].frame.top);
    expect(
      golden(cells),
      '[{"pageIndex":0,"frame":{"left":10.0,"top":119.807,"width":91.0,'
      '"height":57.385},"contentIndex":0},{"pageIndex":0,"frame":'
      '{"left":109.0,"top":119.807,"width":91.0,"height":57.385},'
      '"contentIndex":1}]',
    );
  });

  test('vertical stacks two per page, top-left when not centred', () {
    const spec = PageLayoutSpec(
      paper: PaperSize.a5,
      layout: LayoutMode.vertical,
      centerContent: false,
      margins: EdgeInsetsMm(left: 5, top: 5, right: 5, bottom: 5),
      spacingMm: 4,
    );
    final cells = engine.layout(spec, const [
      SizeMm(100, 100),
      SizeMm(100, 100),
      SizeMm(100, 100),
    ]);
    expect(cells.map((c) => c.pageIndex), [0, 0, 1]);
    // Cell height = (200 - 4) / 2 = 98; square content → 98 × 98.
    expect(cells[0].frame, const RectMm(5, 5, 98, 98));
    expect(cells[1].frame, const RectMm(5, 5 + 98 + 4, 98, 98));
    expect(cells[2].frame, const RectMm(5, 5, 98, 98));
  });

  test('grid 2×2 on letter landscape paginates five items into two pages', () {
    const spec = PageLayoutSpec(
      paper: PaperSize.letter,
      orientation: Orientation.landscape,
      layout: LayoutMode.grid,
      cellFit: CellFit.fillCell,
    );
    final cells = engine.layout(spec, List.filled(5, const SizeMm(40, 30)));
    expect(LayoutEngine.pageCount(spec, 5), 2);
    expect(cells.map((c) => c.pageIndex), [0, 0, 0, 0, 1]);
    // Landscape letter: 279.4 × 215.9; area 259.4 × 195.9; cells fill.
    expect(cells[0].frame.width, closeTo((259.4 - 8) / 2, 0.001));
    expect(cells[0].frame.height, closeTo((195.9 - 8) / 2, 0.001));
    expect(cells[3].frame.left, closeTo(10 + (259.4 - 8) / 2 + 8, 0.001));
    expect(cells[3].frame.top, closeTo(10 + (195.9 - 8) / 2 + 8, 0.001));
  });

  test('actualSize keeps natural size and shrinks only when it overflows', () {
    const spec = PageLayoutSpec(
      paper: PaperSize.a4,
      cellFit: CellFit.actualSize,
    );
    final small = engine.layout(spec, const [SizeMm(50, 20)]).single;
    expect(small.frame.width, 50);
    expect(small.frame.height, 20);
    expect(small.frame.left, closeTo(10 + (190 - 50) / 2, 0.001));
    final huge = engine.layout(spec, const [SizeMm(400, 100)]).single;
    expect(huge.frame.width, 190);
    expect(huge.frame.height, 47.5);
  });

  test('is deterministic: same input, same JSON', () {
    const spec = PageLayoutSpec(
      paper: PaperSize.a4,
      layout: LayoutMode.grid,
      gridColumns: 3,
      gridRows: 4,
    );
    final sizes = [for (var i = 1; i <= 12; i++) SizeMm(30.0 + i, 40.0 - i)];
    expect(
      golden(engine.layout(spec, sizes)),
      golden(engine.layout(spec, sizes)),
    );
  });
}
