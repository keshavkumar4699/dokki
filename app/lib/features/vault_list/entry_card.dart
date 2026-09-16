/// One tile in the vault grid: thumbnail, type badge, title, freshness.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/motion.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../core_ui/widgets/thumbnail_image.dart';

/// Shared by the grid tile and the detail viewer so the cover flies
/// between them.
String coverHeroTag(EntryId id) => 'cover-$id';

class EntryCard extends ConsumerWidget {
  const EntryCard({
    required this.summary,
    required this.onTap,
    this.index = 0,
    super.key,
  });

  final VaultEntrySummary summary;
  final VoidCallback onTap;

  /// Position in the grid; drives the entrance stagger. Tiles past the
  /// first screenful appear without one.
  final int index;

  static const _animatedTiles = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = EntryTypeStyle.of(summary.type);
    final now = ref.read(appGraphProvider).context.now();
    final cover = summary.coverVersionId;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (cover != null)
                    Hero(
                      tag: coverHeroTag(summary.id),
                      child: ThumbnailImage(
                        versionId: cover,
                        size: ThumbnailSizeClass.m,
                        type: summary.type,
                      ),
                    )
                  else
                    ColoredBox(
                      color: style.tintOn(scheme),
                      child: Center(
                        child: Icon(
                          style.icon,
                          size: 36,
                          color: style.foregroundOn(scheme),
                        ),
                      ),
                    ),
                  Positioned(
                    left: DokkiSpace.sm,
                    top: DokkiSpace.sm,
                    child: EntryTypeBadge(summary.type, dense: true),
                  ),
                  if (summary.assetCount > 1)
                    Positioned(
                      right: DokkiSpace.sm,
                      top: DokkiSpace.sm,
                      child: _CountPill(
                        count: summary.assetCount,
                        label: summary.type == EntryType.document
                            ? 'pages'
                            : 'sides',
                      ),
                    ),
                  if (summary.hasOpenConflict)
                    Positioned(
                      right: DokkiSpace.sm,
                      bottom: DokkiSpace.sm,
                      child: Icon(
                        Icons.call_split,
                        size: 18,
                        color: scheme.error,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DokkiSpace.md,
                DokkiSpace.sm,
                DokkiSpace.md,
                DokkiSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.title?.isNotEmpty ?? false
                        ? summary.title!
                        : 'Untitled ${style.label.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relativeTime(summary.updatedAt, now),
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final pressable = PressScale(child: card);
    if (index >= _animatedTiles) {
      return pressable;
    }
    return FadeSlideIn.staggered(index, child: pressable);
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.inverseSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(DokkiRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '$count $label',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onInverseSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
