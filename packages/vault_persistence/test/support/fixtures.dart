/// Shared builders for persistence tests: deterministic ids, clock, HLCs,
/// and the minimal `NewEntry`/`NewAsset`/`BlobRef` shapes.
library;

import 'package:vault_domain/vault_domain.dart';
import 'package:vault_persistence/vault_persistence.dart';

const deviceA = 'device-aaaaaaaa';

final class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

final class SequenceIds implements IdGenerator {
  int _n = 0;

  @override
  String newEntityId() => 'e${(++_n).toString().padLeft(4, '0')}';

  @override
  String newBlobId() => 'b${(++_n).toString().padLeft(4, '0')}';
}

final class Fixtures {
  Fixtures({DateTime? start})
    : clock = FixedClock(start ?? DateTime.utc(2026)),
      ids = SequenceIds();

  final FixedClock clock;
  final SequenceIds ids;
  int _hlcCounter = 0;

  Hlc nextHlc() =>
      Hlc(clock.now().millisecondsSinceEpoch, _hlcCounter++, deviceA);

  BlobRef blob({int size = 1000}) {
    final id = ids.newBlobId();
    return BlobRef(
      id: id,
      storageClass: StorageClass.asset,
      relPath: 'blobs/${id.substring(0, 2)}/$id',
      keyEpoch: 1,
      wrappedDek: List<int>.filled(60, 7),
      plaintextSize: size,
      ciphertextSize: size + 128,
      ciphertextSha256: 'ab' * 32,
      plaintextSha256: 'cd' * 32,
    );
  }

  ImageMeta meta({int width = 800, int height = 600, int size = 1000}) =>
      ImageMeta(
        width: width,
        height: height,
        mime: 'image/jpeg',
        plaintextSha256: 'cd' * 32,
        byteSize: size,
      );

  NewAsset newAsset({
    required EntryId entryId,
    required AssetRole role,
    int ordinal = 0,
  }) {
    final assetId = ids.newEntityId();
    final blobRef = blob();
    final now = clock.now();
    final hlc = nextHlc();
    return NewAsset(
      id: assetId,
      entryId: entryId,
      role: role,
      ordinal: ordinal,
      hlc: hlc,
      originDevice: deviceA,
      createdAt: now,
      blob: blobRef,
      originalVersion: originalVersion(
        id: ids.newEntityId(),
        assetId: assetId,
        seq: 0,
        blobId: blobRef.id,
        meta: meta(),
        hlc: hlc,
        originDevice: deviceA,
        createdAt: now,
      ),
    );
  }

  NewEntry newEntry(
    EntryType type, {
    String? title,
    AssetRole? firstRole,
    List<String> tags = const [],
  }) {
    final entryId = ids.newEntityId();
    final role = firstRole ?? _defaultRole(type);
    return NewEntry(
      id: entryId,
      type: type,
      title: title ?? '${type.name} title',
      note: null,
      tags: tags,
      hlc: nextHlc(),
      originDevice: deviceA,
      createdAt: clock.now(),
      asset: newAsset(entryId: entryId, role: role),
    );
  }

  /// A DERIVED version + blob pair for `commitVersion`.
  (AssetVersion, BlobRef) derived({
    required AssetId assetId,
    required VersionId parentId,
    required int seq,
  }) {
    final blobRef = blob();
    final version = derivedVersion(
      id: ids.newEntityId(),
      assetId: assetId,
      parentVersionId: parentId,
      seq: seq,
      blobId: blobRef.id,
      recipe: const EditRecipe([RotateOp(1)]),
      meta: meta(),
      hlc: nextHlc(),
      originDevice: deviceA,
      createdAt: clock.now(),
    );
    return (version, blobRef);
  }

  static AssetRole _defaultRole(EntryType type) => switch (type) {
    EntryType.id => AssetRole.idFront,
    EntryType.document => AssetRole.page,
    _ => AssetRole.primary,
  };
}

/// Opens an in-memory DB and registers the self device and key epoch 1 so
/// the FK constraints on `origin_device` and `blobs.key_epoch` are
/// satisfiable — exactly what vault creation does in the real app.
Future<AppDatabase> openTestDb() async {
  final db = AppDatabase.inMemory();
  await SyncStateRepositoryImpl(db).ensureSelfDevice(
    id: deviceA,
    label: 'Test device',
    now: DateTime.utc(2026),
  );
  await KeyEpochRepositoryImpl(db).insertEpoch(
    KeyEpoch(
      epoch: 1,
      createdAt: DateTime.utc(2026),
      wrapAlgorithm: 'TEST',
      wrappedMkDevice: const [1, 2, 3],
      keystoreAlias: 'test.kek.1',
      strongbox: false,
    ),
  );
  return db;
}

T unwrap<T>(Result<T, VaultFailure> result) => result.fold(
  (value) => value,
  (failure) => throw StateError('expected Ok, got $failure: ${failure.cause}'),
);

VaultFailure unwrapErr<T>(Result<T, VaultFailure> result) => result.fold(
  (value) => throw StateError('expected Err, got Ok($value)'),
  (failure) => failure,
);
