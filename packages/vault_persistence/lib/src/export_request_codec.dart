/// JSON codec for [ExportRequest] (§6.3: `request_json` is the replayable
/// source of truth).
///
/// The domain defines no canonical wire format for requests, so this
/// package owns one. Corrupt data surfaces as a [FormatException], which
/// `guardDb` translates to `DATABASE_FAILURE`.
library;

import 'dart:convert';

import 'package:vault_domain/vault_domain.dart';

/// Serialises [request] to JSON text.
String encodeExportRequest(ExportRequest request) => jsonEncode({
  'schema': request.requestSchemaVersion,
  'source': _encodeSource(request.source),
  'format': request.format.dbValue,
  'raster': request.raster == null ? null : _encodeRaster(request.raster!),
  'quality': _encodeQuality(request.quality),
  'page': request.page == null ? null : _encodePage(request.page!),
  'color': _encodeColor(request.color),
  'extensions': request.extensions,
});

/// Parses a request written by [encodeExportRequest].
ExportRequest decodeExportRequest(String json) {
  final map = (jsonDecode(json) as Map).cast<String, Object?>();
  return ExportRequest(
    source: _decodeSource(_map(map, 'source')),
    format:
        OutputFormat.fromDbValue(_string(map, 'format') ?? '') ??
        _bad('format ${map['format']}'),
    quality: _decodeQuality(_map(map, 'quality')),
    raster: map['raster'] == null ? null : _decodeRaster(_map(map, 'raster')),
    page: map['page'] == null ? null : _decodePage(_map(map, 'page')),
    color: map['color'] == null
        ? const ColorSpec()
        : _decodeColor(_map(map, 'color')),
    extensions: (map['extensions'] as Map? ?? const {}).cast<String, Object?>(),
    requestSchemaVersion: _int(map, 'schema') ?? 1,
  );
}

Object? _encodeSource(ExportSource source) => switch (source) {
  SingleVersionSource(:final versionId) => {
    'kind': 'single',
    'versionId': versionId,
  },
  IdPairSource(:final front, :final back) => {
    'kind': 'idPair',
    'front': front,
    'back': back,
  },
  DocumentPagesSource(:final pages) => {'kind': 'pages', 'pages': pages},
  CurrentOfEntrySource(:final entryId) => {
    'kind': 'currentOfEntry',
    'entryId': entryId,
  },
};

Object? _encodeRaster(RasterSpec spec) => {
  'width': spec.width,
  'height': spec.height,
  'unit': spec.unit.name,
  'dpi': spec.dpi,
  'fit': spec.fit.name,
  'filter': spec.filter.name,
};

Object? _encodeQuality(QualitySpec spec) => {
  'quality': spec.quality,
  'targetBytes': spec.targetBytes,
  'maxBytes': spec.maxBytes,
  'minQualityFloor': spec.minQualityFloor,
  'allowDownscale': spec.allowDownscale,
};

Object? _encodePage(PageLayoutSpec spec) => {
  'paper': spec.paper.name,
  'orientation': spec.orientation.name,
  'margins': {
    'left': spec.margins.left,
    'top': spec.margins.top,
    'right': spec.margins.right,
    'bottom': spec.margins.bottom,
  },
  'spacingMm': spec.spacingMm,
  'layout': spec.layout.dbValue,
  'gridColumns': spec.gridColumns,
  'gridRows': spec.gridRows,
  'cellFit': spec.cellFit.name,
  'centerContent': spec.centerContent,
};

Object? _encodeColor(ColorSpec spec) => {
  'grayscale': spec.grayscale,
  'bw': spec.bw,
  'backgroundColor': spec.backgroundColor,
};

ExportSource _decodeSource(Map<String, Object?> map) =>
    switch (_string(map, 'kind')) {
      'single' => SingleVersionSource(
        _string(map, 'versionId') ?? _bad('versionId'),
      ),
      'idPair' => IdPairSource(
        front: map['front'] as String?,
        back: map['back'] as String?,
      ),
      'pages' => DocumentPagesSource(
        (map['pages'] as List? ?? const []).cast<String>(),
      ),
      'currentOfEntry' => CurrentOfEntrySource(
        _string(map, 'entryId') ?? _bad('entryId'),
      ),
      _ => _bad('source kind ${map['kind']}'),
    };

RasterSpec _decodeRaster(Map<String, Object?> map) => RasterSpec(
  width: _int(map, 'width'),
  height: _int(map, 'height'),
  unit:
      DimensionUnit.values.asNameMap()[_string(map, 'unit')] ??
      DimensionUnit.px,
  dpi: _int(map, 'dpi'),
  fit: FitMode.values.asNameMap()[_string(map, 'fit')] ?? FitMode.cover,
  filter:
      ResampleFilter.values.asNameMap()[_string(map, 'filter')] ??
      ResampleFilter.lanczos,
);

QualitySpec _decodeQuality(Map<String, Object?> map) => QualitySpec(
  quality: _int(map, 'quality'),
  targetBytes: _int(map, 'targetBytes'),
  maxBytes: _int(map, 'maxBytes'),
  minQualityFloor: _int(map, 'minQualityFloor') ?? 40,
  allowDownscale: map['allowDownscale'] as bool? ?? true,
);

PageLayoutSpec _decodePage(Map<String, Object?> map) {
  final margins = map['margins'] == null
      ? const EdgeInsetsMm()
      : _decodeMargins(_map(map, 'margins'));
  return PageLayoutSpec(
    paper: PaperSize.values.asNameMap()[_string(map, 'paper')] ?? PaperSize.a4,
    orientation:
        Orientation.values.asNameMap()[_string(map, 'orientation')] ??
        Orientation.portrait,
    margins: margins,
    spacingMm: (map['spacingMm'] as num?)?.toDouble() ?? 8,
    layout:
        LayoutMode.fromDbValue(_string(map, 'layout') ?? '') ??
        LayoutMode.single,
    gridColumns: _int(map, 'gridColumns') ?? 2,
    gridRows: _int(map, 'gridRows') ?? 2,
    cellFit:
        CellFit.values.asNameMap()[_string(map, 'cellFit')] ?? CellFit.fitCell,
    centerContent: map['centerContent'] as bool? ?? true,
  );
}

EdgeInsetsMm _decodeMargins(Map<String, Object?> map) => EdgeInsetsMm(
  left: (map['left'] as num?)?.toDouble() ?? 10,
  top: (map['top'] as num?)?.toDouble() ?? 10,
  right: (map['right'] as num?)?.toDouble() ?? 10,
  bottom: (map['bottom'] as num?)?.toDouble() ?? 10,
);

ColorSpec _decodeColor(Map<String, Object?> map) => ColorSpec(
  grayscale: map['grayscale'] as bool? ?? false,
  bw: map['bw'] as bool? ?? false,
  backgroundColor: _int(map, 'backgroundColor'),
);

Map<String, Object?> _map(Map<String, Object?> parent, String key) =>
    (parent[key] as Map? ?? const {}).cast<String, Object?>();

String? _string(Map<String, Object?> map, String key) => map[key] as String?;

int? _int(Map<String, Object?> map, String key) => (map[key] as num?)?.toInt();

Never _bad(String detail) =>
    throw FormatException('Corrupt export request: $detail');
