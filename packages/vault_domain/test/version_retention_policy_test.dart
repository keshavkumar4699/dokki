import 'package:test/test.dart';
import 'package:vault_domain/src/imaging/image_meta.dart';
import 'package:vault_domain/src/imaging/image_op.dart';
import 'package:vault_domain/src/sync/hlc.dart';
import 'package:vault_domain/src/versions/asset_version.dart';
import 'package:vault_domain/src/versions/edit_recipe.dart';
import 'package:vault_domain/src/versions/pin_set.dart';
import 'package:vault_domain/src/versions/version_graph.dart';
import 'package:vault_domain/src/versions/version_kind.dart';
import 'package:vault_domain/src/versions/version_retention_policy.dart';

const _hlc = Hlc(1, 0, 'dev');
final _t = DateTime.fromMillisecondsSinceEpoch(1000);

ImageMeta get _meta => const ImageMeta(
  width: 10,
  height: 10,
  mime: 'image/jpeg',
  plaintextSha256: 'x',
  byteSize: 10,
);

AssetVersion _version(
  String assetId,
  int seq, {
  String? blobId,
  VersionKind kind = VersionKind.derived,
  String? parent,
}) => AssetVersion(
  id: 'v$seq',
  assetId: assetId,
  parentVersionId: parent ?? (seq == 0 ? null : 'v${seq - 1}'),
  kind: kind,
  seq: seq,
  blobId: blobId,
  recipe: const EditRecipe([RotateOp(1)]),
  recipeDeterministic: true,
  meta: _meta,
  createdAt: _t,
  createdHlc: _hlc,
  originDevice: 'dev',
);

VersionGraph _graph({int derived = 3, int evicted = 0, String current = 'v3'}) {
  final versions = <AssetVersion>[
    _version('a', 0, kind: VersionKind.original, blobId: 'b-original'),
  ];
  for (var seq = 1; seq <= derived; seq++) {
    versions.add(_version('a', seq, blobId: seq <= evicted ? null : 'b$seq'));
  }
  return VersionGraph(versions: versions, currentId: current);
}

void main() {
  group('VersionGraph', () {
    test('original is found and permanent', () {
      final graph = _graph();
      expect(graph.original.seq, 0);
      expect(graph.original.isMaterialized, isTrue);
    });

    test('pathFromOriginal walks lineage root-first', () {
      final graph = _graph(derived: 4);
      final path = graph.pathFromOriginal('v3');
      expect(path.map((AssetVersion v) => v.id), ['v0', 'v1', 'v2', 'v3']);
    });

    test('pathFromOriginal throws on unknown version', () {
      expect(() => _graph().pathFromOriginal('v99'), throwsStateError);
    });

    test('isRematerializable only for evicted deterministic chains', () {
      final graph = _graph(evicted: 1);
      expect(graph['v1']!.isEvicted, isTrue);
      expect(graph.isRematerializable('v1'), isTrue);
      expect(
        graph.isRematerializable('v3'),
        isFalse,
        reason: 'materialized versions need no rematerialization',
      );
    });
  });

  group('KeepOriginalCurrentAndNPolicy', () {
    const policy = KeepOriginalCurrentAndNPolicy();

    test('never evicts original or current', () {
      final graph = _graph(derived: 10, current: 'v10');
      final evictable = policy.selectEvictable(graph, const PinSet.empty());
      expect(evictable, isNot(contains('v0')));
      expect(evictable, isNot(contains('v10')));
    });

    test('keeps exactly the newest N derived versions', () {
      final graph = _graph(derived: 6, current: 'v6');
      final evictable = policy.selectEvictable(graph, const PinSet.empty());
      // derived v1..v6; keep v6 (current), v5, v4, v3 → evict v1, v2
      expect(evictable, {'v1', 'v2'});
    });

    test('with 7th edit: original + current + 3 derived survive', () {
      // Phase 3 acceptance: creating a 7th edit leaves exactly
      // original + current + 3 derived materialized.
      final graph = _graph(derived: 7, current: 'v7');
      final evictable = policy.selectEvictable(graph, const PinSet.empty());
      expect(evictable, {'v1', 'v2', 'v3'});
      final retainedAfterEviction = graph.versions
          .where(
            (AssetVersion v) => v.isMaterialized && !evictable.contains(v.id),
          )
          .map((AssetVersion v) => v.id)
          .toSet();
      expect(retainedAfterEviction, {'v0', 'v4', 'v5', 'v6', 'v7'});
    });

    test('pinned versions are never evicted (P8)', () {
      final graph = _graph(derived: 6, current: 'v6');
      const pins = PinSet([
        Pin(versionId: 'v2', reason: PinReason.user, refId: ''),
        Pin(versionId: 'v1', reason: PinReason.conflict, refId: 'c1'),
      ]);
      final evictable = policy.selectEvictable(graph, pins);
      expect(evictable, isEmpty, reason: 'v1/v2 pinned; v3-v6 kept by depth');
    });

    test('evicted rows are not re-evicted', () {
      final graph = _graph(derived: 5, evicted: 2, current: 'v5');
      final evictable = policy.selectEvictable(graph, const PinSet.empty());
      expect(evictable, isNot(contains('v1')));
      expect(evictable, isNot(contains('v2')));
    });

    test('historyDepth = 0 evicts everything non-protected', () {
      const policy = KeepOriginalCurrentAndNPolicy(historyDepth: 0);
      final graph = _graph(derived: 4, current: 'v4');
      final evictable = policy.selectEvictable(graph, const PinSet.empty());
      expect(evictable, {'v1', 'v2', 'v3'});
    });
  });

  group('PinSet', () {
    test('tracks pins by id/reason/refId', () {
      const pins = PinSet([
        Pin(versionId: 'v1', reason: PinReason.exportRetained, refId: 'e1'),
        Pin(versionId: 'v1', reason: PinReason.user, refId: ''),
        Pin(versionId: 'v2', reason: PinReason.syncPending, refId: ''),
      ]);
      expect(pins.pinned, {'v1', 'v2'});
      expect(pins.isPinned('v1'), isTrue);
      expect(pins.hasPin('v1', PinReason.exportRetained, refId: 'e1'), isTrue);
      expect(
        pins
            .withoutPin(
              const Pin(versionId: 'v1', reason: PinReason.user, refId: ''),
            )
            .isPinned('v1'),
        isTrue,
        reason: 'still export-pinned',
      );
    });
  });
}
