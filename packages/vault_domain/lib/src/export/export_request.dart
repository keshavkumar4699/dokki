/// `ExportRequest` and its value objects (§11.1).
///
/// The full request is the replayable source of truth for an export record;
/// the persistence layer denormalises a few columns for fast list filtering.
library;

import '../ids.dart';
import '../imaging/image_op.dart';

enum OutputFormat {
  jpeg,
  png,
  webp,
  pdf;

  String get dbValue => name.toUpperCase();

  static OutputFormat? fromDbValue(String value) {
    for (final format in OutputFormat.values) {
      if (format.dbValue == value) {
        return format;
      }
    }
    return null;
  }
}

/// What to export. Sealed: new shapes are new subtypes, not nullable fields.
sealed class ExportSource {
  const ExportSource();
}

/// One specific version.
final class SingleVersionSource extends ExportSource {
  const SingleVersionSource(this.versionId);

  final VersionId versionId;
}

/// An ID's front and back (either may be null — front-only / back-only).
final class IdPairSource extends ExportSource {
  const IdPairSource({this.front, this.back});

  final VersionId? front;
  final VersionId? back;
}

/// Selected document pages, in order.
final class DocumentPagesSource extends ExportSource {
  const DocumentPagesSource(this.pages);

  final List<VersionId> pages;
}

/// Quick export: the current versions of whatever the entry holds.
final class CurrentOfEntrySource extends ExportSource {
  const CurrentOfEntrySource(this.entryId);

  final EntryId entryId;
}

enum DimensionUnit { px, mm, inch }

/// How the output raster is sized.
final class RasterSpec {
  const RasterSpec({
    this.width,
    this.height,
    this.unit = DimensionUnit.px,
    this.dpi,
    this.fit = FitMode.cover,
    this.filter = ResampleFilter.lanczos,
  });

  /// At most one may be null ⇒ aspect preserved (§11.1).
  final int? width;
  final int? height;
  final DimensionUnit unit;

  /// Required when [unit] != px.
  final int? dpi;

  final FitMode fit;
  final ResampleFilter filter;
}

enum ResampleFilter { lanczos, bilinear, nearest }

/// Quality and size targets (§11.4).
final class QualitySpec {
  const QualitySpec({
    this.quality,
    this.targetBytes,
    this.maxBytes,
    this.minQualityFloor = 40,
    this.allowDownscale = true,
  });

  /// 1..100, encoder-specific. `null` = encoder default (85).
  final int? quality;

  /// Best effort; missing it is a warning, not a failure.
  final int? targetBytes;

  /// HARD constraint; exceeding it is a failure (`SizeUnattainable`).
  final int? maxBytes;

  /// Don't produce mush.
  final int minQualityFloor;

  /// If the quality floor is hit, may we shrink the output?
  final bool allowDownscale;
}

enum PaperSize { a4, a5, letter, legal, custom }

enum Orientation { portrait, landscape }

enum LayoutMode {
  single('SINGLE'),
  sideBySide('SIDE_BY_SIDE'),
  vertical('VERTICAL'),
  grid('GRID');

  const LayoutMode(this.dbValue);

  /// Stable DB value (§6.3 `export_records.layout`).
  final String dbValue;

  static LayoutMode? fromDbValue(String value) {
    for (final mode in LayoutMode.values) {
      if (mode.dbValue == value) {
        return mode;
      }
    }
    return null;
  }
}

enum CellFit { fitCell, fillCell, actualSize }

/// Margins in millimetres.
final class EdgeInsetsMm {
  const EdgeInsetsMm({
    this.left = 10,
    this.top = 10,
    this.right = 10,
    this.bottom = 10,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  static const zero = EdgeInsetsMm(left: 0, top: 0, right: 0, bottom: 0);
}

/// Paper + placement rules for PDF output (§11.1).
final class PageLayoutSpec {
  const PageLayoutSpec({
    required this.paper,
    this.orientation = Orientation.portrait,
    this.margins = const EdgeInsetsMm(),
    this.spacingMm = 8,
    this.layout = LayoutMode.single,
    this.gridColumns = 2,
    this.gridRows = 2,
    this.cellFit = CellFit.fitCell,
    this.centerContent = true,
  });

  final PaperSize paper;
  final Orientation orientation;
  final EdgeInsetsMm margins;
  final double spacingMm;
  final LayoutMode layout;

  /// Grid dimensions when [layout] is [LayoutMode.grid].
  final int gridColumns;
  final int gridRows;

  final CellFit cellFit;
  final bool centerContent;

  /// Standard paper sizes in millimetres (portrait).
  static ({double width, double height}) paperSizeMm(PaperSize paper) =>
      switch (paper) {
        PaperSize.a4 => (width: 210, height: 297),
        PaperSize.a5 => (width: 148, height: 210),
        PaperSize.letter => (width: 215.9, height: 279.4),
        PaperSize.legal => (width: 215.9, height: 355.6),
        PaperSize.custom => (width: 0, height: 0),
      };
}

/// Colour treatment for the output.
final class ColorSpec {
  const ColorSpec({
    this.grayscale = false,
    this.bw = false,
    this.backgroundColor,
  });

  final bool grayscale;

  /// 1-bit black & white (only sensible for PDF).
  final bool bw;

  /// ARGB fill behind content; `null` = white.
  final int? backgroundColor;
}

final class ExportRequest {
  const ExportRequest({
    required this.source,
    required this.format,
    required this.quality,
    this.raster,
    this.page,
    this.color = const ColorSpec(),
    this.extensions = const {},
    this.requestSchemaVersion = 1,
  });

  final ExportSource source;
  final OutputFormat format;

  /// `null` for pure-PDF pass-through (§11.1).
  final RasterSpec? raster;

  final QualitySpec quality;

  /// Required iff [format] == [OutputFormat.pdf].
  final PageLayoutSpec? page;

  final ColorSpec color;

  /// Forward-compat bag.
  final Map<String, Object?> extensions;

  final int requestSchemaVersion;
}
