import 'package:test/test.dart';
import 'package:vault_domain/src/imaging/geometry.dart';
import 'package:vault_domain/src/imaging/image_op.dart';
import 'package:vault_domain/src/versions/edit_recipe.dart';

void main() {
  group('geometry', () {
    test('RectN validates normalisation', () {
      expect(() => RectN(-0.1, 0, 1, 1), throwsA(isA<AssertionError>()));
      expect(() => RectN(0, 0, 1.1, 1), throwsA(isA<AssertionError>()));
      expect(() => RectN(0.5, 0, 0.4, 1), throwsA(isA<AssertionError>()));
      const ok = RectN(0.1, 0.2, 0.9, 0.8);
      expect(ok.width, closeTo(0.8, 1e-9));
      expect(ok.height, closeTo(0.6, 1e-9));
    });

    test('PointN validates range', () {
      expect(() => PointN(1.01, 0), throwsA(isA<AssertionError>()));
    });

    test('Quad.fullFrame is identity', () {
      const quad = Quad.fullFrame;
      expect(quad.topLeft, const PointN(0, 0));
      expect(quad.bottomRight, const PointN(1, 1));
      expect(quad.corners, hasLength(4));
    });
  });

  group('ImageOp serialisation', () {
    test('every op round-trips through JSON', () {
      const ops = <ImageOp>[
        CropOp(RectN(0.1, 0.2, 0.8, 0.9)),
        PerspectiveOp(
          Quad(
            PointN(0.05, 0.1),
            PointN(0.95, 0.05),
            PointN(0.9, 0.95),
            PointN(0.1, 0.9),
          ),
        ),
        RotateOp(3),
        BrightnessOp(0.25),
        ContrastOp(1.4),
        ExposureOp(0.7),
        SharpenOp(0.5),
        DenoiseOp(DenoiseStrength.medium),
        ResizeOp(width: 800, fit: FitMode.contain),
        FilterOp('grayscale'),
        BackgroundOp(BackgroundSpec(color: 0xFFFFFFFF, blurRadius: 2.5)),
      ];
      const recipe = EditRecipe(ops);
      final decoded = EditRecipe.fromJson(recipe.toJson());
      expect(decoded, recipe);
    });

    test('unknown op types throw FormatException', () {
      expect(
        () => EditRecipe.fromJson('[{"op":"magic"}]'),
        throwsFormatException,
      );
    });

    test('BackgroundOp is the only non-deterministic op', () {
      const ops = <ImageOp>[CropOp(RectN(0, 0, 0.5, 0.5)), RotateOp(1)];
      expect(const EditRecipe(ops).isDeterministic, isTrue);
      expect(
        const EditRecipe([
          BackgroundOp(BackgroundSpec(color: 0xFF000000)),
        ]).isDeterministic,
        isFalse,
      );
    });

    test('normalised coordinates hold across resolutions', () {
      // The same recipe applied at 4000 px and 400 px must produce the same
      // framing (§5.3).
      const crop = CropOp(RectN(0.25, 0.25, 0.75, 0.75));
      const big = (w: 4000, h: 3000);
      const small = (w: 400, h: 300);
      expect(crop.rect.left * big.w, 1000);
      expect(crop.rect.left * small.w, 100);
      expect(crop.rect.top * big.h, 750);
      expect(crop.rect.top * small.h, 75);
    });
  });

  group('EditRecipe', () {
    test('append and compose preserve order', () {
      const first = EditRecipe([RotateOp(1)]);
      const second = EditRecipe([BrightnessOp(0.1)]);
      final combined = first.compose(second);
      expect(combined.ops, hasLength(2));
      expect(combined.ops.first, isA<RotateOp>());
      expect(combined.ops.last, isA<BrightnessOp>());
    });

    test('empty recipe is deterministic and serialisable', () {
      const empty = EditRecipe.empty();
      expect(empty.isEmpty, isTrue);
      expect(empty.isDeterministic, isTrue);
      expect(EditRecipe.fromJson(empty.toJson()), empty);
    });
  });
}
