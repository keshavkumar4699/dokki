/// Export use cases (§11): quick export in one call, configured export,
/// "Export Again" from history, and the artifact GC. Plus the built-in
/// presets — a registry of request builders, never new domain (§11.6).
library;

import 'package:vault_domain/vault_domain.dart';

import '../context/vault_context.dart';
import '../error_boundary.dart';

// ── Presets ─────────────────────────────────────────────────────────────

/// Full quality: JPEG at 92 for photographs, PNG for a signature (crisp
/// edges, transparency kept).
final class FullQualityPreset implements ExportPreset {
  const FullQualityPreset();

  @override
  String get id => 'full';

  @override
  String get displayName => 'Full quality';

  @override
  bool appliesTo(EntryType type) => true;

  @override
  ExportRequest build(ExportContext context) => ExportRequest(
    source: context.source,
    format: context.entryType == EntryType.signature
        ? OutputFormat.png
        : OutputFormat.jpeg,
    quality: const QualitySpec(quality: 92),
  );
}

/// "Email-friendly": aims at ~200 KB, shrinking if the quality floor
/// alone cannot get there; the result says how close it got.
final class EmailFriendlyPreset implements ExportPreset {
  const EmailFriendlyPreset();

  static const targetBytes = 200 * 1024;

  @override
  String get id => 'email';

  @override
  String get displayName => 'Email-friendly (≈200 KB)';

  @override
  bool appliesTo(EntryType type) => true;

  @override
  ExportRequest build(ExportContext context) => ExportRequest(
    source: context.source,
    format: OutputFormat.jpeg,
    quality: const QualitySpec(targetBytes: targetBytes),
  );
}

/// Lossless PNG, pixels untouched.
final class LosslessPngPreset implements ExportPreset {
  const LosslessPngPreset();

  @override
  String get id => 'png';

  @override
  String get displayName => 'Lossless PNG';

  @override
  bool appliesTo(EntryType type) => true;

  @override
  ExportRequest build(ExportContext context) => ExportRequest(
    source: context.source,
    format: OutputFormat.png,
    quality: const QualitySpec(),
  );
}

/// The presets every build ships with.
ExportPresetRegistry builtInExportPresets() => ExportPresetRegistry(const [
  FullQualityPreset(),
  EmailFriendlyPreset(),
  LosslessPngPreset(),
]);

// ── Use cases ───────────────────────────────────────────────────────────

final class ExportUseCases {
  const ExportUseCases({
    required this.context,
    required this.engine,
    required this.entries,
    required this.blobStore,
    required this.presets,
  });

  final VaultContext context;
  final ExportEngine engine;
  final EntryRepository entries;
  final BlobStore blobStore;
  final ExportPresetRegistry presets;

  /// Quick export (§11.1): the entry's current versions — or just
  /// [onlyVersion] — through [presetId]. ≤2 taps, no editor.
  Future<Result<ExportResult, VaultFailure>> quick(
    EntryId entryId, {
    required String presetId,
    VersionId? onlyVersion,
    bool retainArtifact = false,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    final preset = presets.byId(presetId);
    if (preset == null) {
      return Err(InvalidAsset('unknown export preset $presetId'));
    }
    return entries.findEntry(entryId).asyncFlatMap((entry) {
      if (!preset.appliesTo(entry.type)) {
        return Future.value(
          Err<ExportResult, VaultFailure>(
            InvalidAsset('preset $presetId does not apply to ${entry.type}'),
          ),
        );
      }
      final request = preset.build(
        ExportContext(
          entryType: entry.type,
          currentVersionIds: {
            for (final asset in entry.liveAssets)
              asset.role.dbValue: asset.currentVersionId,
          },
          source: onlyVersion == null
              ? CurrentOfEntrySource(entryId)
              : SingleVersionSource(onlyVersion),
        ),
      );
      return engine.run(
        request,
        progress: progress,
        cancel: cancel,
        retainArtifact: retainArtifact,
      );
    });
  });

  /// A caller-built request (the configured editor, or a preset with
  /// overrides).
  Future<Result<ExportResult, VaultFailure>> configured(
    ExportRequest request, {
    bool retainArtifact = false,
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => engine.run(
    request,
    progress: progress,
    cancel: cancel,
    retainArtifact: retainArtifact,
  );

  /// "Export Again" (§11.7): replays a record against the exact versions
  /// it recorded, so a materialized source reproduces the same file. The
  /// resolver applies the fallbacks and reports them as warnings.
  Future<Result<ExportResult, VaultFailure>> again(
    ExportId exportId, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    final found = await entries.findExportRecord(exportId);
    return found.asyncFlatMap((record) {
      if (record == null) {
        return Future.value(
          Err<ExportResult, VaultFailure>(
            InvalidAsset('no export record $exportId'),
          ),
        );
      }
      final original = record.request;
      return engine.run(
        ExportRequest(
          source: replaySource(record),
          format: original.format,
          quality: original.quality,
          raster: original.raster,
          page: original.page,
          color: original.color,
          extensions: original.extensions,
          requestSchemaVersion: original.requestSchemaVersion,
        ),
        progress: progress,
        cancel: cancel,
        retainArtifact: record.retainArtifact,
      );
    });
  });

  /// The exact versions a record exported, as a source the resolver can
  /// take through the §11.7 ladder. `CurrentOfEntrySource` is never
  /// replayed as such: "again" means *those* pixels, not today's.
  static ExportSource replaySource(ExportRecord record) {
    final versions =
        ([...record.sources]..sort((a, b) => a.ordinal.compareTo(b.ordinal)))
            .map((s) => s.versionId)
            .toList(growable: false);
    if (versions.isEmpty) {
      return record.request.source;
    }
    return switch (record.request.source) {
      IdPairSource() when versions.length <= 2 => IdPairSource(
        front: versions.first,
        back: versions.length == 2 ? versions[1] : null,
      ),
      DocumentPagesSource() => DocumentPagesSource(versions),
      _ when versions.length == 1 => SingleVersionSource(versions.single),
      _ => DocumentPagesSource(versions),
    };
  }

  Future<Result<List<ExportRecordSummary>, VaultFailure>> history(
    EntryId entryId,
  ) => entries.listExportRecords(entryId);

  Future<Result<ExportRecord?, VaultFailure>> record(ExportId exportId) =>
      entries.findExportRecord(exportId);

  /// Artifact GC (§11.7): drops artifacts that were never retained or whose
  /// retention expired, then purges their files. Returns how many.
  Future<Result<int, VaultFailure>> releaseArtifacts() =>
      entries.releaseExportArtifacts(now: context.now()).asyncMap((ids) async {
        for (final id in ids) {
          await blobStore.purge(id);
        }
        return ids.length;
      });
}
