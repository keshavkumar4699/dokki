/// `CreateEntry`: one sealed image becomes a new entry of any type.
library;

import 'package:vault_domain/vault_domain.dart';

import '../assets/asset_importer.dart';
import '../assets/import_source.dart';
import '../context/vault_context.dart';
import '../error_boundary.dart';

final class CreateEntryCommand {
  const CreateEntryCommand({
    required this.type,
    required this.source,
    this.title,
    this.note,
    this.tags = const [],
    this.role,
  });

  final EntryType type;
  final ImportSource source;
  final String? title;
  final String? note;
  final List<String> tags;

  /// The role of the first asset. Defaults to the type's natural first
  /// role (`PRIMARY`, `ID_FRONT`, or `PAGE`).
  final AssetRole? role;
}

final class CreateEntryUseCase {
  const CreateEntryUseCase({
    required this.context,
    required this.entries,
    required this.importer,
  });

  final VaultContext context;
  final EntryRepository entries;
  final AssetImporter importer;

  Future<Result<VaultEntry, VaultFailure>> execute(
    CreateEntryCommand command, {
    ProgressSink? progress,
    CancellationToken? cancel,
  }) => guardUseCase(() async {
    final spec = specFor(command.type);
    final role = command.role ?? firstRoleFor(command.type);
    if (!spec.allowsRole(role)) {
      return Err(
        EntryInvariantViolated(
          'role ${role.dbValue} not allowed on ${command.type.dbValue}',
        ),
      );
    }
    final sealed = await importer.seal(
      command.source,
      progress: progress,
      cancel: cancel,
    );
    return sealed.asyncFlatMap((imported) async {
      final entryId = context.ids.newEntityId();
      final entry = NewEntry(
        id: entryId,
        type: command.type,
        title: _cleanTitle(command.title ?? command.source.displayName),
        note: _clean(command.note),
        tags: command.tags
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(growable: false),
        hlc: context.nextHlc(),
        originDevice: context.deviceId,
        createdAt: context.now(),
        asset: importer.describe(
          imported,
          entryId: entryId,
          role: role,
          ordinal: 0,
        ),
      );
      final created = await entries.createEntry(entry);
      return switch (created) {
        Ok() => created,
        Err(:final error) => await importer.discard(imported.blob, error),
      };
    });
  });

  static String? _cleanTitle(String? raw) => _clean(raw);

  static String? _clean(String? raw) {
    final trimmed = raw?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// The role a type's first asset naturally takes.
AssetRole firstRoleFor(EntryType type) => switch (type) {
  EntryType.id => AssetRole.idFront,
  EntryType.document => AssetRole.page,
  EntryType.photo ||
  EntryType.signature ||
  EntryType.thumbprint => AssetRole.primary,
};
