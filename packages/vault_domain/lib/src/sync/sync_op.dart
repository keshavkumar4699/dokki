/// The sync op-log schema (§9.3).
///
/// Each device appends ops to its own log segments; peers replay them
/// through a deterministic reducer. Unknown op types are preserved verbatim
/// and skipped, never dropped (§9.6) — that is handled at the serialisation
/// layer in `vault_sync`, which stores unknown ops as raw `UnknownSyncOp`
/// carriers.
library;

import 'dart:convert';

import '../ids.dart';
import '../imaging/image_meta.dart';
import 'conflict.dart';
import 'hlc.dart';
import 'tombstone.dart';

/// The op-log schema version this build emits (§9.6). Independent of the
/// database schema version.
const int currentOpSchemaVersion = 1;

/// One op-log entry. Ops are immutable once written.
sealed class SyncOp {
  const SyncOp({
    required this.hlc,
    required this.origin,
    this.opSchemaVersion = currentOpSchemaVersion,
  });

  final Hlc hlc;

  /// The device that originated the op (not necessarily the writer of the
  /// segment it is found in).
  final DeviceId origin;

  final int opSchemaVersion;

  /// Stable type tag.
  String get opType;

  Map<String, Object?> toJson() => {
    'op': opType,
    'hlc': hlc.toSortableString(),
    'origin': origin,
    'opSchemaVersion': opSchemaVersion,
  };

  static SyncOp fromJson(Map<String, Object?> json) {
    final hlc = Hlc.parse(json['hlc'] as String);
    final origin = json['origin'] as String;
    final opSchemaVersion = (json['opSchemaVersion'] as num).toInt();
    return switch (json['op'] as String) {
      'upsertEntry' => UpsertEntryOp.fromJson(
        hlc,
        origin,
        opSchemaVersion,
        json,
      ),
      'upsertAsset' => UpsertAssetOp.fromJson(
        hlc,
        origin,
        opSchemaVersion,
        json,
      ),
      'addVersion' => AddVersionOp.fromJson(hlc, origin, opSchemaVersion, json),
      'setCurrent' => SetCurrentOp.fromJson(hlc, origin, opSchemaVersion, json),
      'reorderPages' => ReorderPagesOp.fromJson(
        hlc,
        origin,
        opSchemaVersion,
        json,
      ),
      'evictVersion' => EvictVersionOp.fromJson(
        hlc,
        origin,
        opSchemaVersion,
        json,
      ),
      'tombstone' => TombstoneOp.fromJson(hlc, origin, opSchemaVersion, json),
      'resolveConflict' => ResolveConflictOp.fromJson(
        hlc,
        origin,
        opSchemaVersion,
        json,
      ),
      'deviceJoined' => DeviceJoinedOp.fromJson(
        hlc,
        origin,
        opSchemaVersion,
        json,
      ),
      _ => throw FormatException('Unknown SyncOp type: ${json['op']}'),
    };
  }
}

/// An op a NEWER peer wrote that we cannot interpret. Preserved verbatim so
/// a future upgrade can replay it (§9.6 rule 3).
final class UnknownSyncOp extends SyncOp {
  const UnknownSyncOp({
    required super.hlc,
    required super.origin,
    required super.opSchemaVersion,
    required this.rawJson,
  });

  final Map<String, Object?> rawJson;

  @override
  String get opType => 'unknown';

  @override
  Map<String, Object?> toJson() => rawJson;
}

/// Create/update an entry. `title`/`note`/`tags` travel sealed (opaque).
final class UpsertEntryOp extends SyncOp {
  const UpsertEntryOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.id,
    required this.type,
    required this.sealedTitleBase64,
    required this.sealedNoteBase64,
    required this.sealedTagsBase64,
    required this.createdAtMillis,
    required this.deletedAtMillis,
  });

  @override
  String get opType => 'upsertEntry';

  final EntryId id;

  /// DB value of the entry type (`PHOTO`, `DOCUMENT`, …). Kept as TEXT so
  /// unknown future types pass through (§6.6).
  final String type;

  final String? sealedTitleBase64;
  final String? sealedNoteBase64;
  final String? sealedTagsBase64;
  final int createdAtMillis;
  final int? deletedAtMillis;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'id': id,
    'type': type,
    'sealedTitleBase64': sealedTitleBase64,
    'sealedNoteBase64': sealedNoteBase64,
    'sealedTagsBase64': sealedTagsBase64,
    'createdAtMillis': createdAtMillis,
    'deletedAtMillis': deletedAtMillis,
  };

  static UpsertEntryOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => UpsertEntryOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    id: json['id'] as String,
    type: json['type'] as String,
    sealedTitleBase64: json['sealedTitleBase64'] as String?,
    sealedNoteBase64: json['sealedNoteBase64'] as String?,
    sealedTagsBase64: json['sealedTagsBase64'] as String?,
    createdAtMillis: (json['createdAtMillis'] as num).toInt(),
    deletedAtMillis: (json['deletedAtMillis'] as num?)?.toInt(),
  );
}

