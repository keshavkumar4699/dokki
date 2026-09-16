/// Riverpod providers over the wired graph. Features read use cases and
/// ports from here; they never see a concrete infrastructure type.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import 'app_boot.dart';
import 'app_graph.dart';

/// Overridden in `main()` with the pre-unlock boot.
final appBootProvider = Provider<AppBoot>(
  (_) => throw UnimplementedError('appBootProvider must be overridden'),
);

final sessionProvider = Provider<UnlockSession>(
  (ref) => ref.watch(appBootProvider).session,
);

/// The opened vault, set by the opening screen after unlock and cleared by
/// `AppLifecycle` on lock. `null` = locked or still opening.
final openVaultProvider = StateProvider<AppGraph?>((_) => null);

/// The post-unlock graph. Only routes behind the lock gate may read it;
/// the router guarantees it is set before any of them build.
final appGraphProvider = Provider<AppGraph>(
  (ref) =>
      ref.watch(openVaultProvider) ??
      (throw StateError('vault graph read while locked')),
);

/// The lock state as a stream, seeded with the current value so the router
/// redirect and the UI never see a stale "loading" state.
final lockStateProvider = StreamProvider<LockState>((ref) async* {
  final session = ref.watch(sessionProvider);
  yield session.state;
  yield* session.states;
});

/// Reactive views of the session flags for widgets that `watch`. The
/// router's redirect reads the session directly instead (see there).
final isUnlockedProvider = Provider<bool>((ref) {
  ref.watch(lockStateProvider);
  return ref.watch(sessionProvider).isUnlocked;
});

final hasVaultProvider = Provider<bool>((ref) {
  ref.watch(lockStateProvider);
  return ref.watch(sessionProvider).hasVault;
});

final queriesProvider = Provider<VaultQueries>(
  (ref) => ref.watch(appGraphProvider).queries,
);

// ── Read models ────────────────────────────────────────────────────────────

/// The vault grid: live, filtered by type.
final entriesProvider =
    StreamProvider.family<List<VaultEntrySummary>, EntryType?>((ref, type) {
      final queries = ref.watch(queriesProvider);
      return queries
          .watchEntries(type: type)
          .map(
            (result) => result.fold(
              (entries) => entries,
              (failure) => throw VaultFailureException(failure),
            ),
          );
    });

/// One entry, live. Emits `null` once it is deleted.
final entryProvider = StreamProvider.family<VaultEntry?, EntryId>((ref, id) {
  final queries = ref.watch(queriesProvider);
  return queries
      .watchEntry(id)
      .map(
        (result) => result.fold(
          (entry) => entry,
          (failure) => throw VaultFailureException(failure),
        ),
      );
});

/// An entry's export history, newest first. Refreshed by the export
/// sheet after each run (`ref.invalidate`), disposed with the screen.
final exportHistoryProvider = FutureProvider.autoDispose
    .family<List<ExportRecordSummary>, EntryId>((ref, entryId) async {
      final result = await ref.watch(appGraphProvider).exports.history(entryId);
      return result.fold(
        (records) => records,
        (failure) => throw VaultFailureException(failure),
      );
    });

// ── Thumbnails ─────────────────────────────────────────────────────────────

typedef ThumbnailKey = ({VersionId versionId, ThumbnailSizeClass size});

/// Decrypted preview bytes for one version at one size.
///
/// This is the one bounded plaintext the Dart heap holds (§8.4): previews
/// are ≤1024 px JPEGs. `keepAlive` caches them for the session; every
/// cached provider is invalidated on lock (see `AppLifecycle`) so nothing
/// outlives the key material.
final thumbnailBytesProvider = FutureProvider.family<Uint8List, ThumbnailKey>((
  ref,
  key,
) async {
  ref.keepAlive();
  final graph = ref.watch(appGraphProvider);
  final state = await graph.thumbnails
      .request(key.versionId, key.size)
      .firstWhere((s) => s is! ThumbnailLoading);
  switch (state) {
    case ThumbnailReady(:final blobId):
      final bytes = await graph.blobStore.readSmall(
        blobId,
        maxBytes: 4 * 1024 * 1024,
      );
      return bytes.fold(
        Uint8List.fromList,
        (failure) => throw VaultFailureException(failure),
      );
    case ThumbnailFailed(:final failure):
      throw VaultFailureException(failure);
    case ThumbnailLoading():
      throw StateError('unreachable');
  }
});

/// Carries a domain failure through Riverpod's `AsyncError` so the UI can
/// switch on it exhaustively instead of parsing a message.
final class VaultFailureException implements Exception {
  const VaultFailureException(this.failure);

  final VaultFailure failure;

  @override
  String toString() => 'VaultFailureException(${failure.code})';
}
