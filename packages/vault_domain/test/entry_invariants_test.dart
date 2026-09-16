import 'package:test/test.dart';
import 'package:vault_domain/src/assets/asset.dart';
import 'package:vault_domain/src/assets/asset_role.dart';
import 'package:vault_domain/src/entries/entry_invariants.dart';
import 'package:vault_domain/src/entries/entry_type.dart';
import 'package:vault_domain/src/entries/vault_entry.dart';
import 'package:vault_domain/src/failures/vault_failure.dart';
import 'package:vault_domain/src/imaging/image_meta.dart';
import 'package:vault_domain/src/sync/hlc.dart';
import 'package:vault_domain/src/versions/asset_version.dart';
import 'package:vault_domain/src/versions/version_kind.dart';

const _hlc = Hlc(1700000000000, 0, 'dev-a');
const _time = 1700000000000;
final _t = DateTime.fromMillisecondsSinceEpoch(_time);

ImageMeta _meta(String id) => ImageMeta(
  width: 100,
  height: 200,
  mime: 'image/jpeg',
  plaintextSha256: id.padLeft(64, '0'),
  byteSize: 1000,
);

AssetVersion _original(String assetId, {String? blobId}) => AssetVersion(
  id: 'v-$assetId-0',
  assetId: assetId,
  parentVersionId: null,
  kind: VersionKind.original,
  seq: 0,
  blobId: blobId ?? 'blob-$assetId',
  recipe: null,
  recipeDeterministic: true,
  meta: _meta(assetId),
  createdAt: _t,
  createdHlc: _hlc,
  originDevice: 'dev-a',
);

Asset _asset(
  String entryId,
  String id,
  AssetRole role,
  int ordinal, {
  String? blobId,
}) => Asset(
  id: id,
  entryId: entryId,
  role: role,
  ordinal: ordinal,
  currentVersionId: 'v-$id-0',
  createdAt: _t,
  updatedAt: _t,
  updatedHlc: _hlc,
  originDevice: 'dev-a',
  versions: [_original(id, blobId: blobId)],
);

VaultEntry _entry(
  EntryType type,
  List<Asset> assets, {
  List<AssetVersion> Function(String assetId)? versions,
}) {
  final withVersions = assets
      .map(
        (Asset a) =>
            versions == null ? a : a.copyWith(versions: versions(a.id)),
      )
      .toList(growable: false);
  return VaultEntry(
    id: 'entry-1',
    type: type,
    title: 'T',
    note: null,
    tags: const [],
    createdAt: _t,
    updatedAt: _t,
    updatedHlc: _hlc,
    originDevice: 'dev-a',
    assets: withVersions,
  );
}

