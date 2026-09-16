/// DAO for `export_records` and `export_record_sources`.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'exports_dao.g.dart';

/// Lightweight projection for the export-history list (§6.7).
final class ExportSummaryRow {
  const ExportSummaryRow({
    required this.id,
    required this.format,
    required this.status,
    required this.createdAt,
    required this.actualBytes,
    required this.pageCount,
    required this.artifactBlobId,
  });

  final String id;
  final String format;
  final String status;
  final DateTime createdAt;
  final int? actualBytes;
  final int? pageCount;
  final String? artifactBlobId;
}

@DriftAccessor(tables: [ExportRecords, ExportRecordSources])
class ExportsDao extends DatabaseAccessor<AppDatabase> with _$ExportsDaoMixin {
  ExportsDao(super.db);

  Future<void> insertExportRow(ExportRecordsCompanion companion) =>
      into(exportRecords).insert(companion);

  Future<void> insertExportSourceRow(ExportRecordSourcesCompanion companion) =>
      into(exportRecordSources).insert(companion);

  Future<ExportRecordData?> exportRowById(String id) =>
      (select(exportRecords)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ExportRecordSourceData>> sourcesForExport(String exportId) {
    final query = select(exportRecordSources)
      ..where((t) => t.exportId.equals(exportId))
      ..orderBy([(t) => OrderingTerm.asc(t.ordinal)]);
    return query.get();
  }

  Future<List<ExportSummaryRow>> exportSummariesFor(String entryId) {
    final query = select(exportRecords)
      ..where((t) => t.entryId.equals(entryId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query
        .map(
          (row) => ExportSummaryRow(
            id: row.id,
            format: row.format,
            status: row.status,
            createdAt: row.createdAt,
            actualBytes: row.actualBytes,
            pageCount: row.pageCount,
            artifactBlobId: row.artifactBlobId,
          ),
        )
        .get();
  }
}
