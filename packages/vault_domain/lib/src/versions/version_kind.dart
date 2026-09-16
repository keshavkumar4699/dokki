/// Version provenance (§5.3).
library;

enum VersionKind {
  original,
  derived;

  String get dbValue => name.toUpperCase();

  static VersionKind? fromDbValue(String value) {
    for (final kind in VersionKind.values) {
      if (kind.dbValue == value) {
        return kind;
      }
    }
    return null;
  }
}
