/// `PdfComposerImpl` (§11.3 step 6, §11.5): the `PdfComposer` port over
/// `package:pdf`. Takes `PlacedCell`s (pure mm geometry from the layout
/// engine) plus sealed image handles and emits document bytes.
///
/// §11.4 PDF size control is honoured here, not delegated to the library:
/// every image is decoded once per attempt, downsampled to the resolution
/// its frame actually needs at `effectiveDpi`, colour-treated, and
/// JPEG-encoded at `quality`. A 4000 px scan in a 90 mm cell at 300 DPI
/// needs about 1063 px — anything beyond that is pure waste.
///
/// Metadata policy (§15.6): a bare `pw.Document` writes no `/Info`
/// dictionary at all — no title, author, producer, or path. The
/// metadata-leak test asserts this, it is not assumed.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_imaging/vault_imaging.dart';

import 'error_boundary.dart';

final class PdfComposerImpl implements PdfComposer {
  const PdfComposerImpl({
    required this.source,
    this.maxDecodedPixels = 40 * 1000 * 1000,
  });

  /// Opens the plaintext of sealed blobs (§7.4). The composition root
  /// adapts the blob store to this seam.
  final BlobPlaintextSource source;

  /// Decode ceiling per image (R2), enforced *before* a pixel buffer is
  /// allocated.
  final int maxDecodedPixels;

  /// Points per millimetre: 1 pt = 1/72 in, 1 in = 25.4 mm.
  static const double mmToPt = 72.0 / 25.4;

  /// The frame [content]'s cell occupies, converted to the pixel size the
  /// embedded image needs at [dpi]. Pure geometry; unit-tested directly.
  static ({int width, int height}) embeddedPixels(
    RectMm frame,
    int dpi, {
    required int sourceWidth,
    required int sourceHeight,
  }) {
    final wantW = (frame.width / 25.4 * dpi).round().clamp(1, 1 << 20);
    final wantH = (frame.height / 25.4 * dpi).round().clamp(1, 1 << 20);
    // Shrink only: upscaling buys nothing but bytes.
    if (sourceWidth <= wantW && sourceHeight <= wantH) {
      return (width: sourceWidth, height: sourceHeight);
    }
    final scale = wantW / sourceWidth < wantH / sourceHeight
        ? wantW / sourceWidth
        : wantH / sourceHeight;
    return (
      width: (sourceWidth * scale).round().clamp(1, 1 << 20),
      height: (sourceHeight * scale).round().clamp(1, 1 << 20),
    );
  }

  @override
  Future<Result<List<int>, VaultFailure>> compose(
    PdfComposeRequest request, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardPdf(() async {
    final spec = request.spec;
    final base = PageLayoutSpec.paperSizeMm(spec.paper);
    final oriented = spec.orientation == Orientation.landscape
        ? (width: base.height, height: base.width)
        : (width: base.width, height: base.height);
    final pageFormat = PdfPageFormat(
      oriented.width * mmToPt,
      oriented.height * mmToPt,
    );

    // One placement per content index (the layout engine emits exactly
    // one cell per content item), so embedding follows placement order.
    final framesByContent = <int, RectMm>{
      for (final cell in request.placements) cell.contentIndex: cell.frame,
    };
    final embedded = <int, pw.MemoryImage>{};
    for (var i = 0; i < request.images.length; i++) {
      cancel?.throwIfCancelled();
      // The layout engine emits exactly one cell per content item; a
      // missing frame is a caller bug, not a runtime condition (§12.4).
      final frame = framesByContent[i]!;
      embedded[i] = await _embed(
        request,
        imageIndex: i,
        frame: frame,
        cancel: cancel,
      );
      progress?.call(i + 1, request.images.length);
    }

    final doc = pw.Document();
    final pageCount = request.placements.isEmpty
        ? 0
        : request.placements
                  .map((c) => c.pageIndex)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    for (var page = 0; page < pageCount; page++) {
      final cells = [
        for (final cell in request.placements)
          if (cell.pageIndex == page) cell,
      ];
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              for (final cell in cells)
                pw.Positioned(
                  left: cell.frame.left * mmToPt,
                  top: cell.frame.top * mmToPt,
                  // The frame is already aspect-fitted by the layout
                  // engine; fill places it exactly, without re-fitting.
                  child: pw.Image(
                    embedded[cell.contentIndex]!,
                    width: cell.frame.width * mmToPt,
                    height: cell.frame.height * mmToPt,
                    fit: pw.BoxFit.fill,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    cancel?.throwIfCancelled();
    return doc.save();
  });

  /// Decode → downsample to the frame's needs → colour → JPEG at the
  /// probed quality. Any decode failure on a page is a
  /// [PdfGenerationFailed] naming that page (§13, Phase 6).
  Future<pw.MemoryImage> _embed(
    PdfComposeRequest request, {
    required int imageIndex,
    required RectMm frame,
    CancellationToken? cancel,
  }) async {
    final handle = request.images[imageIndex];
    final decoded = await guardPdfPage(
      imageIndex,
      () async => decodeImageBytes(
        await readAllPlaintext(source, handle, cancel: cancel),
        maxDecodedPixels: maxDecodedPixels,
        cancel: cancel,
      ),
    );
    var image = decoded.image;
    final target = embeddedPixels(
      frame,
      request.effectiveDpi,
      sourceWidth: image.width,
      sourceHeight: image.height,
    );
    cancel?.throwIfCancelled();
    if (image.width != target.width || image.height != target.height) {
      image = img.copyResize(
        image,
        width: target.width,
        height: target.height,
        interpolation: img.Interpolation.cubic,
      );
    }
    if (request.color.bw) {
      image = img.luminanceThreshold(image);
    } else if (request.color.grayscale) {
      image = img.grayscale(image);
    }
    cancel?.throwIfCancelled();
    // JPEG has no alpha: composite onto the background (white by
    // default) so transparent scans do not come out black.
    if (image.hasAlpha) {
      final canvas = img.Image(width: image.width, height: image.height)
        ..clear(colorFromArgb(request.color.backgroundColor ?? 0xFFFFFFFF));
      image = img.compositeImage(canvas, image);
    }
    final jpeg = img.encodeJpg(image, quality: request.quality);
    return pw.MemoryImage(Uint8List.fromList(jpeg));
  }
}
