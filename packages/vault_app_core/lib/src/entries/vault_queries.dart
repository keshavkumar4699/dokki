/// Read-side queries the presentation layer watches (§2: "calls use
/// cases, watches streams"). Thin by design; the repository already
/// returns view-ready projections.
library;

import 'package:vault_domain/vault_domain.dart';

final class VaultQueries {
  const VaultQueries({required this.entries});

  final EntryRepository entries;

  Stream<Result<List<VaultEntrySummary>, VaultFailure>> watchEntries({
    EntryType? type,
  }) => entries.watchEntries(type: type);

  Stream<Result<VaultEntry?, VaultFailure>> watchEntry(EntryId id) =>
      entries.watchEntry(id);

  Future<Result<VaultEntry, VaultFailure>> entry(EntryId id) =>
      entries.findEntry(id);

  Future<Result<Asset, VaultFailure>> asset(AssetId id) =>
      entries.findAsset(id);

  Future<Result<List<ExportRecordSummary>, VaultFailure>> exportHistory(
    EntryId id,
  ) => entries.listExportRecords(id);
}
