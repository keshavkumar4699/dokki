/// How an in-process image pipeline reads the bytes behind a `BlobHandle`.
///
/// The native pipeline (Phase 4) opens the sealed file itself and keeps
/// plaintext in Kotlin. The Dart reference pipeline needs the decrypted
/// stream, which only the blob store can produce; the composition root
/// adapts `FileBlobStore.openPlaintext` to this interface.
library;

import 'package:vault_domain/vault_domain.dart';

abstract interface class BlobPlaintextSource {
  Stream<List<int>> openPlaintext(BlobHandle handle);
}
