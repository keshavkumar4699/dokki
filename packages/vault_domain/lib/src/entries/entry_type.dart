/// The five entry types.
///
/// Adding a type later is: one enum value + one `EntryTypeSpec` (§5.2).
library;

enum EntryType {
  photo,
  id,
  signature,
  thumbprint,
  document;

  /// Stable DB/serialisation value. Never renumber these; they are TEXT in
  /// the schema for exactly that reason (§6.6).
  String get dbValue => name.toUpperCase();

  /// Parses a stored value. Returns `null` for unknown values so that a
  /// newer peer's type is preserved verbatim, never coerced (§6.6).
  static EntryType? fromDbValue(String value) {
    final lowered = value.toLowerCase();
    for (final type in EntryType.values) {
      if (type.name == lowered) {
        return type;
      }
    }
    return null;
  }
}
