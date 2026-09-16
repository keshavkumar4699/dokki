/// The five built-in type specs (§5.2). All shape rules live here.
library;

import '../assets/asset_role.dart';
import 'entry_type.dart';
import 'entry_type_spec.dart';

/// photo: one `PRIMARY` asset.
const photoSpec = EntryTypeSpec(
  type: EntryType.photo,
  allowedRoles: {AssetRole.primary},
  cardinality: {AssetRole.primary: (min: 1, max: 1)},
);

/// id: `ID_FRONT` required, `ID_BACK` optional, coordinated editing.
const idSpec = EntryTypeSpec(
  type: EntryType.id,
  allowedRoles: {AssetRole.idFront, AssetRole.idBack},
  cardinality: {
    AssetRole.idFront: (min: 1, max: 1),
    AssetRole.idBack: (min: 0, max: 1),
  },
  supportsCoordinatedEdit: true,
);

/// signature: one `PRIMARY` asset.
const signatureSpec = EntryTypeSpec(
  type: EntryType.signature,
  allowedRoles: {AssetRole.primary},
  cardinality: {AssetRole.primary: (min: 1, max: 1)},
);

/// thumbprint: one `PRIMARY` asset.
const thumbprintSpec = EntryTypeSpec(
  type: EntryType.thumbprint,
  allowedRoles: {AssetRole.primary},
  cardinality: {AssetRole.primary: (min: 1, max: 1)},
);

/// document: one or more `PAGE` assets, order meaningful.
const documentSpec = EntryTypeSpec(
  type: EntryType.document,
  allowedRoles: {AssetRole.page},
  cardinality: {AssetRole.page: (min: 1, max: -1)},
  ordinalIsMeaningful: true,
);

const Map<EntryType, EntryTypeSpec> _specs = {
  EntryType.photo: photoSpec,
  EntryType.id: idSpec,
  EntryType.signature: signatureSpec,
  EntryType.thumbprint: thumbprintSpec,
  EntryType.document: documentSpec,
};

/// The spec for [type]. Exhaustive by construction of [_specs].
EntryTypeSpec specFor(EntryType type) {
  final spec = _specs[type];
  if (spec == null) {
    throw ArgumentError('No spec registered for $type');
  }
  return spec;
}
