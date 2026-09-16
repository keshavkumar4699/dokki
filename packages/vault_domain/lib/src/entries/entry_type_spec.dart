/// Per-type shape rules, declared as data (§5.2).
///
/// The five specs live in `entry_type_specs.dart` (~40 lines). Adding
/// `BUSINESS_CARD` is a new enum value plus a new spec — no migration, no
/// domain rewrite.
library;

import '../assets/asset_role.dart';
import 'entry_type.dart';

/// `(min, max)` cardinality for a role. `max = -1` means unbounded.
typedef RoleCardinality = ({int min, int max});

final class EntryTypeSpec {
  const EntryTypeSpec({
    required this.type,
    required this.allowedRoles,
    required this.cardinality,
    this.ordinalIsMeaningful = false,
    this.supportsCoordinatedEdit = false,
  });

  final EntryType type;

  final Set<AssetRole> allowedRoles;

  /// Required cardinality per role. Every role in [allowedRoles] must have
  /// an entry here.
  final Map<AssetRole, RoleCardinality> cardinality;

  /// True only for `DOCUMENT`: page ordering matters.
  final bool ordinalIsMeaningful;

  /// True only for `ID`: front and back edit together in one transaction.
  final bool supportsCoordinatedEdit;

  RoleCardinality cardinalityFor(AssetRole role) {
    final c = cardinality[role];
    if (c == null) {
      throw ArgumentError('$role is not allowed on $type');
    }
    return c;
  }

  bool allowsRole(AssetRole role) => allowedRoles.contains(role);
}
