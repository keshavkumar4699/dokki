/// Metadata edits and soft deletion of entries.
library;

import 'package:vault_domain/vault_domain.dart';

import '../context/vault_context.dart';

final class UpdateEntryDetailsUseCase {
  const UpdateEntryDetailsUseCase({
    required this.context,
    required this.entries,
  });

  final VaultContext context;
  final EntryRepository entries;

  /// Any argument left `null` is left unchanged. An empty title clears it.
  Future<Result<VaultEntry, VaultFailure>> execute(
    EntryId id, {
    String? title,
    String? note,
    List<String>? tags,
  }) async {
    if (title == null && note == null && tags == null) {
      return entries.findEntry(id);
    }
    final updated = await entries.updateEntryDetails(
      id,
      EntryDetailsUpdate(
        hlc: context.nextHlc(),
        updatedAt: context.now(),
        title: title?.trim(),
        note: note?.trim(),
        tags: tags
            ?.map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList(growable: false),
      ),
    );
    return updated.asyncFlatMap((_) => entries.findEntry(id));
  }
}

final class DeleteEntryUseCase {
  const DeleteEntryUseCase({required this.context, required this.entries});

  final VaultContext context;
  final EntryRepository entries;

  /// Stage one of two-stage deletion (§6.5): tombstone + `deleted_at`.
  /// Blobs stay on disk until the purge job runs after the tombstone TTL.
  Future<Result<void, VaultFailure>> execute(EntryId id) {
    final now = context.now();
    return entries.deleteEntry(
      id,
      Tombstone.of(
        entityKind: TombstoneEntityKind.entry,
        entityId: id,
        deletedHlc: context.nextHlc(),
        originDevice: context.deviceId,
        deletedAt: now,
      ),
      now: now,
    );
  }
}
