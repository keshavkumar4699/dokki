/// Fakes for the export pipeline: a raster with a known size curve, an
/// in-memory blob store, a recording repository and a canned resolver.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:vault_domain/vault_domain.dart';

/// A raster whose encoded size follows a known, monotonic curve:
/// `bytes = area × (0.02 + 0.0098 × quality)` for JPEG, and a fixed
/// `area × 1.2` for PNG. Downscaling multiplies the area.
final class CurveRaster implements PreparedRaster {
  CurveRaster({
    required this.width,
    required this.height,
    int? sourceWidth,
    int? sourceHeight,
  }) : sourceWidth = sourceWidth ?? width,
       sourceHeight = sourceHeight ?? height;

  @override
  final int width;
  @override
  final int height;
  @override
  final int sourceWidth;
  @override
  final int sourceHeight;

  final List<int> probedQualities = [];
  bool disposed = false;

  int bytesAt(OutputFormat format, int quality) {
    final area = width * height;
    return switch (format) {
      OutputFormat.png => (area * 1.2).round(),
      _ => (area * (0.02 + 0.0098 * quality)).round(),
    };
  }

  @override
  Future<int> measure(OutputFormat format, int quality) async {
    probedQualities.add(quality);
    return bytesAt(format, quality);
  }

  @override
  Future<EncodedRaster> encode(OutputFormat format, int quality) async =>
      EncodedRaster(
        bytes: List<int>.filled(bytesAt(format, quality), 0x42),
        width: width,
        height: height,
        format: format,
        quality: quality,
      );

  @override
  Future<PreparedRaster> downscale(double factor) async => CurveRaster(
    width: math.max(1, (width * factor).round()),
    height: math.max(1, (height * factor).round()),
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );

  @override
  void dispose() => disposed = true;
}

final class FakeRasterEngine implements RasterEngine {
  FakeRasterEngine({this.width = 1000, this.height = 800, this.failure});

  final int width;
  final int height;
  final VaultFailure? failure;
  RasterPlan? lastPlan;
  CurveRaster? lastRaster;

  @override
  Future<Result<PreparedRaster, VaultFailure>> prepare(
    BlobHandle source, {
    required RasterPlan plan,
    CancellationToken? cancel,
  }) async {
    lastPlan = plan;
    if (failure != null) {
      return Err(failure!);
    }
    final w = plan.width ?? width;
    final h = plan.height ?? height;
    return Ok(
      lastRaster = CurveRaster(
        width: w,
        height: h,
        sourceWidth: width,
        sourceHeight: height,
      ),
    );
  }
}

final class MemHandle implements BlobHandle {
  const MemHandle(this.token, this.plaintextSize);

  @override
  final String token;
  @override
  final int? plaintextSize;
}

final class MemBlobStore implements BlobStore {
  final Map<BlobId, List<int>> blobs = {};
  final Map<BlobId, StorageClass> classes = {};
  final List<BlobId> purged = [];
  int _next = 0;
  VaultFailure? failNextWrite;

  @override
  Future<Result<BlobHandle, VaultFailure>> openRead(BlobId id) async =>
      blobs.containsKey(id)
      ? Ok(MemHandle(id, blobs[id]!.length))
      : Err(CorruptFile(id));

