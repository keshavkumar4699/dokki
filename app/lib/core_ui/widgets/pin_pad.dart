/// A numeric PIN pad with dot indicators, haptics, a "verifying" wave
/// while the PIN is being checked, and an error shake.
///
/// Shared by the unlock screen and onboarding so the two never drift.
library;

import 'dart:async';
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion.dart';
import '../tokens.dart';

class PinPad extends StatefulWidget {
  const PinPad({
    required this.length,
    required this.onCompleted,
    this.enabled = true,
    this.error = false,
    this.trailingAction,
    super.key,
  });

  final int length;

  /// Called with the full PIN once [length] digits are entered. The pad
  /// clears itself after the callback returns.
  final Future<void> Function(String pin) onCompleted;

  final bool enabled;

  /// Flip to `true` to play the shake + clear animation.
  final bool error;

  /// Bottom-right slot: biometric button, "forgot", or nothing.
  final Widget? trailingAction;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with TickerProviderStateMixin {
  final List<int> _digits = [];
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: DokkiDuration.slow,
  );

  /// Runs only while [_busy]: a soft wave travelling across the dots, so
  /// the second or so of Argon2id never looks like a hang.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _busy = false;

  @override
  void didUpdateWidget(PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error && !oldWidget.error) {
      _shake.forward(from: 0);
      unawaited(HapticFeedback.heavyImpact());
      setState(_digits.clear);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _wave.dispose();
    super.dispose();
  }

  Future<void> _press(int digit) async {
    if (!widget.enabled || _busy || _digits.length >= widget.length) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() => _digits.add(digit));
    if (_digits.length == widget.length) {
      setState(() => _busy = true);
      if (!reduceMotion(context)) {
        unawaited(_wave.repeat());
      }
      await widget.onCompleted(_digits.join());
      if (mounted) {
        _wave
          ..stop()
          ..value = 0;
        setState(() {
          _busy = false;
          _digits.clear();
        });
      }
    }
  }

  void _backspace() {
    if (_digits.isEmpty || _busy) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(_digits.removeLast);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final t = _shake.value;
          final dx = t == 0 ? 0.0 : (1 - t) * 12 * sin(t * 6 * pi);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: AnimatedBuilder(
          animation: _wave,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++)
                _Dot(filled: i < _digits.length, glow: _busy ? _waveAt(i) : 0),
            ],
          ),
        ),
      ),
      const SizedBox(height: DokkiSpace.xxl),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in const [
              [1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
            ])
              _KeyRow(
                children: [
                  for (final d in row)
                    _Key(
                      label: '$d',
                      enabled: widget.enabled && !_busy,
                      onTap: () => _press(d),
                    ),
                ],
              ),
            _KeyRow(
              children: [
                _KeySlot(child: widget.trailingAction),
                _Key(
                  label: '0',
                  enabled: widget.enabled && !_busy,
                  onTap: () => _press(0),
                ),
                _KeySlot(
                  child: AnimatedOpacity(
                    duration: DokkiDuration.fast,
                    opacity: _digits.isEmpty || _busy ? 0.35 : 1,
                    child: IconButton(
                      onPressed: _digits.isEmpty || _busy ? null : _backspace,
                      icon: const Icon(Icons.backspace_outlined),
                      tooltip: 'Delete',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  /// 0–1 highlight for dot [i] as the wave passes over it.
  double _waveAt(int i) {
    final phase = _wave.value * 2 * pi - i * (pi / widget.length);
    return (0.5 + 0.5 * sin(phase)).clamp(0.0, 1.0);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.glow});

  final bool filled;

  /// 0 = resting; 1 = the wave crest is on this dot.
  final double glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: AnimatedScale(
        scale: filled ? 1 : 0.85,
        duration: DokkiDuration.normal,
        curve: DokkiCurves.pop,
        child: Transform.scale(
          scale: 1 + glow * 0.2,
          child: SizedBox.square(
            dimension: 14,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedContainer(
                  duration: DokkiDuration.fast,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
                if (glow > 0)
                  Opacity(
                    opacity: glow * 0.85,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      scale: 0.92,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: DokkiDuration.fast,
        opacity: enabled ? 1 : 0.6,
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DokkiRadius.tile),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DokkiRadius.tile),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeySlot extends StatelessWidget {
  const _KeySlot({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}

/// One row of three equal-width keys, 1.45:1 each, with the shared gap.
class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DokkiSpace.sm),
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: DokkiSpace.sm),
          Expanded(child: AspectRatio(aspectRatio: 1.45, child: children[i])),
        ],
      ],
    ),
  );
}
