/// Page transitions for top-level state changes.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core_ui/motion.dart';
import '../core_ui/tokens.dart';

/// The M3 fade-through: outgoing content fades away, incoming content
/// fades in while settling from 96% scale. Used where the two screens have
/// no spatial relationship (locked → open, welcome → vault).
class FadeThroughPage<T> extends CustomTransitionPage<T> {
  const FadeThroughPage({required super.child, super.key, super.name})
    : super(
        transitionDuration: DokkiDuration.slow,
        reverseTransitionDuration: DokkiDuration.normal,
        transitionsBuilder: _transition,
      );

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion(context)) {
      return child;
    }
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
      reverseCurve: const Interval(0.6, 1, curve: Curves.easeIn),
    );
    final scale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: animation, curve: DokkiCurves.enter));
    // While a *new* route is entering on top, fade this one gently.
    final fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn),
    );
    return FadeTransition(
      opacity: fadeIn,
      child: ScaleTransition(
        scale: scale,
        child: FadeTransition(opacity: fadeOut, child: child),
      ),
    );
  }
}
