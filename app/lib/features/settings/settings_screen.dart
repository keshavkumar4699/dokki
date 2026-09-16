/// Settings: security status (honest about the dev backend), auto-lock,
/// and about.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/app_graph.dart';
import '../../bootstrap/providers.dart';
import '../../core_ui/motion.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import 'rotate_keys_sheet.dart';
import 'sync_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(appBootProvider);
    final graph = ref.watch(appGraphProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDev = boot.cryptoBackend == CryptoBackend.softwareDev;
    final signals = ref.watch(securitySignalsProvider).value ?? const [];

    final rows = <Widget>[
      const SectionHeader('Security'),
      if (signals.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.lg),
          child: Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(DokkiSpace.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.gpp_maybe_outlined,
                    color: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: DokkiSpace.md),
                  Expanded(
                    child: Text(
                      'This device shows signs of being modified '
                      '(${signals.join(', ').toLowerCase()}). An unlocked '
                      'vault on a compromised device cannot be protected '
                      '(T4).',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.lg),
        child: Card(
          color: isDev ? scheme.errorContainer : scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(DokkiSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isDev
                      ? Icons.warning_amber_rounded
                      : Icons.verified_user_outlined,
                  color: isDev
                      ? scheme.onErrorContainer
                      : scheme.onTertiaryContainer,
                ),
                const SizedBox(width: DokkiSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDev
                            ? 'Development build: software keys'
                            : 'Hardware-backed keys',
                        style: text.titleSmall?.copyWith(
                          color: isDev
                              ? scheme.onErrorContainer
                              : scheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: DokkiSpace.xs),
                      Text(
                        isDev
                            ? 'Keys are derived from your PIN in software. '
                                  'Data is encrypted at rest, but a stolen '
                                  'database could be brute-forced offline. '
                                  'The Keystore-backed build removes this.'
                            : 'Your master key is bound to this device’s '
                                  'secure hardware and your PIN.',
                        style: text.bodySmall?.copyWith(
                          color: isDev
                              ? scheme.onErrorContainer
                              : scheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: DokkiSpace.sm),
      ListTile(
        leading: const Icon(Icons.timer_outlined),
        title: const Text('Auto-lock'),
        subtitle: Text(
          'Locks ${boot.session.autoLockAfter.inSeconds} s after leaving the app',
        ),
      ),
      ListTile(
        leading: const Icon(Icons.key_outlined),
        title: const Text('Recovery passphrase'),
        subtitle: const Text('Verify or change it'),
        trailing: const Icon(Icons.chevron_right),
        enabled: false,
        onTap: () {},
      ),
      ListTile(
        leading: const Icon(Icons.vpn_key_outlined),
        title: const Text('Rotate encryption keys'),
        subtitle: const Text('New master key; everything is re-wrapped'),
        onTap: () => showRotateKeysSheet(context),
      ),
      ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Lock now'),
        onTap: () => ref.read(sessionProvider).lock(),
      ),
      const SyncSection(),
      const SectionHeader('About'),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('dokki'),
        subtitle: Text('Device ${graph.context.deviceId.substring(0, 8)}'),
      ),
      const SizedBox(height: DokkiSpace.xxl),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          for (var i = 0; i < rows.length; i++)
            FadeSlideIn.staggered(i, child: rows[i]),
        ],
      ),
    );
  }
}