/// Create/update an asset row.
final class UpsertAssetOp extends SyncOp {
  const UpsertAssetOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.id,
    required this.entryId,
    required this.role,
    required this.ordinal,
    required this.createdAtMillis,
    this.deletedAtMillis,
  });

  @override
  String get opType => 'upsertAsset';

  final AssetId id;
  final EntryId entryId;

  /// DB value (`PRIMARY`, `ID_FRONT`, `PAGE`, …).
  final String role;

  final int ordinal;
  final int createdAtMillis;
  final int? deletedAtMillis;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'id': id,
    'entryId': entryId,
    'role': role,
    'ordinal': ordinal,
    'createdAtMillis': createdAtMillis,
    'deletedAtMillis': deletedAtMillis,
  };

  static UpsertAssetOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => UpsertAssetOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    id: json['id'] as String,
    entryId: json['entryId'] as String,
    role: json['role'] as String,
    ordinal: (json['ordinal'] as num).toInt(),
    createdAtMillis: (json['createdAtMillis'] as num).toInt(),
    deletedAtMillis: (json['deletedAtMillis'] as num?)?.toInt(),
  );
}

/// Add a new immutable version row to an asset.
final class AddVersionOp extends SyncOp {
  const AddVersionOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.id,
    required this.assetId,
    required this.parentVersionId,
    required this.kind,
    required this.seq,
    required this.blobId,
    required this.recipeJson,
    required this.recipeDeterministic,
    required this.meta,
    required this.createdAtMillis,
    this.evictedAtMillis,
    this.blobKeyEpoch,
    this.blobWrappedDekBase64,
    this.blobCiphertextSha256,
    this.blobCiphertextSize,
  });

  @override
  String get opType => 'addVersion';

  final VersionId id;
  final AssetId assetId;
  final VersionId? parentVersionId;

  /// `ORIGINAL` | `DERIVED`.
  final String kind;

  final int seq;
  final BlobId? blobId;
  final String? recipeJson;
  final bool recipeDeterministic;
  final ImageMeta meta;
  final int createdAtMillis;
  final int? evictedAtMillis;

  /// The blob-row fields a receiving device needs to register the blob as
  /// REMOTE_ONLY before downloading it (§9.9): the FK from
  /// `asset_versions.blob_id` demands the row exist, and the envelope
  /// header travels inside the op because the file may not be fetched for
  /// days. All present iff [blobId] is non-null.
  final int? blobKeyEpoch;
  final String? blobWrappedDekBase64;
  final String? blobCiphertextSha256;
  final int? blobCiphertextSize;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'id': id,
    'assetId': assetId,
    'parentVersionId': parentVersionId,
    'kind': kind,
    'seq': seq,
    'blobId': blobId,
    'recipeJson': recipeJson,
    'recipeDeterministic': recipeDeterministic,
    'meta': {
      'width': meta.width,
      'height': meta.height,
      'mime': meta.mime,
      'plaintextSha256': meta.plaintextSha256,
      'byteSize': meta.byteSize,
    },
    'createdAtMillis': createdAtMillis,
    'evictedAtMillis': evictedAtMillis,
    'blobKeyEpoch': blobKeyEpoch,
    'blobWrappedDekBase64': blobWrappedDekBase64,
    'blobCiphertextSha256': blobCiphertextSha256,
    'blobCiphertextSize': blobCiphertextSize,
  };

  static AddVersionOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) {
    final meta = (json['meta'] as Map<Object?, Object?>)
        .cast<String, Object?>();
    return AddVersionOp(
      hlc: hlc,
      origin: origin,
      opSchemaVersion: opSchemaVersion,
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      parentVersionId: json['parentVersionId'] as String?,
      kind: json['kind'] as String,
      seq: (json['seq'] as num).toInt(),
      blobId: json['blobId'] as String?,
      recipeJson: json['recipeJson'] as String?,
      recipeDeterministic: json['recipeDeterministic'] as bool,
      meta: ImageMeta(
        width: (meta['width'] as num).toInt(),
        height: (meta['height'] as num).toInt(),
        mime: meta['mime'] as String,
        plaintextSha256: meta['plaintextSha256'] as String,
        byteSize: (meta['byteSize'] as num).toInt(),
      ),
      createdAtMillis: (json['createdAtMillis'] as num).toInt(),
      evictedAtMillis: (json['evictedAtMillis'] as num?)?.toInt(),
      blobKeyEpoch: (json['blobKeyEpoch'] as num?)?.toInt(),
      blobWrappedDekBase64: json['blobWrappedDekBase64'] as String?,
      blobCiphertextSha256: json['blobCiphertextSha256'] as String?,
      blobCiphertextSize: (json['blobCiphertextSize'] as num?)?.toInt(),
    );
  }
}

