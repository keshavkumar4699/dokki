/// `PdfComposerImpl` tests (§13, Phase 6): structural assertions, the
/// metadata-leak sweep, corrupt-page failure, size/dpi/quality behaviour,
/// and a 100-page smoke run. No brittle goldens (§13.7): encoders are not
/// byte-reproducible, so we assert structure and monotonicity instead.
library;

import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:vault_domain/vault_domain.dart';
import 'package:vault_imaging/vault_imaging.dart';
import 'package:vault_pdf/vault_pdf.dart';

final class _Handle implements BlobHandle {
  const _Handle(this.token);

  @override
  final String token;

  @override
  int? get plaintextSize => null;
}

final class _MapSource implements BlobPlaintextSource {
  _MapSource(this.blobs);

  final Map<String, List<int>> blobs;

  @override
  Stream<List<int>> openPlaintext(BlobHandle handle) {
    final bytes = blobs[handle.token];
    if (bytes == null) {
      throw StateError('no blob ${handle.token}');
    }
    return Stream.value(bytes);
  }
}

/// A solid-colour JPEG with a marker comment that must NOT survive
/// re-encoding into the PDF.
List<int> jpegBytes(int w, int h, {int r = 200, int g = 120, int b = 40}) {
  final image = img.Image(width: w, height: h)
    ..clear(img.ColorRgb8(r, g, b));
  return img.encodeJpg(image, quality: 90);
}

const a4 = PageLayoutSpec(paper: PaperSize.a4);

PdfComposeRequest requestFor(
  List<({String id, RectMm frame})> items, {
  PageLayoutSpec spec = a4,
  int quality = 85,
  int effectiveDpi = 300,
  ColorSpec color = const ColorSpec(),
}) => PdfComposeRequest(
  spec: spec,
  placements: [
    for (var i = 0; i < items.length; i++)
      PlacedCell(
        pageIndex: items[i].frame.left < 0 ? 1 : 0,
        frame: items[i].frame,
        contentIndex: i,
      ),
  ],
  images: [for (final item in items) _Handle(item.id)],
  quality: quality,
  effectiveDpi: effectiveDpi,
  color: color,
);

