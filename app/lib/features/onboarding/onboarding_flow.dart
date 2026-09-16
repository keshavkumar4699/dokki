/// First launch: welcome → choose PIN → confirm PIN → recovery passphrase
/// → done. The passphrase step is blocking (A3, R1): a vault cannot exist
/// without it, and the user must confirm they have written it down.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../core_ui/widgets/pin_pad.dart';
import 'passphrase_words.dart';

enum _Step { welcome, pin, confirmPin, passphrase, creating }

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  static const pinLength = 6;

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  _Step _step = _Step.welcome;
  String? _pin;
  bool _pinMismatch = false;
  late final List<String> _words = generatePassphrase(
    ref.read(appBootProvider).random,
  );
  bool _writtenDown = false;
  String? _createError;

  Future<void> _onPin(String pin) async {
    setState(() {
      _pin = pin;
      _pinMismatch = false;
      _step = _Step.confirmPin;
    });
  }

  Future<void> _onConfirmPin(String pin) async {
    if (pin != _pin) {
      setState(() => _pinMismatch = true);
      return;
    }
    setState(() => _step = _Step.passphrase);
  }

  Future<void> _create() async {
    setState(() {
      _step = _Step.creating;
      _createError = null;
    });
    final result = await ref
        .read(sessionProvider)
        .createVault(pin: _pin!, recoveryPassphrase: _words.join(' '));
    if (!mounted) {
      return;
    }
    result.fold((_) {}, (failure) {
      setState(() {
        _step = _Step.passphrase;
        _createError = describeFailure(failure).detail;
      });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AnimatedSwitcher(
        duration: DokkiDuration.normal,
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_step), child: _body()),
      ),
    ),
  );

  Widget _body() => switch (_step) {
    _Step.welcome => _Welcome(onStart: () => setState(() => _step = _Step.pin)),
    _Step.pin => _PinStep(
      title: 'Choose a PIN',
      subtitle: 'Six digits. You’ll enter it every time you open dokki.',
      onCompleted: _onPin,
      onBack: () => setState(() => _step = _Step.welcome),
    ),
    _Step.confirmPin => _PinStep(
      title: 'Confirm your PIN',
      subtitle: _pinMismatch
          ? 'That didn’t match. Try again.'
          : 'Enter the same six digits once more.',
      error: _pinMismatch,
      onCompleted: _onConfirmPin,
      onBack: () => setState(() {
        _pinMismatch = false;
        _step = _Step.pin;
      }),
    ),
    _Step.passphrase || _Step.creating => _PassphraseStep(
      words: _words,
      writtenDown: _writtenDown,
      busy: _step == _Step.creating,
      error: _createError,
      onWrittenDown: (v) => setState(() => _writtenDown = v),
      onContinue: _create,
      onBack: () => setState(() => _step = _Step.confirmPin),
    ),
  };
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(DokkiSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(DokkiRadius.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(DokkiSpace.lg),
              child: Icon(
                Icons.lock_outline,
                color: scheme.onPrimary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: DokkiSpace.xl),
          Text('dokki', style: text.displaySmall),
          const SizedBox(height: DokkiSpace.sm),
          Text(
            'A vault for the documents you can’t afford to lose or leak.',
            style: text.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: DokkiSpace.xl),
          const _Point(
            icon: Icons.enhanced_encryption_outlined,
            text: 'Everything is encrypted before it touches storage.',
          ),
          const _Point(
            icon: Icons.cloud_off_outlined,
            text: 'Nothing leaves this device unless you turn on sync.',
          ),
          const _Point(
            icon: Icons.key_outlined,
            text: 'Your keys are yours. dokki cannot read your vault.',
          ),
          const Spacer(),
          FilledButton(
            onPressed: onStart,
            child: const Text('Create my vault'),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: DokkiSpace.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.tertiary),
          const SizedBox(width: DokkiSpace.md),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _PinStep extends StatelessWidget {
  const _PinStep({
    required this.title,
    required this.subtitle,
    required this.onCompleted,
    required this.onBack,
    this.error = false,
  });

  final String title;
  final String subtitle;
  final bool error;
  final Future<void> Function(String) onCompleted;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
        ),
        const Spacer(),
        Text(title, style: text.headlineSmall),
        const SizedBox(height: DokkiSpace.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.xxl),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: error ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: DokkiSpace.xxl),
        PinPad(
          length: OnboardingFlow.pinLength,
          onCompleted: onCompleted,
          error: error,
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _PassphraseStep extends StatelessWidget {
  const _PassphraseStep({
    required this.words,
    required this.writtenDown,
    required this.busy,
    required this.error,
    required this.onWrittenDown,
    required this.onContinue,
    required this.onBack,
  });

  final List<String> words;
  final bool writtenDown;
  final bool busy;
  final String? error;
  final ValueChanged<bool> onWrittenDown;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: busy ? null : onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.xl),
            children: [
              const SecurityChip(
                'Recovery passphrase',
                icon: Icons.key_outlined,
              ),
              const SizedBox(height: DokkiSpace.lg),
              Text('Write these six words down', style: text.headlineSmall),
              const SizedBox(height: DokkiSpace.sm),
              Text(
                'If this phone is lost, reset, or your fingerprint changes, '
                'this passphrase is the only way back into your vault. dokki '
                'cannot recover it for you.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DokkiSpace.xl),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(DokkiRadius.card),
                  border: Border.all(
                    color: scheme.tertiary.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DokkiSpace.lg),
                  child: Wrap(
                    spacing: DokkiSpace.sm,
                    runSpacing: DokkiSpace.sm,
                    children: [
                      for (var i = 0; i < words.length; i++)
                        _WordChip(index: i + 1, word: words[i]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DokkiSpace.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: words.join(' ')),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Copied. The clipboard clears in 30 s.',
                          ),
                        ),
                      );
                    }
                    // §8.5: any copied value is cleared after 30 s.
                    Future<void>.delayed(const Duration(seconds: 30), () {
                      Clipboard.setData(const ClipboardData(text: ''));
                    });
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(height: DokkiSpace.md),
              CheckboxListTile(
                value: writtenDown,
                onChanged: busy ? null : (v) => onWrittenDown(v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I’ve written these words down somewhere safe.',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: DokkiSpace.sm),
                Text(
                  error!,
                  style: text.bodyMedium?.copyWith(color: scheme.error),
                ),
              ],
              const SizedBox(height: DokkiSpace.xl),
              FilledButton(
                onPressed: writtenDown && !busy ? onContinue : null,
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create vault'),
              ),
              const SizedBox(height: DokkiSpace.xl),
            ],
          ),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.index, required this.word});

  final int index;
  final String word;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DokkiRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DokkiSpace.md,
          vertical: DokkiSpace.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$index',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: DokkiSpace.sm),
            Text(
              word,
              style: text.titleMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
