/// Drift table definitions for the vault schema (ARCHITECTURE.md §6.1–§6.4).
///
/// Schema conventions (§6): IDs are TEXT UUIDs, timestamps are INTEGER
/// epoch-millis UTC ([MillisConverter]), enums are TEXT, HLCs are TEXT in
/// sortable form. Partial unique indexes (invariants I1/I6, single self
/// device, single active key epoch, …) cannot be expressed with the drift
/// table DSL, so they are created as raw SQL in `AppDatabase.onCreate`.
// Drift table DSL: `.check(col.isIn(...))` refers to the column being
// declared, which the analyzer reads as a recursive getter. This is the
// documented drift idiom, not a bug.
// ignore_for_file: recursive_getters
library;

import 'package:drift/drift.dart';

/// Stores [DateTime] as INTEGER epoch-millis UTC (§6 conventions).
///
/// Drift wraps this converter automatically on nullable columns, so `null`
/// round-trips without ever reaching [toSql] or [fromSql].
class MillisConverter extends TypeConverter<DateTime, int> {
  const MillisConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

/// One vault device (§6.1). Exactly one row has `is_self = 1`, enforced by
/// the partial unique index `ux_devices_self`.
@DataClassName('DeviceData')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get label => text().nullable()();
  BoolColumn get isSelf => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  TextColumn get lastSeenHlc => text().nullable()();
  IntColumn get lastSyncedAt =>
      integer().map(const MillisConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key/value metadata (`schema_version`, `active_key_epoch`, `install_id`, …).
@DataClassName('AppMetaData')
class AppMeta extends Table {
  TextColumn get key => text()();
  BlobColumn get value => blob()();

  @override
  Set<Column> get primaryKey => {key};
}

/// One key epoch (§8.1). `retired_at IS NULL` means active; at most one
/// active epoch, enforced by the partial unique index `ux_key_epoch_active`.
@DataClassName('KeyEpochData')
class KeyEpochs extends Table {
  IntColumn get epoch => integer()();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get retiredAt =>
      integer().map(const MillisConverter()).nullable()();
  TextColumn get wrapAlg => text()();
  BlobColumn get wrappedMkDevice => blob()();
  BlobColumn get wrappedMkRecovery => blob().nullable()();
  TextColumn get kdfParamsJson => text().nullable()();
  TextColumn get keystoreAlias => text()();
  BoolColumn get strongbox => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {epoch};
}

/// One vault entry (§6.1). `title_enc`/`note_enc`/`tags_enc` are sealed
/// under K_meta in Phase 2; in Phase 1 they hold plaintext bytes.
@DataClassName('VaultEntryData')
class VaultEntries extends Table {
  TextColumn get id => text()();
  TextColumn get type => text().check(
    type.isIn(const ['PHOTO', 'ID', 'SIGNATURE', 'THUMBPRINT', 'DOCUMENT']),
  )();
  BlobColumn get titleEnc => blob().nullable()();
  BlobColumn get noteEnc => blob().nullable()();
  BlobColumn get tagsEnc => blob().nullable()();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get updatedAt => integer().map(const MillisConverter())();
  TextColumn get updatedHlc => text()();
  TextColumn get originDevice =>
      text().references(Devices, #id, onDelete: KeyAction.restrict)();
  IntColumn get deletedAt =>
      integer().map(const MillisConverter()).nullable()();
  TextColumn get syncState =>
      text().withDefault(const Constant('LOCAL_ONLY'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One visual unit inside an entry (§5.1). Slot uniqueness (I6) is enforced
/// by the partial unique indexes `ux_assets_slot`/`ux_assets_singleton`.
///
/// Deviation from §6.1: `current_version_id` carries no `REFERENCES`
/// clause. Drift's code generator rejects the `assets ↔ asset_versions`
/// reference cycle (even when spelled as a raw `FOREIGN KEY` constraint),
/// so invariant I3 is enforced by the `trg_assets_current_*` triggers in
/// `AppDatabase.onCreate` instead. Those triggers are stricter than the FK
/// was: the pointer must name a *materialized* version *of the same
/// asset*, and a version that is current cannot be deleted.
@DataClassName('AssetData')
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().references(VaultEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text().check(
    role.isIn(const ['PRIMARY', 'ID_FRONT', 'ID_BACK', 'PAGE']),
  )();
  IntColumn get ordinal => integer()
      .withDefault(const Constant(0))
      .check(ordinal.isBiggerOrEqualValue(0))();
  TextColumn get currentVersionId => text().nullable()();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get updatedAt => integer().map(const MillisConverter())();
  TextColumn get updatedHlc => text()();
  TextColumn get originDevice =>
      text().references(Devices, #id, onDelete: KeyAction.restrict)();
  IntColumn get deletedAt =>
      integer().map(const MillisConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One immutable version of one asset's bytes (§5.3). Invariants I1 (single
/// ORIGINAL per asset) and I4/I2 are enforced by the partial unique index
/// `ux_version_original` and the CHECK constraints below.
@DataClassName('AssetVersionData')
class AssetVersions extends Table {
  TextColumn get id => text()();
  TextColumn get assetId =>
      text().references(Assets, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentVersionId => text().nullable().references(
    AssetVersions,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get kind =>
      text().check(kind.isIn(const ['ORIGINAL', 'DERIVED']))();
  IntColumn get seq => integer()();
  TextColumn get blobId =>
      text().nullable().references(Blobs, #id, onDelete: KeyAction.restrict)();
  TextColumn get recipeJson => text().nullable()();
  IntColumn get recipeSchemaVersion =>
      integer().withDefault(const Constant(1))();
  BoolColumn get recipeDeterministic =>
      boolean().withDefault(const Constant(true))();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  TextColumn get mime => text()();
  BlobColumn get plaintextSha256 => blob()();
  IntColumn get plaintextSize => integer()();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  TextColumn get createdHlc => text()();
  TextColumn get originDevice =>
      text().references(Devices, #id, onDelete: KeyAction.restrict)();
  IntColumn get evictedAt =>
      integer().map(const MillisConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    // I4: a DERIVED version always names its parent.
    "CHECK (kind = 'ORIGINAL' OR parent_version_id IS NOT NULL)",
    // I2: an ORIGINAL is never evicted (blob always present).
    "CHECK (kind = 'DERIVED' OR (blob_id IS NOT NULL AND evicted_at IS NULL))",
  ];
}

/// Retention pins (§10.4). Rows, so the eviction query is an anti-join.
@DataClassName('VersionPinData')
class VersionPins extends Table {
  TextColumn get versionId =>
      text().references(AssetVersions, #id, onDelete: KeyAction.cascade)();
  TextColumn get reason => text()();
  TextColumn get refId => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer().map(const MillisConverter())();

  @override
  Set<Column> get primaryKey => {versionId, reason, refId};
}

/// One sealed binary (§6.2). The `blobs` row is the recovery-side duplicate
/// of the envelope header; `rel_path` is unique (`ux_blobs_path`).
@DataClassName('BlobData')
class Blobs extends Table {
  TextColumn get id => text()();
  TextColumn get storageClass => text().check(
    storageClass.isIn(const ['ASSET', 'THUMBNAIL', 'EXPORT', 'SYNC_LOG']),
  )();
  TextColumn get relPath => text()();
  IntColumn get envelopeVersion => integer().withDefault(const Constant(1))();
  IntColumn get keyEpoch =>
      integer().references(KeyEpochs, #epoch, onDelete: KeyAction.restrict)();
  BlobColumn get wrappedDek => blob()();
  IntColumn get ciphertextSize => integer()();
  IntColumn get plaintextSize => integer()();
  BlobColumn get ciphertextSha256 => blob()();
  TextColumn get localState => text().check(
    localState.isIn(const ['PRESENT', 'EVICTED', 'REMOTE_ONLY', 'CORRUPT']),
  )();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get lastVerifiedAt =>
      integer().map(const MillisConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {relPath},
  ];
}

/// One thumbnail of one version (§7.5). Slot uniqueness via `ux_thumb_slot`.
@DataClassName('ThumbnailData')
class Thumbnails extends Table {
  TextColumn get id => text()();
  TextColumn get versionId =>
      text().references(AssetVersions, #id, onDelete: KeyAction.cascade)();
  TextColumn get sizeClass =>
      text().check(sizeClass.isIn(const ['S', 'M', 'L']))();
  TextColumn get blobId =>
      text().references(Blobs, #id, onDelete: KeyAction.restrict)();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  IntColumn get lastAccessedAt => integer().map(const MillisConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {versionId, sizeClass},
  ];
}

/// The record of one export (§6.3). Rows are never capacity-limited; the
/// artifact blob is nullable and expirable.
@DataClassName('ExportRecordData')
class ExportRecords extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().references(VaultEntries, #id, onDelete: KeyAction.restrict)();
  TextColumn get requestJson => text()();
  IntColumn get requestSchemaVersion => integer()();
  TextColumn get format => text()();
  TextColumn get layout => text().nullable()();
  TextColumn get paperSize => text().nullable()();
  IntColumn get outWidth => integer().nullable()();
  IntColumn get outHeight => integer().nullable()();
  IntColumn get dpi => integer().nullable()();
  IntColumn get quality => integer().nullable()();
  IntColumn get targetBytes => integer().nullable()();
  IntColumn get maxBytes => integer().nullable()();
  IntColumn get actualBytes => integer().nullable()();
  IntColumn get pageCount => integer().nullable()();
  TextColumn get status =>
      text().check(status.isIn(const ['SUCCESS', 'FAILED', 'CANCELLED']))();
  TextColumn get failureCode => text().nullable()();
  TextColumn get warningsJson => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get artifactBlobId =>
      text().nullable().references(Blobs, #id, onDelete: KeyAction.setNull)();
  BoolColumn get retainArtifact =>
      boolean().withDefault(const Constant(false))();
  IntColumn get artifactExpiresAt =>
      integer().map(const MillisConverter()).nullable()();
  IntColumn get createdAt => integer().map(const MillisConverter())();
  TextColumn get originDevice =>
      text().references(Devices, #id, onDelete: KeyAction.restrict)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Join table: an export may have many source versions (§6.3 deviation).
@DataClassName('ExportRecordSourceData')
class ExportRecordSources extends Table {
  TextColumn get exportId =>
      text().references(ExportRecords, #id, onDelete: KeyAction.cascade)();
  IntColumn get ordinal => integer()();
  TextColumn get versionId =>
      text().references(AssetVersions, #id, onDelete: KeyAction.restrict)();

  @override
  Set<Column> get primaryKey => {exportId, ordinal};
}

/// The sync work queue (§6.4). Idempotency via `ux_sync_idem`.
@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get opType => text()();
  TextColumn get targetKind => text()();
  TextColumn get targetId => text()();
  TextColumn get idempotencyKey => text()();
  IntColumn get priority => integer().withDefault(const Constant(100))();
  TextColumn get state => text()
      .withDefault(const Constant('PENDING'))
      .check(
        state.isIn(const ['PENDING', 'INFLIGHT', 'DONE', 'FAILED', 'DEAD']),
      )();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().map(const MillisConverter())();
  TextColumn get lastErrorCode => text().nullable()();
  IntColumn get lastErrorAt =>
      integer().map(const MillisConverter()).nullable()();
  TextColumn get resumeToken => text().nullable()();
  IntColumn get bytesDone => integer().withDefault(const Constant(0))();
  IntColumn get bytesTotal => integer().nullable()();
  TextColumn get leaseOwner => text().nullable()();
  IntColumn get leaseExpiresAt =>
      integer().map(const MillisConverter()).nullable()();
  IntColumn get createdAt => integer().map(const MillisConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [
    {idempotencyKey},
  ];
}

/// The remote pointer for one blob (§6.4). `remote_id` unique when set
/// (`ux_cloud_remote`), `remote_name` always unique (`ux_cloud_name`).
@DataClassName('CloudObjectData')
class CloudObjects extends Table {
  TextColumn get blobId =>
      text().references(Blobs, #id, onDelete: KeyAction.restrict)();
  TextColumn get remoteId => text().nullable()();
  TextColumn get remoteName => text()();
  IntColumn get remoteSize => integer().nullable()();
  TextColumn get remoteChecksum => text().nullable()();
  BlobColumn get ciphertextSha256 => blob()();
  IntColumn get keyEpoch => integer()();
  TextColumn get state => text().check(
    state.isIn(const [
      'LOCAL_ONLY',
      'UPLOADING',
      'UPLOADED',
      'REMOTE_ONLY',
      'MISSING',
      'TAMPERED',
    ]),
  )();
  IntColumn get uploadedAt =>
      integer().map(const MillisConverter()).nullable()();
  IntColumn get verifiedAt =>
      integer().map(const MillisConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {blobId};

  @override
  List<Set<Column>> get uniqueKeys => [
    {remoteName},
  ];
}

/// One sync log segment per (device, seq) (§6.4). `sealed_at IS NULL` means
/// the segment is still being appended to locally.
@DataClassName('SyncLogSegmentData')
class SyncLogSegments extends Table {
  TextColumn get deviceId =>
      text().references(Devices, #id, onDelete: KeyAction.restrict)();
  IntColumn get seq => integer()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get remoteName => text()();
  TextColumn get blobId =>
      text().nullable().references(Blobs, #id, onDelete: KeyAction.restrict)();
  IntColumn get opCount => integer().withDefault(const Constant(0))();
  TextColumn get hlcLow => text().nullable()();
  TextColumn get hlcHigh => text().nullable()();
  IntColumn get sealedAt => integer().map(const MillisConverter()).nullable()();
  IntColumn get uploadedAt =>
      integer().map(const MillisConverter()).nullable()();
  IntColumn get appliedAt =>
      integer().map(const MillisConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {deviceId, seq};
}

/// The replay cursor per remote device (§6.4).
@DataClassName('SyncCursorData')
class SyncCursor extends Table {
  TextColumn get deviceId =>
      text().references(Devices, #id, onDelete: KeyAction.cascade)();
  IntColumn get lastAppliedSeq => integer().withDefault(const Constant(0))();
  TextColumn get lastAppliedHlc => text().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// One sync conflict record (§9.5).
@DataClassName('ConflictData')
class Conflicts extends Table {
  TextColumn get id => text()();
  TextColumn get entityKind => text()();
  TextColumn get entityId => text()();
  TextColumn get localStateJson => text()();
  TextColumn get remoteStateJson => text()();
  TextColumn get provisionalWinner => text()();
  IntColumn get detectedAt => integer().map(const MillisConverter())();
  TextColumn get detectedHlc => text()();
  IntColumn get resolvedAt =>
      integer().map(const MillisConverter()).nullable()();
  TextColumn get resolution => text().nullable()();
  TextColumn get resolvedByDevice =>
      text().nullable().references(Devices, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stage one of two-stage deletion (§6.5).
@DataClassName('TombstoneData')
class Tombstones extends Table {
  TextColumn get entityKind => text()();
  TextColumn get entityId => text()();
  TextColumn get deletedHlc => text()();
  TextColumn get originDevice =>
      text().references(Devices, #id, onDelete: KeyAction.restrict)();
  IntColumn get purgeAfter => integer().map(const MillisConverter())();

  @override
  Set<Column> get primaryKey => {entityKind, entityId};
}

/// ADDED table (documented deviation): the durable buffer of unsealed ops.
///
/// Each op is appended here the moment it is accepted, before its segment
/// is sealed and uploaded, so a crash between "op accepted" and "segment
/// sealed" loses nothing. [seq] is the log segment the op was written into;
/// rows are purged once their segment has been applied (Phase 2 GC).
@DataClassName('SyncLogOpData')
class SyncLogOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text()();
  TextColumn get opJson => text()();
  TextColumn get hlc => text()();
  IntColumn get seq => integer()();
}
