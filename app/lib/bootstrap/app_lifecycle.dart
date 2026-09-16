/// Wires platform lifecycle into the `UnlockSession` (§5.5, §8.4):
/// background → auto-lock countdown, foreground → cancel, and on every
/// lock, drop cached plaintext previews so nothing outlives the keys.
library;

import 'dart:async';

import 'package:flutter/widgets.dart' hide LockState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import 'providers.dart';

final class AppLifecycle extends ConsumerStatefulWidget {
  const AppLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends ConsumerState<AppLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = ref.read(sessionProvider);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        session.appBackgrounded();
      case AppLifecycleState.resumed:
        session.appForegrounded();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<LockState>>(lockStateProvider, (previous, next) {
      if (next.value == LockState.locked &&
          previous?.value != LockState.locked) {
        // Every decrypted preview goes with the keys, and so does the
        // database handle: SQLCipher must not stay open past the key.
        ref
          ..invalidate(thumbnailBytesProvider)
          ..invalidate(entriesProvider)
          ..invalidate(entryProvider);
        ref.read(openVaultProvider.notifier).state = null;
        unawaited(ref.read(appBootProvider).closeVault());
      }
    });
    return widget.child;
  }
}
