/// The role an asset plays inside its entry (Idea 1, §1.1).
library;

enum AssetRole {
  primary,
  idFront,
  idBack,
  page;

  /// Stable DB/serialisation value.
  String get dbValue => name == 'idFront'
      ? 'ID_FRONT'
      : name == 'idBack'
      ? 'ID_BACK'
      : name.toUpperCase();

  /// Parses a stored value; `null` for unknown (future) roles.
  static AssetRole? fromDbValue(String value) {
    for (final role in AssetRole.values) {
      if (role.dbValue == value) {
        return role;
      }
    }
    return null;
  }
}
