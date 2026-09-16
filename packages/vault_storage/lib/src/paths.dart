/// On-disk layout (§7.1). No extensions, no human-readable names, a
/// 2-hex-char fan-out from the UUID, one directory per storage class.
library;

import 'package:path/path.dart' as p;
import 'package:vault_domain/vault_domain.dart';

final class BlobPaths {
  const BlobPaths(this.root);

  /// The app-private files directory (`getFilesDir()`), never external
  /// storage.
  final String root;

  static const _classDirs = <StorageClass, String>{
    StorageClass.asset: 'blobs',
    StorageClass.thumbnail: 'thumbs',
    StorageClass.exportArtifact: 'exports',
    StorageClass.syncLog: 'logs',
  };

  static String dirFor(StorageClass storageClass) => _classDirs[storageClass]!;

  static StorageClass? classForDir(String dir) {
    for (final entry in _classDirs.entries) {
      if (entry.value == dir) {
        return entry.key;
      }
    }
    return null;
  }

  /// Storage-relative path, e.g. `blobs/0a/0a3f1c8e-...`.
  static String relPathFor(StorageClass storageClass, BlobId id) =>
      '${dirFor(storageClass)}/${_fanOut(id)}/$id';

  /// Every relative path a blob with [id] could live at, one per class.
  static Iterable<String> candidateRelPaths(BlobId id) =>
      StorageClass.values.map((c) => relPathFor(c, id));

  String absolute(String relPath) =>
      p.join(root, p.joinAll(relPath.split('/')));

  String partFile(String relPath) => '${absolute(relPath)}.part';

  static String _fanOut(BlobId id) =>
      id.length >= 2 ? id.substring(0, 2).toLowerCase() : '00';

  /// The purpose byte a class is sealed under (§7.2).
  static EnvelopePurpose purposeFor(StorageClass storageClass) =>
      switch (storageClass) {
        StorageClass.asset => EnvelopePurpose.asset,
        StorageClass.thumbnail => EnvelopePurpose.thumbnail,
        StorageClass.exportArtifact => EnvelopePurpose.exportArtifact,
        StorageClass.syncLog => EnvelopePurpose.logSegment,
      };
}
