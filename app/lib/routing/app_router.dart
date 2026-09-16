/// GoRouter configuration with the lock gate (§15.2): one `redirect` is
/// the single choke point — no vault exists → onboarding; locked → unlock;
/// unlocked on a gate route → vault.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../bootstrap/providers.dart';
import '../features/app_lock/opening_screen.dart';
import '../features/app_lock/unlock_screen.dart';
import '../features/entry_detail/entry_detail_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/settings/settings_screen.dart';
import '../features/vault_list/vault_home_screen.dart';
import 'routes.dart';
import 'transitions.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _LockRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: Routes.vault,
    refreshListenable: refresh,
    redirect: (context, state) {
      // Read the session directly, not through a derived provider: this
      // runs synchronously inside listener callbacks (the lock listener
      // clears `openVaultProvider`, which refreshes the router), and
      // Riverpod notifies `ref.listen` callbacks *before* it invalidates
      // providers that `watch` the same source. A derived provider would
      // still answer "unlocked" here for one turn.
      final session = ref.read(sessionProvider);
      final hasVault = session.hasVault;
      final unlocked = session.isUnlocked;
      final opened = ref.read(openVaultProvider) != null;
      final at = state.matchedLocation;
      if (!hasVault) {
        return at == Routes.onboarding ? null : Routes.onboarding;
      }
      if (!unlocked) {
        return at == Routes.unlock ? null : Routes.unlock;
      }
      if (!opened) {
        return at == Routes.opening ? null : Routes.opening;
      }
      if (at == Routes.unlock ||
          at == Routes.onboarding ||
          at == Routes.opening) {
        return Routes.vault;
      }
      return null;
    },
    routes: [
      // The gate screens and the vault root fade through each other: they
      // are states, not places, so there is no direction to slide in.
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (_, state) =>
            FadeThroughPage(key: state.pageKey, child: const OnboardingFlow()),
      ),
      GoRoute(
        path: Routes.unlock,
        pageBuilder: (_, state) =>
            FadeThroughPage(key: state.pageKey, child: const UnlockScreen()),
      ),
      GoRoute(
        path: Routes.opening,
        pageBuilder: (_, state) =>
            FadeThroughPage(key: state.pageKey, child: const OpeningScreen()),
      ),
      GoRoute(
        path: Routes.vault,
        pageBuilder: (_, state) =>
            FadeThroughPage(key: state.pageKey, child: const VaultHomeScreen()),
        routes: [
          GoRoute(
            path: 'entry/:id',
            builder: (_, state) =>
                EntryDetailScreen(entryId: state.pathParameters['id']!),
          ),
          GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

/// Bridges the lock-state stream into a `Listenable` for GoRouter.
final class _LockRefresh extends ChangeNotifier {
  _LockRefresh(Ref ref) {
    _subs = [
      ref.listen<AsyncValue<Object?>>(
        lockStateProvider,
        (_, _) => notifyListeners(),
      ),
      ref.listen<Object?>(openVaultProvider, (_, _) => notifyListeners()),
    ];
  }

  late final List<ProviderSubscription<Object?>> _subs;

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    super.dispose();
  }
}
