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

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _LockRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: Routes.vault,
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasVault = ref.read(hasVaultProvider);
      final unlocked = ref.read(isUnlockedProvider);
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
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingFlow(),
      ),
      GoRoute(path: Routes.unlock, builder: (_, _) => const UnlockScreen()),
      GoRoute(path: Routes.opening, builder: (_, _) => const OpeningScreen()),
      GoRoute(
        path: Routes.vault,
        builder: (_, _) => const VaultHomeScreen(),
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
