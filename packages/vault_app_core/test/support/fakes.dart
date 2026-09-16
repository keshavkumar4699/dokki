/// In-memory test doubles for the ports (§13.6). Deterministic, no I/O.
library;

import 'dart:async';
import 'dart:convert';

import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

const testDevice = 'device-test0001';

final class FixedClock implements Clock {
  FixedClock([DateTime? start]) : _now = start ?? DateTime.utc(2026);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

final class SequenceIds implements IdGenerator {
  int _n = 0;

  @override
  String newEntityId() => 'e${(++_n).toString().padLeft(3, '0')}';

  @override
  String newBlobId() => 'b${(++_n).toString().padLeft(3, '0')}';
}

final class SeededRandom implements RandomSource {
  int _seed = 1;

  @override
  void fillBytes(List<int> out) {
    for (var i = 0; i < out.length; i++) {
      out[i] = nextInt(256);
    }
  }

  @override
  int nextInt(int max) =>
      (_seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF) % max;
}

VaultContext testContext({FixedClock? clock, SequenceIds? ids}) => VaultContext(
  deviceId: testDevice,
  clock: clock ?? FixedClock(),
  ids: ids ?? SequenceIds(),
  random: SeededRandom(),
);

// ── BlobStore ───────────────────────────────────────────────────────────

final class MemoryHandle implements BlobHandle {
  const MemoryHandle(this.token, this.plaintextSize);

  @override
  final String token;

  @override
  final int? plaintextSize;
}

/// Stores plaintext bytes keyed by blob id; "sealing" is a no-op so tests
/// can assert on content. Digest = a stable fake hash of the bytes.
final class InMemoryBlobStore implements BlobStore {
  InMemoryBlobStore({this.ids});

  final IdGenerator? ids;
  final Map<BlobId, List<int>> blobs = {};
  final List<BlobId> purged = [];
  bool failWrites = false;
  int _n = 0;

  static String fakeSha(List<int> bytes) {
    var h = 0x811c9dc5;
    for (final b in bytes) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0') * 8;
  }

  @override
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    if (failWrites) {
      return const Err(StorageIoFailure('write'));
    }
    final bytes = <int>[];
    await for (final chunk in source) {
      cancel?.throwIfCancelled();
      bytes.addAll(chunk);
      progress?.call(bytes.length, expectedSize);
    }
    final id = ids?.newBlobId() ?? 'blob${++_n}';
    blobs[id] = bytes;
    return Ok(
      BlobRef(
        id: id,
        storageClass: storageClass,
        relPath: 'blobs/${id.substring(0, 2)}/$id',
        keyEpoch: 1,
        wrappedDek: const [1, 2, 3],
        plaintextSize: bytes.length,
        ciphertextSize: bytes.length + 64,
        ciphertextSha256: fakeSha([...bytes, 1]),
        plaintextSha256: fakeSha(bytes),
      ),
    );
  }

  @override
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id) async {
    final bytes = blobs[id];
    if (bytes == null) {
      return Err(CorruptFile(id));
    }
    return Ok(MemoryHandle(id, bytes.length));
  }

  @override
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  }) async {
    final bytes = blobs[id];
    if (bytes == null) {
      return Err(CorruptFile(id));
    }
    return Ok(bytes);
  }

  @override
  Future<Result<void, VaultFailure>> verify(BlobId id) async =>
      blobs.containsKey(id) ? const Ok(null) : Err(CorruptFile(id));

  @override
  Stream<List<int>>? ciphertextStream(BlobHandle handle) {
    final bytes = blobs[handle.token];
    return bytes == null ? null : Stream.value(bytes);
  }

  @override
  Future<Result<({int ciphertextSize, String ciphertextSha256}), VaultFailure>>
  writeSealed(
    BlobId id,
    Stream<List<int>> ciphertext, {
    StorageClass storageClass = StorageClass.asset,
    required String expectedCiphertextSha256,
    CancellationToken? cancel,
  }) async {
    final bytes = <int>[];
    await for (final chunk in ciphertext) {
      cancel?.throwIfCancelled();
      bytes.addAll(chunk);
    }
    final digest = fakeSha(bytes);
    if (expectedCiphertextSha256.isNotEmpty &&
        digest != expectedCiphertextSha256) {
      return Err(RemoteObjectTampered(id));
    }
    blobs[id] = bytes;
    return Ok((ciphertextSize: bytes.length, ciphertextSha256: digest));
  }

  @override
  Future<Result<void, VaultFailure>> evict(BlobId id) => purge(id);

  @override
  Future<Result<void, VaultFailure>> purge(BlobId id) async {
    blobs.remove(id);
    purged.add(id);
    return const Ok(null);
  }

  @override
  Future<Result<bool, VaultFailure>> exists(BlobId id) async =>
      Ok(blobs.containsKey(id));
}

