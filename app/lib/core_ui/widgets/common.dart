/// Small shared widgets: type badge, empty state, section header, and the
/// security-affordance chip.
library;

import 'package:flutter/material.dart';
import 'package:vault_domain/vault_domain.dart';

import '../motion.dart';
import '../tokens.dart';

/// A compact pill naming the entry type with its icon and hue.
class EntryTypeBadge extends StatelessWidget {
  const EntryTypeBadge(this.type, {this.dense = false, super.key});

  final EntryType type;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = EntryTypeStyle.of(type);
    final fg = style.foregroundOn(scheme);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.tintOn(scheme),
        borderRadius: BorderRadius.circular(DokkiRadius.chip),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : DokkiSpace.sm,
          vertical: dense ? 2 : DokkiSpace.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: DokkiSpace.xs),
            Text(
              style.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A centred, calm empty state with one clear action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Scrolls rather than overflows on short viewports (landscape, split
    // screen), while staying centred whenever it fits.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DokkiSpace.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(DokkiSpace.xl),
                    child: Icon(icon, size: 40, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: DokkiSpace.xl),
              FadeSlideIn.staggered(
                1,
                child: Text(
                  title,
                  style: text.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: DokkiSpace.sm),
              FadeSlideIn.staggered(
                2,
                child: Text(
                  message,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: DokkiSpace.xl),
                FadeSlideIn.staggered(3, child: action!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercase eyebrow label for grouping settings and detail sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DokkiSpace.lg,
        DokkiSpace.xl,
        DokkiSpace.lg,
        DokkiSpace.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The brass "this is about your keys" chip.
class SecurityChip extends StatelessWidget {
  const SecurityChip(this.label, {this.icon = Icons.lock_outline, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
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
            Icon(icon, size: 16, color: scheme.onTertiaryContainer),
            const SizedBox(width: DokkiSpace.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Relative time for list rows ("just now", "3 min ago", "Yesterday").
String relativeTime(DateTime when, DateTime now) {
  final diff = now.difference(when);
  if (diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} h ago';
  }
  if (diff.inDays == 1) {
    return 'Yesterday';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} days ago';
  }
  final local = when.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}
