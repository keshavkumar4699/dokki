/// Public export surface of `vault_persistence`.
///
/// The database file is SQLCipher-encrypted (Phase 2); Phase 1 uses plain
/// sqlite3 with the same schema.
library;

export 'src/database/app_database.dart';
export 'src/database/connection.dart';
export 'src/database/tables.dart';
export 'src/error_boundary.dart';
export 'src/export_request_codec.dart';
export 'src/repositories/blob_epoch_repository_impl.dart';
export 'src/repositories/entry_repository_impl.dart';
export 'src/repositories/key_epoch_repository_impl.dart';
export 'src/repositories/sync_apply_repository_impl.dart';
export 'src/repositories/sync_state_repository_impl.dart';
export 'src/repositories/thumbnail_index_impl.dart';
