/// The wired object graph the presentation layer consumes. Only ports and
/// use cases — no concrete infrastructure type appears here, so features
/// can depend on this file without breaching §3.1.
library;

import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

/// Which crypto backend the composition root selected.
enum CryptoBackend {
  /// Kotlin + Keystore + Tink (§8). Not yet implemented natively.
  native,

  /// Pure Dart, keys in the heap, PIN-derived (M1). Development only.
  softwareDev,
}

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
}
