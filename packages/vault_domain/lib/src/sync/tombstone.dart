/// Tombstones: stage one of two-stage deletion (§6.5, M14).
library;

import '../ids.dart';
import 'hlc.dart';

enum TombstoneEntityKind {
  entry('ENTRY'),
  asset('ASSET'),
  version('VERSION'),
  export('EXPORT');

  const TombstoneEntityKind(this.dbValue);

  final String dbValue;

  static TombstoneEntityKind fromDbValue(String value) =>
      TombstoneEntityKind.values.firstWhere(
        (TombstoneEntityKind kind) => kind.dbValue == value,
        orElse: () => TombstoneEntityKind.entry,
      );
}

/// How long a tombstone is retained before the purge job may hard-delete.
const Duration tombstoneTtl = Duration(days: 180);

final class Tombstone {
  const Tombstone({
    required this.entityKind,
    required this.entityId,
    required this.deletedHlc,
    required this.originDevice,
    required this.purgeAfter,
  });

  /// Convenience constructor: purge after [deletedAt] + [tombstoneTtl].
  factory Tombstone.of({
    required TombstoneEntityKind entityKind,
    required String entityId,
    required Hlc deletedHlc,
    required DeviceId originDevice,
    required DateTime deletedAt,
  }) => Tombstone(
    entityKind: entityKind,
    entityId: entityId,
    deletedHlc: deletedHlc,
    originDevice: originDevice,
    purgeAfter: deletedAt.add(tombstoneTtl),
  );

  final TombstoneEntityKind entityKind;
  final String entityId;
  final Hlc deletedHlc;
  final DeviceId originDevice;

  /// `deletedAt + TOMBSTONE_TTL`.
  final DateTime purgeAfter;
}
