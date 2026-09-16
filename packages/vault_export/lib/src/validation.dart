/// Pipeline step 1 (§11.3): validate an [ExportRequest] before any pixel
/// is touched, and turn its raster spec into a pixel plan.
library;

import 'package:vault_domain/vault_domain.dart';

/// Hard ceiling on any output edge (§11.3).
const maxOutputEdgePx = 20000;

/// Highest DPI a physical-unit raster may ask for.
const maxDpi = 2400;

/// A request that passed validation, plus the derived raster plan.
final class ValidatedRequest {
  const ValidatedRequest({required this.request, required this.plan});

  final ExportRequest request;

  /// `null` for PDF pass-through with no raster spec.
  final RasterPlan? plan;
}

/// Validates [request] for an engine that can encode [supportedFormats].
Result<ValidatedRequest, VaultFailure> validateExportRequest(
  ExportRequest request, {
  required Set<OutputFormat> supportedFormats,
}) {
  if (!supportedFormats.contains(request.format)) {
    return Err(UnsupportedFormat(_mimeOf(request.format)));
  }
  final sourceProblem = _validateSource(request.source);
  if (sourceProblem != null) {
    return Err(sourceProblem);
  }
  final quality = _validateQuality(request.quality, request.format);
  if (quality != null) {
    return Err(quality);
  }
  if (request.format == OutputFormat.pdf) {
    final page = request.page;
    if (page == null) {
      return const Err(InvalidExportDimensions('pdf requires a page layout'));
    }
    final pageProblem = _validatePage(page);
    if (pageProblem != null) {
      return Err(pageProblem);
    }
  } else if (request.page != null) {
    return const Err(
      InvalidExportDimensions('page layout only applies to pdf'),
    );
  }
  final raster = request.raster;
  if (raster == null) {
    return Ok(
      ValidatedRequest(
        request: request,
        plan: request.format == OutputFormat.pdf
            ? null
            : RasterPlan(color: request.color),
      ),
    );
  }
  return _planFor(
    raster,
    request.color,
  ).map((plan) => ValidatedRequest(request: request, plan: plan));
}

VaultFailure? _validateSource(ExportSource source) => switch (source) {
  DocumentPagesSource(:final pages) when pages.isEmpty =>
    const InvalidExportDimensions('no pages selected'),
  IdPairSource(front: null, back: null) => const InvalidExportDimensions(
    'an id export needs a front or a back',
  ),
  _ => null,
};

VaultFailure? _validateQuality(QualitySpec spec, OutputFormat format) {
  final quality = spec.quality;
  if (quality != null && (quality < 1 || quality > 100)) {
    return InvalidExportDimensions('quality $quality outside 1..100');
  }
  if (spec.minQualityFloor < 1 || spec.minQualityFloor > 100) {
    return InvalidExportDimensions(
      'minQualityFloor ${spec.minQualityFloor} outside 1..100',
    );
  }
  final target = spec.targetBytes;
  final max = spec.maxBytes;
  if (target != null && target <= 0) {
    return const InvalidExportDimensions('targetBytes must be positive');
  }
  if (max != null && max <= 0) {
    return const InvalidExportDimensions('maxBytes must be positive');
  }
  if (target != null && max != null && target > max) {
    return const InvalidExportDimensions('targetBytes exceeds maxBytes');
  }
  // PNG is lossless: a hard cap can only be met by shrinking. Fail now
  // rather than after a futile search (§11.4).
  if (format == OutputFormat.png && max != null && !spec.allowDownscale) {
    return SizeUnattainable(0, max);
  }
  return null;
}

VaultFailure? _validatePage(PageLayoutSpec page) {
  if (page.paper == PaperSize.custom) {
    return const InvalidExportDimensions('custom paper is not supported');
  }
  final size = orientedPaperMm(page);
  final m = page.margins;
  if (m.left < 0 || m.top < 0 || m.right < 0 || m.bottom < 0) {
    return const InvalidExportDimensions('negative margin');
  }
  if (m.left + m.right >= size.width || m.top + m.bottom >= size.height) {
    return const InvalidExportDimensions('margins leave no printable area');
  }
  if (page.spacingMm < 0) {
    return const InvalidExportDimensions('negative spacing');
  }
  if (page.layout == LayoutMode.grid &&
      (page.gridColumns < 1 || page.gridRows < 1)) {
    return const InvalidExportDimensions('grid needs ≥1 row and column');
  }
  return null;
}

/// Paper size after orientation, in millimetres.
SizeMm orientedPaperMm(PageLayoutSpec page) {
  final base = PageLayoutSpec.paperSizeMm(page.paper);
  return page.orientation == Orientation.landscape
      ? SizeMm(base.height, base.width)
      : SizeMm(base.width, base.height);
}

Result<RasterPlan, VaultFailure> _planFor(RasterSpec raster, ColorSpec color) {
  if (raster.width == null && raster.height == null) {
    return const Err(
      InvalidExportDimensions('raster needs a width or a height'),
    );
  }
  final dpi = raster.dpi;
  if (raster.unit != DimensionUnit.px) {
    if (dpi == null || dpi <= 0 || dpi > maxDpi) {
      return InvalidExportDimensions(
        'dpi $dpi required for ${raster.unit.name} output',
      ).asErr();
    }
  }
  final width = _toPx(raster.width, raster.unit, dpi);
  final height = _toPx(raster.height, raster.unit, dpi);
  for (final edge in [width, height]) {
    if (edge != null && (edge < 1 || edge > maxOutputEdgePx)) {
      return InvalidExportDimensions(
        'edge $edge px outside 1..$maxOutputEdgePx',
      ).asErr();
    }
  }
  return Ok(
    RasterPlan(
      width: width,
      height: height,
      fit: raster.fit,
      filter: raster.filter,
      color: color,
    ),
  );
}

int? _toPx(int? value, DimensionUnit unit, int? dpi) {
  if (value == null) {
    return null;
  }
  return switch (unit) {
    DimensionUnit.px => value,
    DimensionUnit.mm => (value / 25.4 * dpi!).round(),
    DimensionUnit.inch => value * dpi!,
  };
}

String _mimeOf(OutputFormat format) => switch (format) {
  OutputFormat.jpeg => 'image/jpeg',
  OutputFormat.png => 'image/png',
  OutputFormat.webp => 'image/webp',
  OutputFormat.pdf => 'application/pdf',
};

extension on VaultFailure {
  Result<T, VaultFailure> asErr<T>() => Err(this);
}
