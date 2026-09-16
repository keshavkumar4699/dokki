/// Shown between "unlocked" and "vault open": derives K_db, opens the
/// SQLCipher database, builds the graph. Usually a few hundred ms; the
/// first open after a Phase-1 install also encrypts the legacy database.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/motion.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import 'unlock_screen.dart' show LockMark;

class OpeningScreen extends ConsumerStatefulWidget {
  const OpeningScreen({super.key});

  @override
  ConsumerState<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends ConsumerState<OpeningScreen> {
  VaultFailure? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    setState(() => _failure = null);
    final result = await ref.read(appBootProvider).openVault();
    if (!mounted) {
      return;
    }
    result.fold(
      (graph) => ref.read(openVaultProvider.notifier).state = graph,
      (failure) => setState(() => _failure = failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: failure == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LockMark(verifying: true, unlocked: true),
                  const SizedBox(height: DokkiSpace.lg),
                  FadeSlideIn.staggered(
                    2,
                    child: Text(
                      'Opening your vault…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : EmptyState(
              icon: Icons.lock_person_outlined,
              title: describeFailure(failure).title,
              message: describeFailure(failure).detail,
              action: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: _open,
                    child: const Text('Try again'),
                  ),
                  const SizedBox(height: DokkiSpace.sm),
                  TextButton(
                    onPressed: () => ref.read(sessionProvider).lock(),
                    child: const Text('Lock'),
                  ),
                ],
              ),
            ),
    );
  }
}
