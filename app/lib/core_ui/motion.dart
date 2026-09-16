/// Motion: the curves, durations and small entrance/press primitives every
/// screen shares, so the app moves in one voice.
///
/// Principles: motion is calm and purposeful (a vault, not a game); every
/// transition is short, decelerating and interruptible; nothing loops
/// while a screen is idle; and the OS "remove animations" setting turns
/// all of it off through [reduceMotion].
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class DokkiCurves {
  /// M3 "emphasized decelerate": fast out of the gate, long soft landing.
  static const enter = Cubic(0.05, 0.7, 0.1, 1);

  /// M3 "emphasized accelerate": for things leaving the screen.
  static const exit = Cubic(0.3, 0, 0.8, 0.15);

  static const standard = Curves.easeOutCubic;

  /// A hint of overshoot for small elements (PIN dots, chips).
  static const pop = Curves.easeOutBack;
}

abstract final class DokkiStagger {
  /// Gap between consecutive siblings.
  static const step = Duration(milliseconds: 40);

  /// Siblings past this index share the last delay; a long list must not
  /// keep the user waiting for its tail.
  static const maxSteps = 10;

  static Duration delayFor(int index) =>
      step * (index < maxSteps ? index : maxSteps);
}

/// True when the platform asks apps to remove non-essential motion.
bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Fades and slides [child] in once, on first build, after [delay].
///
/// Purely presentational: the child is laid out at its final size from
/// the first frame, so nothing under it moves.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.duration = DokkiDuration.slow,
    this.offset = const Offset(0, 0.06),
    this.curve = DokkiCurves.enter,
    super.key,
  });

  /// Stagger helper: `FadeSlideIn.staggered(index, child: …)`.
  FadeSlideIn.staggered(
    int index, {
    required this.child,
    this.duration = DokkiDuration.slow,
    this.offset = const Offset(0, 0.06),
    this.curve = DokkiCurves.enter,
    super.key,
  }) : delay = DokkiStagger.delayFor(index);

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Start offset as a fraction of the child's size.
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: Tween(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(_curved),
        child: widget.child,
      ),
    );
  }
}

/// Scales [child] down slightly while a pointer is on it — the "this is a
/// real button" feel that ripples alone don't give. Listens without
/// competing for the gesture, so the child's own tap handler still wins.
class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    this.scale = 0.965,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) {
      setState(() => _down = down);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || reduceMotion(context)) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? const Duration(milliseconds: 90) : DokkiDuration.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A one-shot scale-in with a hint of overshoot, for icons and badges
/// that appear as the result of something the user did.
class PopIn extends StatelessWidget {
  const PopIn({
    required this.child,
    this.duration = DokkiDuration.slow,
    this.from = 0.6,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final double from;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: DokkiCurves.pop,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: from + (1 - from) * t, child: child),
      ),
      child: child,
    );
  }
}