/// Move an asset's current pointer.
final class SetCurrentOp extends SyncOp {
  const SetCurrentOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.assetId,
    required this.versionId,
  });

  @override
  String get opType => 'setCurrent';

  final AssetId assetId;
  final VersionId versionId;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'assetId': assetId,
    'versionId': versionId,
  };

  static SetCurrentOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => SetCurrentOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    assetId: json['assetId'] as String,
    versionId: json['versionId'] as String,
  );
}

/// Reorder a document's pages. [assetIds] is the full new order.
final class ReorderPagesOp extends SyncOp {
  const ReorderPagesOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.entryId,
    required this.assetIds,
  });

  @override
  String get opType => 'reorderPages';

  final EntryId entryId;
  final List<AssetId> assetIds;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'entryId': entryId,
    'assetIds': assetIds,
  };

  static ReorderPagesOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => ReorderPagesOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    entryId: json['entryId'] as String,
    assetIds: (json['assetIds'] as List<Object?>)
        .map((Object? id) => id as String)
        .toList(growable: false),
  );
}

/// Evict a version's binary. The row and recipe survive (§10.3).
final class EvictVersionOp extends SyncOp {
  const EvictVersionOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.versionId,
  });

  @override
  String get opType => 'evictVersion';

  final VersionId versionId;

  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'versionId': versionId};

  static EvictVersionOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => EvictVersionOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    versionId: json['versionId'] as String,
  );
}

/// Soft-delete an entity (stage one of two-stage deletion, §6.5).
final class TombstoneOp extends SyncOp {
  const TombstoneOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.entityKind,
    required this.entityId,
  });

  @override
  String get opType => 'tombstone';

  final TombstoneEntityKind entityKind;
  final String entityId;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'entityKind': entityKind.dbValue,
    'entityId': entityId,
  };

  static TombstoneOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => TombstoneOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    entityKind: TombstoneEntityKind.fromDbValue(json['entityKind'] as String),
    entityId: json['entityId'] as String,
  );
}

/// A user (or auto-policy) resolved an open conflict.
final class ResolveConflictOp extends SyncOp {
  const ResolveConflictOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.conflictId,
    required this.resolution,
  });

  @override
  String get opType => 'resolveConflict';

  final ConflictId conflictId;
  final ConflictResolution resolution;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'conflictId': conflictId,
    'resolution': resolution.name,
  };

  static ResolveConflictOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => ResolveConflictOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    conflictId: json['conflictId'] as String,
    resolution: ConflictResolution.values.firstWhere(
      (ConflictResolution r) => r.name == json['resolution'],
    ),
  );
}

/// A device joined the vault (§9.9 step 5).
final class DeviceJoinedOp extends SyncOp {
  const DeviceJoinedOp({
    required super.hlc,
    required super.origin,
    super.opSchemaVersion,
    required this.deviceId,
    required this.label,
  });

  @override
  String get opType => 'deviceJoined';

  final DeviceId deviceId;

  /// User-facing label; NOT sensitive in the threat model (§9.2 allows
  /// only routing props in Drive metadata — this travels inside the sealed
  /// log, so a plain label is acceptable there).
  final String label;

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'deviceId': deviceId,
    'label': label,
  };

  static DeviceJoinedOp fromJson(
    Hlc hlc,
    DeviceId origin,
    int opSchemaVersion,
    Map<String, Object?> json,
  ) => DeviceJoinedOp(
    hlc: hlc,
    origin: origin,
    opSchemaVersion: opSchemaVersion,
    deviceId: json['deviceId'] as String,
    label: json['label'] as String,
  );
}

/// Serialises an op to JSON text (the `vault_sync` layer encodes this via
/// CBOR on the wire; JSON is the canonical semantic form).
String encodeSyncOp(SyncOp op) => jsonEncode(op.toJson());

/// Parses a single op from JSON text.
SyncOp decodeSyncOp(String json) => SyncOp.fromJson(
  (jsonDecode(json) as Map<Object?, Object?>).cast<String, Object?>(),
);
