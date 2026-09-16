import 'package:test/test.dart';
import 'package:vault_domain/src/assets/asset_role.dart';
import 'package:vault_domain/src/entries/entry_type.dart';
import 'package:vault_domain/src/entries/entry_type_specs.dart';

void main() {
  test('all five types have a spec', () {
    for (final type in EntryType.values) {
      expect(specFor(type).type, type);
    }
  });

  test('photo/signature/thumbprint: one primary asset only', () {
    for (final type in [
      EntryType.photo,
      EntryType.signature,
      EntryType.thumbprint,
    ]) {
      final spec = specFor(type);
      expect(spec.allowedRoles, {AssetRole.primary});
      expect(spec.cardinalityFor(AssetRole.primary), (min: 1, max: 1));
      expect(spec.ordinalIsMeaningful, isFalse);
      expect(spec.supportsCoordinatedEdit, isFalse);
    }
  });

  test('id: front required, back optional, coordinated', () {
    final spec = specFor(EntryType.id);
    expect(spec.allowedRoles, {AssetRole.idFront, AssetRole.idBack});
    expect(spec.cardinalityFor(AssetRole.idFront), (min: 1, max: 1));
    expect(spec.cardinalityFor(AssetRole.idBack), (min: 0, max: 1));
    expect(spec.supportsCoordinatedEdit, isTrue);
    expect(spec.ordinalIsMeaningful, isFalse);
  });

  test('document: unbounded pages, ordinal meaningful', () {
    final spec = specFor(EntryType.document);
    expect(spec.allowedRoles, {AssetRole.page});
    expect(spec.cardinalityFor(AssetRole.page), (min: 1, max: -1));
    expect(spec.ordinalIsMeaningful, isTrue);
  });

  test('cardinalityFor rejects unallowed roles', () {
    expect(
      () => specFor(EntryType.photo).cardinalityFor(AssetRole.idFront),
      throwsArgumentError,
    );
  });

  test('EntryType round-trips through DB values', () {
    for (final type in EntryType.values) {
      expect(EntryType.fromDbValue(type.dbValue), type);
    }
    expect(EntryType.fromDbValue('BUSINESS_CARD'), isNull);
  });

  test('AssetRole round-trips through DB values', () {
    expect(AssetRole.fromDbValue('ID_FRONT'), AssetRole.idFront);
    expect(AssetRole.fromDbValue('ID_BACK'), AssetRole.idBack);
    expect(AssetRole.fromDbValue('PRIMARY'), AssetRole.primary);
    expect(AssetRole.fromDbValue('PAGE'), AssetRole.page);
    expect(AssetRole.fromDbValue('STICKER'), isNull);
  });
}