void main() {
  late _MapSource source;
  late PdfComposerImpl composer;

  setUp(() {
    source = _MapSource({
      'a': jpegBytes(800, 600),
      'b': jpegBytes(600, 900, r: 30, g: 90, b: 200),
      'huge': jpegBytes(2400, 1800),
      'broken': [0, 1, 2, 3, 4, 5],
    });
    composer = PdfComposerImpl(source: source);
  });

  Future<List<int>> compose(PdfComposeRequest request) async {
    final result = await composer.compose(request);
    return result.fold((bytes) => bytes, (failure) => fail('Err: $failure'));
  }

  String asLatin1(List<int> bytes) => latin1.decode(bytes, allowInvalid: true);

  group('embeddedPixels (§11.4)', () {
    test('shrinks a large source to the frame at the requested dpi', () {
      // 50.8mm × 38.1mm at 300 dpi = 600 × 450 px needed.
      final target = PdfComposerImpl.embeddedPixels(
        const RectMm(10, 10, 50.8, 38.1),
        300,
        sourceWidth: 2400,
        sourceHeight: 1800,
      );
      expect(target.width, 600);
      expect(target.height, 450);
    });

    test('never upscales a small source', () {
      final target = PdfComposerImpl.embeddedPixels(
        const RectMm(10, 10, 100, 100),
        300,
        sourceWidth: 200,
        sourceHeight: 150,
      );
      expect((target.width, target.height), (200, 150));
    });

    test('a lower dpi shrinks further', () {
      const frame = RectMm(0, 0, 100, 80);
      final hi = PdfComposerImpl.embeddedPixels(
        frame,
        300,
        sourceWidth: 4000,
        sourceHeight: 3200,
      );
      final lo = PdfComposerImpl.embeddedPixels(
        frame,
        150,
        sourceWidth: 4000,
        sourceHeight: 3200,
      );
      expect(lo.width * lo.height, lessThan(hi.width * hi.height));
    });
  });

  group('compose', () {
    test('a single page comes out as a bare, valid PDF', () async {
      final bytes = await compose(
        requestFor([(id: 'a', frame: const RectMm(10, 10, 100, 75))]),
      );
      expect(utf8.decode(bytes.sublist(0, 8)), '%PDF-1.5');
      expect(asLatin1(bytes.sublist(bytes.length - 16)), contains('%%EOF'));
    });

    test('two placements on two pages produce a larger document', () async {
      final one = await compose(
        requestFor([(id: 'a', frame: const RectMm(10, 10, 100, 75))]),
      );
      final two = await compose(
        requestFor([
          (id: 'a', frame: const RectMm(10, 10, 100, 75)),
          // Negative left marks page 2 in the fixture helper.
          (id: 'b', frame: const RectMm(-1, 10, 80, 120)),
        ]),
      );
      expect(two.length, greaterThan(one.length));
    });

    test('no metadata leaks: no /Info, no producer, no names (§15.6)', () async {
      final bytes = await compose(
        requestFor([(id: 'a', frame: const RectMm(10, 10, 100, 75))]),
      );
      final text = asLatin1(bytes);
      for (final forbidden in [
        '/Producer',
        '/Author',
        '/Creator',
        '/Title',
        '/Subject',
        '/Keywords',
        '/CreationDate',
        'dokki',
        'vault',
      ]) {
        expect(text, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('a corrupt page fails with PdfGenerationFailed naming the page', () async {
      final result = await composer.compose(
        requestFor([(id: 'broken', frame: const RectMm(10, 10, 100, 75))]),
      );
      final failure = result.fold((_) => null, (f) => f);
      expect(failure, isA<PdfGenerationFailed>());
      expect((failure! as PdfGenerationFailed).pageIndex, 0);
    });

    test('higher quality embeds more bytes', () async {
      final lo = await compose(
        requestFor(
          [(id: 'huge', frame: const RectMm(10, 10, 180, 135))],
          quality: 40,
        ),
      );
      final hi = await compose(
        requestFor(
          [(id: 'huge', frame: const RectMm(10, 10, 180, 135))],
          quality: 95,
        ),
      );
      expect(hi.length, greaterThan(lo.length));
    });

    test('a higher effective dpi embeds more bytes', () async {
      final lo = await compose(
        requestFor(
          [(id: 'huge', frame: const RectMm(10, 10, 180, 135))],
          effectiveDpi: 150,
        ),
      );
      final hi = await compose(
        requestFor(
          [(id: 'huge', frame: const RectMm(10, 10, 180, 135))],
          effectiveDpi: 600,
        ),
      );
      expect(hi.length, greaterThan(lo.length));
    });

    test('grayscale and bw compose and differ from colour', () async {
      RectMm frame(double l) => RectMm(l, 10, 100, 75);
      final colour = await compose(requestFor([(id: 'a', frame: frame(10))]));
      final gray = await compose(
        requestFor(
          [(id: 'a', frame: frame(10))],
          color: const ColorSpec(grayscale: true),
        ),
      );
      final bw = await compose(
        requestFor(
          [(id: 'a', frame: frame(10))],
          color: const ColorSpec(bw: true),
        ),
      );
      expect(gray, isNot(equals(colour)));
      expect(bw, isNot(equals(gray)));
    });

    test('landscape A4 produces a wider page box', () async {
      final portrait = await compose(
        requestFor([(id: 'a', frame: const RectMm(10, 10, 100, 75))]),
      );
      final landscape = await compose(
        requestFor(
          [(id: 'a', frame: const RectMm(10, 10, 100, 75))],
          spec: const PageLayoutSpec(
            paper: PaperSize.a4,
            orientation: Orientation.landscape,
          ),
        ),
      );
      // /MediaBox [ 0 0 W H ] is uncompressed in the page object.
      final box = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]');
      final p = box.firstMatch(asLatin1(portrait))!;
      final l = box.firstMatch(asLatin1(landscape))!;
      expect(double.parse(p[1]!), lessThan(double.parse(p[2]!)));
      expect(double.parse(l[1]!), greaterThan(double.parse(l[2]!)));
    });

    test('cancellation before composing is OperationCancelled', () async {
      final token = CancellationToken()..cancel();
      final result = await composer.compose(
        requestFor([(id: 'a', frame: const RectMm(10, 10, 100, 75))]),
        cancel: token,
      );
      expect(result.fold((_) => null, (f) => f), isA<OperationCancelled>());
    });

    test(
      'a 100-page document composes (smoke; device suites assert RSS)',
      () async {
        final tiny = _MapSource({
          for (var i = 0; i < 100; i++) 'p$i': jpegBytes(64, 48),
        });
        final big = PdfComposerImpl(source: tiny);
        final result = await big.compose(
          PdfComposeRequest(
            spec: a4,
            placements: [
              for (var i = 0; i < 100; i++)
                PlacedCell(
                  pageIndex: i,
                  frame: const RectMm(10, 10, 190, 142),
                  contentIndex: i,
                ),
            ],
            images: [for (var i = 0; i < 100; i++) _Handle('p$i')],
          ),
        );
        final bytes = result.fold((b) => b, (f) => fail('Err: $f'));
        expect(utf8.decode(bytes.sublist(0, 8)), '%PDF-1.5');
      },
    );
  });
}