  @override
  Future<Result<BlobRef, VaultFailure>> write(
    Stream<List<int>> source, {
    required StorageClass storageClass,
    required int expectedSize,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    final failure = failNextWrite;
    if (failure != null) {
      failNextWrite = null;
      return Err(failure);
    }
    final bytes = <int>[];
    await source.forEach(bytes.addAll);
    final id = 'blob-${_next++}';
    blobs[id] = bytes;
    classes[id] = storageClass;
    return Ok(
      BlobRef(
        id: id,
        storageClass: storageClass,
        relPath: 'mem/$id',
        keyEpoch: 1,
        wrappedDek: const [0],
        plaintextSize: bytes.length,
        ciphertextSize: bytes.length + 64,
        ciphertextSha256: 'ab' * 32,
        plaintextSha256: 'cd' * 32,
      ),
    );
  }

  @override
  Future<Result<List<int>, VaultFailure>> readSmall(
    BlobId id, {
    int maxBytes = 256 * 1024,
  }) async => blobs.containsKey(id) ? Ok(blobs[id]!) : Err(CorruptFile(id));

  @override
  Future<Result<void, VaultFailure>> verify(BlobId id) async => const Ok(null);

  @override
  Future<Result<void, VaultFailure>> evict(BlobId id) => purge(id);

  @override
  Future<Result<void, VaultFailure>> purge(BlobId id) async {
    blobs.remove(id);
    classes.remove(id);
    purged.add(id);
    return const Ok(null);
  }

  @override
  Future<Result<bool, VaultFailure>> exists(BlobId id) async =>
      Ok(blobs.containsKey(id));
}

/// Only the export methods are real; everything else is unreachable from
/// the engine.
final class RecordingEntries implements EntryRepository {
  final List<ExportRecord> records = [];
  VaultFailure? failNextRecord;

  @override
  Future<Result<void, VaultFailure>> recordExport(ExportRecord record) async {
    final failure = failNextRecord;
    if (failure != null) {
      failNextRecord = null;
      return Err(failure);
    }
    records.add(record);
    return const Ok(null);
  }

  @override
  Future<Result<ExportRecord?, VaultFailure>> findExportRecord(
    ExportId id,
  ) async => Ok(records.where((r) => r.id == id).firstOrNull);

  @override
  Future<Result<List<ExportRecordSummary>, VaultFailure>> listExportRecords(
    EntryId entryId,
  ) async => const Ok([]);

  @override
  Future<Result<List<BlobId>, VaultFailure>> releaseExportArtifacts({
    required DateTime now,
  }) async => const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// A composer with a known size curve so the §11.4 PDF search is tested
/// independently of any real codec: per image,
/// `baseBytes × (0.02 + 0.0098 × quality) × (dpi / 300)`, plus a fixed
/// document overhead. Records every probe.
final class FakePdfComposer implements PdfComposer {
  FakePdfComposer({this.baseBytes = 20000, this.failure});

  final int baseBytes;
  VaultFailure? failure;
  final List<({int quality, int effectiveDpi})> probes = [];
  PdfComposeRequest? lastRequest;

  @override
  Future<Result<List<int>, VaultFailure>> compose(
    PdfComposeRequest request, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) async {
    lastRequest = request;
    final failure = this.failure;
    if (failure != null) {
      return Err(failure);
    }
    probes.add((quality: request.quality, effectiveDpi: request.effectiveDpi));
    final perImage =
        baseBytes *
        (0.02 + 0.0098 * request.quality) *
        (request.effectiveDpi / 300);
    final size = (request.images.length * perImage).round() + 500;
    return Ok(List<int>.filled(size, 0x25));
  }
}

final class CannedResolver implements ExportSourceResolver {
  CannedResolver(this.sources, {this.failure});

  final List<ResolvedSource> sources;
  final VaultFailure? failure;
  ExportSource? lastSource;

  @override
  Future<Result<List<ResolvedSource>, VaultFailure>> resolve(
    ExportSource source,
  ) async {
    lastSource = source;
    return failure != null ? Err(failure!) : Ok(sources);
  }
}

ResolvedSource resolved({
  String entryId = 'entry-1',
  String assetId = 'asset-1',
  String versionId = 'v-1',
  String blobId = 'blob-src',
  int width = 1000,
  int height = 800,
  List<ExportWarning> warnings = const [],
}) => ResolvedSource(
  entryId: entryId,
  assetId: assetId,
  requestedVersionId: versionId,
  versionId: versionId,
  blobId: blobId,
  meta: ImageMeta(
    width: width,
    height: height,
    mime: 'image/jpeg',
    plaintextSha256: 'cd' * 32,
    byteSize: 1234,
  ),
  warnings: warnings,
);

final class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  void advance(Duration by) => _now = _now.add(by);

  @override
  DateTime now() => _now;
}

final class SequenceIds implements IdGenerator {
  int _n = 0;

  @override
  String newEntityId() => 'id-${++_n}';

  @override
  String newBlobId() => 'blob-${++_n}';
}
