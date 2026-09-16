/// Version history for one asset (§10): every version row survives, the
/// evicted ones can be rebuilt from their recipe, and the original is
/// permanent. Tapping a version makes it current.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/motion.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../core_ui/widgets/thumbnail_image.dart';

Future<void> showVersionHistorySheet(BuildContext context, Asset asset) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _VersionHistorySheet(assetId: asset.id, entryId: asset.entryId),
    );

class _VersionHistorySheet extends ConsumerStatefulWidget {
  const _VersionHistorySheet({required this.assetId, required this.entryId});

  final AssetId assetId;
  final EntryId entryId;

  @override
  ConsumerState<_VersionHistorySheet> createState() =>
      _VersionHistorySheetState();
}

class _VersionHistorySheetState extends ConsumerState<_VersionHistorySheet> {
  VersionId? _switching;

  Future<void> _switchTo(AssetVersion version) async {
    setState(() => _switching = version.id);
    final result = await ref
        .read(appGraphProvider)
        .switchVersion
        .execute(widget.assetId, version.id);
    if (!mounted) {
      return;
    }
    setState(() => _switching = null);
    result.fold(
      (_) => Navigator.of(context).pop(),
      (failure) => showFailureSnack(context, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(entryProvider(widget.entryId)).value;
    final asset = entry?.assets
        .where((a) => a.id == widget.assetId)
        .firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (asset == null) {
      return const SizedBox(height: 200);
    }
    final versions = [...asset.versions]
      ..sort((a, b) => b.seq.compareTo(a.seq));
    final now = ref.read(appGraphProvider).context.now();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          DokkiSpace.lg,
          0,
          DokkiSpace.lg,
          DokkiSpace.xl,
        ),
        children: [
          Text('History', style: text.titleLarge),
          const SizedBox(height: DokkiSpace.xs),
          Text(
            'The original is kept forever. Recent edits keep their pixels; '
            'older ones keep their recipe and are rebuilt on demand.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: DokkiSpace.lg),
          for (var i = 0; i < versions.length; i++)
            FadeSlideIn.staggered(
              i,
              child: _VersionTile(
                version: versions[i],
                isCurrent: versions[i].id == asset.currentVersionId,
                type: entry!.type,
                now: now,
                busy: _switching == versions[i].id,
                onTap:
                    versions[i].id == asset.currentVersionId ||
                        _switching != null
                    ? null
                    : () => _switchTo(versions[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({
    required this.version,
    required this.isCurrent,
    required this.type,
    required this.now,
    required this.busy,
    required this.onTap,
  });

  final AssetVersion version;
  final bool isCurrent;
  final EntryType type;
  final DateTime now;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ops = version.recipe?.ops ?? const [];
    final label = version.isOriginal
        ? 'Original'
        : ops.map((o) => o.opType).join(' · ');
    final status = version.isEvicted
        ? (version.canRematerialize ? 'Rebuilds on demand' : 'Unavailable')
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: DokkiSpace.sm),
      child: PressScale(
        enabled: onTap != null,
        child: Material(
          color: isCurrent
              ? scheme.primaryContainer.withValues(alpha: 0.5)
              : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DokkiRadius.tile),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DokkiRadius.tile),
            child: Padding(
              padding: const EdgeInsets.all(DokkiSpace.md),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 56,
                    child: version.isMaterialized
                        ? ThumbnailImage(
                            versionId: version.id,
                            size: ThumbnailSizeClass.s,
                            type: type,
                            borderRadius: BorderRadius.circular(
                              DokkiRadius.chip,
                            ),
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                DokkiRadius.chip,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_fix_high_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: DokkiSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: text.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (version.isPinned)
                              Icon(
                                Icons.push_pin_outlined,
                                size: 16,
                                color: scheme.tertiary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            'v${version.seq}',
                            '${version.meta.width}×${version.meta.height}',
                            relativeTime(version.createdAt, now),
                            if (status != null) status,
                          ].join(' · '),
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DokkiSpace.sm),
                  if (busy)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (isCurrent)
                    const SecurityChip('Current', icon: Icons.check)
                  else if (version.isEvicted && !version.canRematerialize)
                    Icon(Icons.block, color: scheme.outline)
                  else
                    Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
