/// One tile in the vault grid: thumbnail, type badge, title, freshness.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../core_ui/widgets/thumbnail_image.dart';

/// The summary carries no version id, so the card resolves the entry's
/// first live asset lazily; the grid stays a single cheap query.
final _coverVersionProvider = FutureProvider.family<VersionId?, EntryId>((
  ref,
  id,
) async {
  final result = await ref.watch(queriesProvider).entry(id);
  return result.fold(
    (entry) => entry.liveAssets.firstOrNull?.currentVersionId,
    (_) => null,
  );
});

class EntryCard extends ConsumerWidget {
  const EntryCard({required this.summary, required this.onTap, super.key});

  final VaultEntrySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = EntryTypeStyle.of(summary.type);
    final cover = ref.watch(_coverVersionProvider(summary.id));
    final now = ref.read(appGraphProvider).context.now();

    return Card(
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
                  switch (cover) {
                    AsyncData(value: final versionId?) => ThumbnailImage(
                      versionId: versionId,
                      size: ThumbnailSizeClass.m,
                      type: summary.type,
                    ),
                    _ => ColoredBox(
                      color: style.tintOn(scheme),
                      child: Center(
                        child: Icon(
                          style.icon,
                          size: 36,
                          color: style.foregroundOn(scheme),
                        ),
                      ),
                    ),
                  },
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
