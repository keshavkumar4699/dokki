/// Domain-side invariant checks (§5.4).
///
/// These mirror the database constraints; the DB is the backstop, these are
/// the friendly, testable, domain-level checks run on every mutation.
library;

import '../assets/asset.dart';
import '../assets/asset_role.dart';
import '../failures/vault_failure.dart';
import '../ids.dart';
import '../result.dart';
import '../versions/asset_version.dart';
import '../versions/version_kind.dart';
import 'entry_type_specs.dart';
import 'vault_entry.dart';

final class EntryInvariants {
  const EntryInvariants._();

  /// Validates [entry] against its `EntryTypeSpec`.
  ///
  /// Returns `Err(EntryInvariantViolated)` naming the broken invariant.
  static Result<VaultEntry, VaultFailure> check(VaultEntry entry) {
    final spec = specFor(entry.type);
    final live = entry.liveAssets.toList(growable: false);

    // Role validity.
    for (final asset in live) {
      if (!spec.allowsRole(asset.role)) {
        return err(
          EntryInvariantViolated(
            'role ${asset.role.dbValue} not allowed on ${entry.type.dbValue}',
          ),
        );
      }
      // I1: exactly one ORIGINAL version per asset, forever.
      final originals = asset.versions
          .where((AssetVersion v) => v.isOriginal)
          .length;
      if (originals != 1) {
        return err(
          EntryInvariantViolated(
            'asset ${asset.id} has $originals ORIGINAL versions (I1)',
          ),
        );
      }
      // I2 + I4: per-version structural checks.
      for (final version in asset.versions) {
        if (version.kind == VersionKind.derived &&
            version.parentVersionId == null) {
          return err(
            EntryInvariantViolated(
              'version ${version.id} is DERIVED without parent (I4)',
            ),
          );
        }
        if (version.isOriginal &&
            (version.blobId == null || version.evictedAt != null)) {
          return err(
            EntryInvariantViolated(
              'version ${version.id} ORIGINAL evicted or missing blob (I2)',
            ),
          );
        }
      }
      // I3: current version is a materialized version of the same asset.
      final current = asset.currentVersion;
      if (current == null || !current.isMaterialized) {
        return err(
          EntryInvariantViolated(
            'asset ${asset.id} current version missing or evicted (I3)',
          ),
        );
      }
    }

    // Cardinality per role among live assets.
    final counts = <AssetRole, int>{};
    for (final asset in live) {
      counts[asset.role] = (counts[asset.role] ?? 0) + 1;
    }
    for (final rule in spec.cardinality.entries) {
      final count = counts[rule.key] ?? 0;
      final min = rule.value.min;
      final max = rule.value.max;
      if (count < min || (max >= 0 && count > max)) {
        return err(
          EntryInvariantViolated(
            '${entry.type.dbValue} role ${rule.key.dbValue} count $count '
            'outside [$min, ${max < 0 ? '∞' : '$max'}]',
          ),
        );
      }
    }

    // I6: unique (role, ordinal) among live assets.
    final slots = <(AssetRole, int)>{};
    for (final asset in live) {
      if (!slots.add((asset.role, asset.ordinal))) {
        return err(
          EntryInvariantViolated(
            'duplicate slot ${asset.role.dbValue}#${asset.ordinal} (I6)',
          ),
        );
      }
    }

    // I7: contiguous page ordinals.
    if (spec.ordinalIsMeaningful) {
      final pages = live
          .where((Asset a) => a.role == AssetRole.page)
          .toList(growable: false);
      if (!pages.hasContiguousOrdinals) {
        return err(
          const EntryInvariantViolated('page ordinals not contiguous (I7)'),
        );
      }
    }

    return ok(entry);
  }

  /// Validates an asset's version list in isolation (used at commit time).
  static Result<List<AssetVersion>, VaultFailure> checkVersions(
    List<AssetVersion> versions,
  ) {
    var originals = 0;
    for (final version in versions) {
      if (version.isOriginal) {
        originals++;
        if (version.blobId == null) {
          return err(
            EntryInvariantViolated('ORIGINAL ${version.id} has no blob (I2)'),
          );
        }
      } else if (version.parentVersionId == null) {
        return err(
          EntryInvariantViolated('DERIVED ${version.id} has no parent (I4)'),
        );
      }
    }
    if (originals != 1) {
      return err(
        EntryInvariantViolated('expected 1 ORIGINAL, got $originals (I1)'),
      );
    }
    return ok(versions);
  }

  /// The eviction boundary: originals and current pointers are never
  /// eligible (I2, I3), enforced here AND by `BlobStore.evict`.
  static bool canEvict(Asset asset, VersionId versionId) {
    if (versionId == asset.currentVersionId) {
      return false;
    }
    for (final version in asset.versions) {
      if (version.id == versionId && version.isOriginal) {
        return false;
      }
    }
    return true;
  }
}
