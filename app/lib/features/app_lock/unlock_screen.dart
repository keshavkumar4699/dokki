/// The lock gate. Every route redirects here while the vault is locked.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_app_core/vault_app_core.dart';

import '../../bootstrap/app_graph.dart';
import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../core_ui/widgets/pin_pad.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  static const pinLength = 6;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _error = false;
  String? _message;

  Future<void> _submit(String pin) async {
    setState(() {
      _error = false;
      _message = null;
    });
    final result = await ref.read(sessionProvider).unlockWithPin(pin);
    if (!mounted) {
      return;
    }
    result.fold((_) {}, (failure) {
      setState(() {
        _error = true;
        _message = describeFailure(failure).detail;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);
    ref.watch(lockStateProvider);
    final reason = session.lastLockReason;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // Spacers need a bounded height; IntrinsicHeight gives the
              // column the viewport height while still allowing scroll on
              // very small screens.
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DokkiSpace.xl,
                    vertical: DokkiSpace.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(DokkiSpace.lg),
                          child: Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: DokkiSpace.xl),
                      Text('Enter your PIN', style: text.headlineSmall),
                      const SizedBox(height: DokkiSpace.sm),
                      AnimatedSwitcher(
                        duration: DokkiDuration.normal,
                        child: Text(
                          _message ?? _subtitleFor(reason),
                          key: ValueKey(_message ?? reason),
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: _error
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: DokkiSpace.xxl),
                      PinPad(
                        length: UnlockScreen.pinLength,
                        onCompleted: _submit,
                        error: _error,
                        trailingAction: const _BiometricButton(),
                      ),
                      const Spacer(),
                      const SecurityChip(
                        'Encrypted on this device',
                        icon: Icons.shield_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _subtitleFor(LockReason reason) => switch (reason) {
    LockReason.initial ||
    LockReason.user => 'Your documents stay sealed until you do.',
    LockReason.autoLock => 'Locked automatically while you were away.',
    LockReason.platform => 'Locked when the screen turned off.',
  };
}

/// Biometrics need an auth-bound Keystore key, which only the native
/// backend provides. Shown disabled so the affordance is discoverable.
class _BiometricButton extends ConsumerWidget {
  const _BiometricButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(appBootProvider).cryptoBackend;
    final enabled = backend != CryptoBackend.softwareDev;
    return IconButton(
      onPressed: enabled
          ? () async {
              final result = await ref
                  .read(sessionProvider)
                  .unlockWithBiometric();
              if (context.mounted && result.isErr) {
                showFailureSnack(context, result.errOrNull!);
              }
            }
          : null,
      tooltip: enabled
          ? 'Unlock with biometrics'
          : 'Biometrics need the hardware key backend',
      icon: const Icon(Icons.fingerprint),
    );
  }
}
