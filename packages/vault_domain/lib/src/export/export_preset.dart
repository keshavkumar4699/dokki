/// Export presets (§11.6): named recipe builders over the core model.
///
/// "Aadhaar front+back A4", "Passport photo 35×45 mm @ 300 DPI",
/// "Email-friendly 200 KB JPEG", "Print-quality PDF" are all `ExportPreset`
/// implementations that emit an ordinary `ExportRequest`. The core domain
/// never changes.
library;

import '../entries/entry_type.dart';
import 'export_request.dart';

/// Context a preset may read while building its request.
final class ExportContext {
  const ExportContext({
    required this.entryType,
    required this.currentVersionIds,
  });

  final EntryType entryType;

  /// Current versions, keyed by role DB value (`PRIMARY`, `ID_FRONT`, …).
  final Map<String, String> currentVersionIds;

  String? currentFor(String roleDbValue) => currentVersionIds[roleDbValue];
}

abstract interface class ExportPreset {
  String get id;

  String get displayName;

  bool appliesTo(EntryType type);

  ExportRequest build(ExportContext context);
}

/// A preset registry: lookup by id.
final class ExportPresetRegistry {
  ExportPresetRegistry(this.presets);

  final List<ExportPreset> presets;

  ExportPreset? byId(String id) {
    for (final preset in presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  List<ExportPreset> forType(EntryType type) => presets
      .where((ExportPreset preset) => preset.appliesTo(type))
      .toList(growable: false);
}
