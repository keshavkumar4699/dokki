/// The ONE translation boundary of `vault_persistence` (§12.3).
///
/// Converts sqlite3/drift exceptions into [VaultFailure] values. No other
/// file in this package may catch (enforced by `tool/check_boundaries.dart`).
library;

import 'package:drift/drift.dart' show InvalidDataException;
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:vault_domain/vault_domain.dart';

/// Carries a [VaultFailure] through the throw-based guard, mirroring the
/// pattern used by `vault_crypto`'s `PersistenceException`.
final class PersistenceException implements Exception {
  const PersistenceException(this.failure);

  final VaultFailure failure;
}

/// Runs [body] and translates every database-layer exception into a
/// [VaultFailure] value (§12.2).
Future<Result<T, VaultFailure>> guardDb<T>(
  String op,
  Future<T> Function() body,
) async {
  try {
    return Ok(await body());
  } on PersistenceException catch (e) {
    return Err(e.failure);
  } on SqliteException catch (e, s) {
    return Err(_translateSqlite(op, e, s));
  } on InvalidDataException catch (e, s) {
    return Err(DatabaseFailure(op, cause: e, trace: s));
  } on FormatException catch (e, s) {
    return Err(DatabaseFailure(op, cause: e, trace: s));
  }
}

VaultFailure _translateSqlite(String op, SqliteException e, StackTrace s) {
  switch (e.extendedResultCode) {
    case 787: // SQLITE_CONSTRAINT_FOREIGNKEY
    case 1811: // SQLITE_CONSTRAINT_TRIGGER (FK enforcement inside a trigger)
      return EntryInvariantViolated(
        'foreign key constraint violated',
        cause: e,
        trace: s,
      );
    case 2067: // SQLITE_CONSTRAINT_UNIQUE
      return EntryInvariantViolated(
        'unique constraint violated',
        cause: e,
        trace: s,
      );
    case 275: // SQLITE_CONSTRAINT_CHECK
      return EntryInvariantViolated(
        'check constraint violated',
        cause: e,
        trace: s,
      );
    case 13: // SQLITE_FULL
      return InsufficientStorage(0, 0, cause: e, trace: s);
    case 11: // SQLITE_CORRUPT
    case 26: // SQLITE_NOTADB
    default:
      return DatabaseFailure(op, cause: e, trace: s);
  }
}