void main() {
  group('EntryInvariants', () {
    test('valid entry of every type passes', () {
      final cases = {
        EntryType.photo: [_asset('e', 'a1', AssetRole.primary, 0)],
        EntryType.signature: [_asset('e', 'a1', AssetRole.primary, 0)],
        EntryType.thumbprint: [_asset('e', 'a1', AssetRole.primary, 0)],
        EntryType.id: [
          _asset('e', 'a1', AssetRole.idFront, 0),
          _asset('e', 'a2', AssetRole.idBack, 0),
        ],
        EntryType.document: [
          _asset('e', 'a1', AssetRole.page, 0),
          _asset('e', 'a2', AssetRole.page, 1),
          _asset('e', 'a3', AssetRole.page, 2),
        ],
      };
      for (final c in cases.entries) {
        final result = EntryInvariants.check(_entry(c.key, c.value));
        expect(
          result.isOk,
          isTrue,
          reason: '${c.key} should be valid: $result',
        );
      }
    });

    test('rejects disallowed roles', () {
      final entry = _entry(EntryType.photo, [
        _asset('e', 'a1', AssetRole.page, 0),
      ]);
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('PAGE not allowed'),
      );
    });

    test('rejects cardinality violations (I6)', () {
      final entry = _entry(EntryType.photo, [
        _asset('e', 'a1', AssetRole.primary, 0),
        _asset('e', 'a2', AssetRole.primary, 1),
      ]);
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('count 2'),
      );
    });

    test('rejects missing required role', () {
      final entry = _entry(EntryType.id, [
        _asset('e', 'a1', AssetRole.idBack, 0),
      ]);
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('ID_FRONT count 0'),
      );
    });

    test('rejects non-contiguous page ordinals (I7)', () {
      final entry = _entry(EntryType.document, [
        _asset('e', 'a1', AssetRole.page, 0),
        _asset('e', 'a2', AssetRole.page, 5),
      ]);
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('contiguous'),
      );
    });

    test('rejects duplicate ordinals (I6)', () {
      final entry = _entry(EntryType.document, [
        _asset('e', 'a1', AssetRole.page, 1),
        _asset('e', 'a2', AssetRole.page, 1),
      ]);
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('duplicate slot'),
      );
    });

    test('rejects a missing ORIGINAL (I1)', () {
      final asset = _asset(
        'e',
        'a1',
        AssetRole.primary,
        0,
      ).copyWith(versions: const []);
      final result = EntryInvariants.check(_entry(EntryType.photo, [asset]));
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('I1'),
      );
    });

    test('rejects an evicted ORIGINAL (I2)', () {
      final asset = _asset('e', 'a1', AssetRole.primary, 0);
      final entry = _entry(
        EntryType.photo,
        [asset],
        versions: (String assetId) => [
          _original(assetId).copyWith(blobId: null),
        ],
      );
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('I2'),
      );
    });

    test('rejects a DERIVED version without a parent (I4)', () {
      final entry = _entry(
        EntryType.photo,
        [_asset('e', 'a1', AssetRole.primary, 0)],
        versions: (String assetId) => [
          _original(assetId),
          AssetVersion(
            id: 'v-$assetId-1',
            assetId: assetId,
            parentVersionId: null,
            kind: VersionKind.derived,
            seq: 1,
            blobId: 'blob-x',
            recipe: null,
            recipeDeterministic: true,
            meta: _meta(assetId),
            createdAt: _t,
            createdHlc: _hlc,
            originDevice: 'dev-a',
          ),
        ],
      );
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('I4'),
      );
    });

    test('rejects a current pointer at an evicted version (I3)', () {
      final derived = AssetVersion(
        id: 'v-a1-1',
        assetId: 'a1',
        parentVersionId: 'v-a1-0',
        kind: VersionKind.derived,
        seq: 1,
        blobId: null,
        recipe: null,
        recipeDeterministic: true,
        meta: _meta('a1'),
        createdAt: _t,
        createdHlc: _hlc,
        originDevice: 'dev-a',
        evictedAt: _t,
      );
      final asset = _asset(
        'e',
        'a1',
        AssetRole.primary,
        0,
      ).copyWith(currentVersionId: 'v-a1-1');
      final entry = _entry(EntryType.photo, [
        asset,
      ], versions: (String assetId) => [_original(assetId), derived]);
      final result = EntryInvariants.check(entry);
      expect(result.isErr, isTrue);
      expect(
        (result.errOrNull as EntryInvariantViolated).invariant,
        contains('I3'),
      );
    });

    test('deleted assets do not count toward cardinality', () {
      final deleted = _asset(
        'e',
        'a2',
        AssetRole.primary,
        1,
      ).copyWith(deletedAt: _t);
      final entry = _entry(EntryType.photo, [
        _asset('e', 'a1', AssetRole.primary, 0),
        deleted,
      ]);
      expect(EntryInvariants.check(entry).isOk, isTrue);
    });
  });

  group('DocumentPageOrder', () {
    test('reorderTo assigns contiguous ordinals', () {
      final pages = [
        _asset('e', 'a1', AssetRole.page, 0),
        _asset('e', 'a2', AssetRole.page, 1),
        _asset('e', 'a3', AssetRole.page, 2),
      ];
      final reordered = pages.reorderTo(['a3', 'a1', 'a2']);
      expect(reordered.map((Asset a) => a.id), ['a3', 'a1', 'a2']);
      expect(reordered.map((Asset a) => a.ordinal), [0, 1, 2]);
      expect(reordered.hasContiguousOrdinals, isTrue);
    });

    test('reorderTo rejects unknown or duplicate ids', () {
      final pages = [
        _asset('e', 'a1', AssetRole.page, 0),
        _asset('e', 'a2', AssetRole.page, 1),
      ];
      expect(() => pages.reorderTo(['a1']), throwsArgumentError);
      expect(() => pages.reorderTo(['a1', 'a9']), throwsArgumentError);
    });
  });
}
