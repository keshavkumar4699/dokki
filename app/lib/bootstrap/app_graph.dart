/// The wired object graph the presentation layer consumes. Only ports and
/// use cases — no concrete infrastructure type appears here, so features
/// can depend on this file without breaching §3.1.
library;

import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

/// Which crypto backend the composition root selected.
enum CryptoBackend {
  /// Kotlin + Keystore (§8): auth-bound KEK, Argon2id, AES-GCM session.
  native,

  /// Pure Dart, keys in the heap, PIN-derived (M1). Development only.
  softwareDev,
}

/// A plaintext copy of an export artifact in the share cache, alive only
/// until [discard] runs (§7.1 "export output").
final class ShareHandle {
  const ShareHandle({
    required this.path,
    required this.mimeType,
    required this.fileName,
    required this.discard,
  });

  final String path;
  final String mimeType;
  final String fileName;
  final Future<void> Function() discard;
}

/// Decrypts an export's artifact for the system share sheet.
typedef PrepareShare =
    Future<Result<ShareHandle, VaultFailure>> Function(ExportId exportId);

final class AppGraph {
  const AppGraph({
    required this.context,
    required this.queries,
    required this.createEntry,
    required this.addAsset,
    required this.reorderPages,
    required this.deleteAsset,
    required this.updateEntryDetails,
    required this.deleteEntry,
    required this.commitEdit,
    required this.switchVersion,
    required this.thumbnails,
    required this.blobStore,
    required this.exports,
    required this.prepareShare,
  });

  final VaultContext context;
  final VaultQueries queries;
  final CreateEntryUseCase createEntry;
  final AddAssetUseCase addAsset;
  final ReorderPagesUseCase reorderPages;
  final DeleteAssetUseCase deleteAsset;
  final UpdateEntryDetailsUseCase updateEntryDetails;
  final DeleteEntryUseCase deleteEntry;
  final CommitEditUseCase commitEdit;
  final SwitchCurrentVersionUseCase switchVersion;
  final ThumbnailProvider thumbnails;

  /// Exposed only for the thumbnail bridge (`readSmall` of ≤1024 px
  /// previews). Widgets never call `write` or `openRead`.
  final BlobStore blobStore;

  final ExportUseCases exports;
  final PrepareShare prepareShare;
}