// ── ImageProcessor ──────────────────────────────────────────────────────

/// Treats blob bytes as UTF-8 text `"<w>x<h>"` plus a trailing op log, so
/// every op is a deterministic string transform the tests can inspect.
final class FakeImageProcessor implements ImageProcessor {
  FakeImageProcessor(this.store);

  final InMemoryBlobStore store;
  final List<List<ImageOp>> applied = [];

  static List<int> encode(int w, int h, [String ops = '']) =>
      utf8.encode('${w}x$h|$ops');

  static (int, int, String) decode(List<int> bytes) {
    final text = utf8.decode(bytes);
    final bar = text.indexOf('|');
    final dims = text.substring(0, bar).split('x');
    return (int.parse(dims[0]), int.parse(dims[1]), text.substring(bar + 1));
  }

  @override
  Future<Result<ImageInfo, VaultFailure>> inspect(BlobHandle source) async {
    final bytes = store.blobs[source.token];
    if (bytes == null) {
      return Err(CorruptFile(source.token));
    }
    final (w, h, _) = decode(bytes);
    return Ok(ImageInfo(width: w, height: h, mime: 'image/jpeg'));
  }

  @override
  Future<Result<ProcessedImage, VaultFailure>> apply(
    BlobHandle source, {
    required List<ImageOp> ops,
    DecodeSpec? decode,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => applyChain(source, chain: [ops], progress: progress, cancel: cancel);

  @override
  Future<Result<ProcessedImage, VaultFailure>> applyChain(
    BlobHandle original, {
    required List<List<ImageOp>> chain,
    DecodeSpec? decode,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final bytes = store.blobs[original.token];
    if (bytes == null) {
      return Err(CorruptFile(original.token));
    }
    var (w, h, log) = FakeImageProcessor.decode(bytes);
    for (final ops in chain) {
      applied.add(ops);
      for (final op in ops) {
        cancel?.throwIfCancelled();
        if (op is RotateOp && op.quarterTurns.isOdd) {
          (w, h) = (h, w);
        }
        log = '$log${op.opType};';
      }
    }
    final written = await store.write(
      Stream.value(encode(w, h, log)),
      storageClass: StorageClass.asset,
      expectedSize: 0,
    );
    return written.map(
      (blob) => ProcessedImage(
        blobRef: blob,
        meta: ImageMeta(
          width: w,
          height: h,
          mime: 'image/jpeg',
          plaintextSha256: blob.plaintextSha256,
          byteSize: blob.plaintextSize,
        ),
      ),
    );
  }

  @override
  Future<Result<ProcessedImage, VaultFailure>> preview(
    BlobHandle source, {
    int maxEdge = 1024,
    String preferredMime = 'image/jpeg',
    int quality = 85,
    StorageClass storageClass = StorageClass.thumbnail,
  }) => applyChain(source, chain: const []);
}

// ── ThumbnailProvider ───────────────────────────────────────────────────

final class FakeThumbnailProvider implements ThumbnailProvider {
  final List<AssetId> invalidated = [];

  @override
  Stream<ThumbnailState> request(
    VersionId versionId,
    ThumbnailSizeClass size,
  ) => const Stream.empty();

  @override
  Future<Result<void, VaultFailure>> invalidate(AssetId assetId) async {
    invalidated.add(assetId);
    return const Ok(null);
  }

  @override
  Future<Result<int, VaultFailure>> trimToBudget(int maxBytes) async =>
      const Ok(0);
}

// ── KeyManager ──────────────────────────────────────────────────────────

final class FakeKeyManager implements KeyManager {
  FakeKeyManager({this.pin = '1234', this.hasVault = true});

  final String pin;
  bool hasVault;
  bool _unlocked = false;
  int lockCalls = 0;

  @override
  bool get isUnlocked => _unlocked;

  @override
  LockState get lockState => _unlocked ? LockState.unlocked : LockState.locked;

  @override
  int? get activeKeyEpoch => hasVault ? 1 : null;

  @override
  Future<Result<void, VaultFailure>> createVault({
    required String pin,
    required String recoveryPassphrase,
  }) async {
    hasVault = true;
    _unlocked = true;
    return const Ok(null);
  }

  @override
  Future<Result<void, VaultFailure>> unlock({
    String? pin,
    bool biometric = false,
  }) async {
    if (biometric || pin == this.pin) {
      _unlocked = true;
      return const Ok(null);
    }
    return const Err(AuthenticationFailed(4));
  }

  @override
  Future<Result<bool, VaultFailure>> verifyPin(String pin) async =>
      Ok(pin == this.pin);

  @override
  Future<Result<void, VaultFailure>> lock() async {
    _unlocked = false;
    lockCalls++;
    return const Ok(null);
  }

  @override
  Future<Result<bool, VaultFailure>> verifyRecoveryPassphrase(
    String passphrase,
  ) async => const Ok(true);

  @override
  Future<Result<void, VaultFailure>> changeRecoveryPassphrase(
    String newPassphrase,
  ) async => const Ok(null);

  @override
  Future<Result<void, VaultFailure>> rotate({
    required String pin,
    required String recoveryPassphrase,
  }) async => const Ok(null);

  @override
  Future<Result<List<int>, VaultFailure>> rewrapDek({
    required List<int> wrappedDek,
    required int fromEpoch,
    required int toEpoch,
    required int purpose,
  }) async => Ok(wrappedDek);

  @override
  Future<Result<RecoveryKeyringBlob, VaultFailure>> exportKeyring({
    required DeviceId deviceId,
  }) async => Ok(
    RecoveryKeyringBlob(
      formatVersion: 1,
      deviceId: deviceId,
      createdAt: DateTime.utc(2026),
      epochs: const [],
    ),
  );

  @override
  Future<Result<void, VaultFailure>> importKeyring({
    required RecoveryKeyringBlob keyring,
    required String recoveryPassphrase,
    required String pin,
  }) async => const Ok(null);

  @override
  Future<Result<List<int>, VaultFailure>> deriveDbKey() async => _unlocked
      ? Ok(List<int>.filled(32, 7))
      : const Err(KeyUnavailable(KeyUnavailableReason.vaultLocked));
}

// ── Helpers ─────────────────────────────────────────────────────────────

ImportSource sourceOf(int w, int h) {
  final bytes = FakeImageProcessor.encode(w, h);
  return ImportSource(
    open: () => Stream.value(bytes),
    byteSize: bytes.length,
    mimeHint: 'image/jpeg',
  );
}

T unwrap<T>(Result<T, VaultFailure> result) => result.fold(
  (value) => value,
  (failure) => throw StateError('expected Ok, got $failure'),
);

VaultFailure unwrapErr<T>(Result<T, VaultFailure> result) => result.fold(
  (value) => throw StateError('expected Err, got Ok($value)'),
  (failure) => failure,
);
