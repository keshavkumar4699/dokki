/// The Sync section of Settings: connect/disconnect Google Drive, honest
/// status (pending, conflicts, last cycle), and a manual "Sync now".
/// The copy never claims more than the design delivers: ciphertext only,
/// freshness limits included (§8.7 T5/T13).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';

class SyncSection extends ConsumerWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(syncAuthStateProvider);
    final status = ref.watch(syncStatusProvider);
    final scheme = Theme.of(context).colorScheme;

    final signedIn = auth.value == CloudAuthState.signedIn;
    final syncing = status.value?.running ?? false;
    final pending = status.value?.pendingOps ?? 0;
    final conflicts = status.value?.openConflicts ?? 0;
    final lastCycle = status.value?.lastCycleAt;
    final lastError = status.value?.lastError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Sync'),
        if (!signedIn)
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Connect Google Drive'),
            subtitle: const Text(
              'Encrypted sync to your own Drive. Everything leaves this '
              'device already sealed — Google sees ciphertext, never content.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connect(context, ref),
          )
        else ...[
          ListTile(
            leading: Icon(Icons.cloud_done_outlined, color: scheme.primary),
            title: const Text('Google Drive connected'),
            subtitle: Text(
              switch ((syncing, pending, conflicts)) {
                (true, _, _) => 'Syncing…',
                (_, final p, final c) when p > 0 && c > 0 =>
                  '$pending pending · $c conflicts',
                (_, final p, _) when p > 0 => '$pending pending',
                (_, _, final c) when c > 0 => '$c conflicts to review',
                _ => lastCycle == null
                    ? 'Waiting for the first sync'
                    : 'Up to date · last synced ${_relative(lastCycle, ref.read(appGraphProvider).context.now())}',
              },
            ),
          ),
          if (lastError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.lg),
              child: Text(
                describeFailure(lastError).detail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync now'),
            enabled: !syncing,
            onTap: () => ref.read(appGraphProvider).sync.syncNow(),
          ),
          ListTile(
            leading: Icon(Icons.cloud_off_outlined, color: scheme.error),
            title: Text(
              'Disconnect',
              style: TextStyle(color: scheme.error),
            ),
            subtitle: const Text(
              'The sealed data in Drive stays; this device stops syncing.',
            ),
            onTap: () => _disconnect(context, ref),
          ),
        ],
      ],
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final graph = ref.read(appGraphProvider);
    final result = await graph.syncLink.connect(
      deviceId: graph.context.deviceId,
    );
    ref.invalidate(syncAuthStateProvider);
    if (!context.mounted) {
      return;
    }
    result.fold((_) {
      // The first cycle carries the vault's history up.
      graph.sync.syncNow();
    }, (failure) => showFailureSnack(context, failure));
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    await ref.read(appGraphProvider).syncLink.disconnect();
    ref.invalidate(syncAuthStateProvider);
  }

  String _relative(DateTime at, DateTime now) {
    final age = now.difference(at);
    if (age.inMinutes < 1) {
      return 'just now';
    }
    if (age.inHours < 1) {
      return '${age.inMinutes} min ago';
    }
    if (age.inDays < 1) {
      return '${age.inHours} h ago';
    }
    return '${age.inDays} d ago';
  }
}
