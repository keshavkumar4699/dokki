/// One entry: a full-bleed viewer over its assets (pages / ID sides), the
/// metadata card, and the actions that exercise the version model.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../core_ui/widgets/thumbnail_image.dart';
import '../capture_import/image_source_picker.dart';
import '../vault_list/add_entry_sheet.dart';
import 'edit_details_sheet.dart';
import 'version_history_sheet.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({required this.entryId, super.key});

  final EntryId entryId;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  final PageController _pages = PageController();
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<Result<Object?, VaultFailure>> Function() action, {
    String? success,
  }) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    result.fold((_) {
      if (success != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(success)));
      }
    }, (failure) => showFailureSnack(context, failure));
  }

  Future<void> _rotate(Asset asset) => _run(
    () => ref
        .read(appGraphProvider)
        .commitEdit
        .execute(asset.id, const EditRecipe([RotateOp(1)])),
    success: 'Rotated. The previous version is kept in history.',
  );

  Future<void> _addAsset(VaultEntry entry, AssetRole role) async {
    final picked = await ref
        .read(imageSourcePickerProvider)
        .pick(CaptureSource.gallery);
    if (picked == null || !mounted) {
      return;
    }
    await _run(
      () => ref
          .read(appGraphProvider)
          .addAsset
          .execute(entry.id, role: role, source: picked),
      success: role == AssetRole.page ? 'Page added.' : 'Back added.',
    );
  }

  Future<void> _deleteAsset(Asset asset) async {
    final confirmed = await _confirm(
      title: 'Remove this page?',
      body: 'It goes to the vault’s trash and is purged after 180 days.',
      action: 'Remove',
    );
    if (confirmed) {
      await _run(
        () => ref.read(appGraphProvider).deleteAsset.execute(asset.id),
      );
      if (mounted && _index > 0) {
        setState(() => _index -= 1);
      }
    }
  }

  Future<void> _deleteEntry(VaultEntry entry) async {
    final confirmed = await _confirm(
      title:
          'Delete this ${EntryTypeStyle.of(entry.type).label.toLowerCase()}?',
      body:
          'It disappears from the vault now and is purged for good after '
          '180 days, so an offline device can still catch up.',
      action: 'Delete',
    );
    if (!confirmed) {
      return;
    }
    final result = await ref
        .read(appGraphProvider)
        .deleteEntry
        .execute(entry.id);
    if (!mounted) {
      return;
    }
    result.fold(
      (_) => context.pop(),
      (failure) => showFailureSnack(context, failure),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(entryProvider(widget.entryId));
    return entry.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.error_outline,
          title: describeError(error).title,
          message: describeError(error).detail,
        ),
      ),
      data: (entry) {
        if (entry == null || entry.isDeleted) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.delete_outline,
              title: 'This item was deleted',
              message: 'It is no longer in the vault.',
            ),
          );
        }
        return _build(context, entry);
      },
    );
  }

  Widget _build(BuildContext context, VaultEntry entry) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = EntryTypeStyle.of(entry.type);
    final assets = entry.liveAssets.toList(growable: false);
    final index = _index.clamp(0, assets.length - 1);
    final current = assets[index];
    final spec = specFor(entry.type);
    final canAddPage = spec.ordinalIsMeaningful;
    final canAddBack =
        entry.type == EntryType.id &&
        !assets.any((a) => a.role == AssetRole.idBack);
    final title = entry.title?.isNotEmpty ?? false
        ? entry.title!
        : 'Untitled ${style.label.toLowerCase()}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Edit details',
            onPressed: () => showEditDetailsSheet(context, entry),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'delete' => _deleteEntry(entry),
              _ => null,
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: scheme.error),
                  title: Text('Delete', style: TextStyle(color: scheme.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: DokkiSpace.xxl),
        children: [
          // ── Viewer ────────────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.48,
            child: ColoredBox(
              color: scheme.surfaceContainerLow,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pages,
                    itemCount: assets.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.all(DokkiSpace.lg),
                      child: Center(
                        child: ThumbnailImage(
                          key: ValueKey(assets[i].currentVersionId),
                          versionId: assets[i].currentVersionId,
                          size: ThumbnailSizeClass.l,
                          type: entry.type,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(DokkiRadius.tile),
                        ),
                      ),
                    ),
                  ),
                  if (assets.length > 1)
                    Positioned(
                      bottom: DokkiSpace.md,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _PageIndicator(
                          label: _slotLabel(
                            entry.type,
                            current,
                            index,
                            assets.length,
                          ),
                        ),
                      ),
                    ),
                  if (_busy)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black26,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ── Quick actions on the visible asset ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DokkiSpace.lg,
              DokkiSpace.md,
              DokkiSpace.lg,
              0,
            ),
            child: Row(
              children: [
                _Action(
                  icon: Icons.rotate_90_degrees_cw_outlined,
                  label: 'Rotate',
                  onTap: _busy ? null : () => _rotate(current),
                ),
                _Action(
                  icon: Icons.history,
                  label: 'History',
                  badge: current.versions.length > 1
                      ? '${current.versions.length}'
                      : null,
                  onTap: _busy
                      ? null
                      : () => showVersionHistorySheet(context, current),
                ),
                if (canAddPage)
                  _Action(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Add page',
                    onTap: _busy
                        ? null
                        : () => _addAsset(entry, AssetRole.page),
                  ),
                if (canAddBack)
                  _Action(
                    icon: Icons.flip_outlined,
                    label: 'Add back',
                    onTap: _busy
                        ? null
                        : () => _addAsset(entry, AssetRole.idBack),
                  ),
                if (assets.length > 1)
                  _Action(
                    icon: Icons.remove_circle_outline,
                    label: 'Remove',
                    onTap: _busy ? null : () => _deleteAsset(current),
                  ),
              ],
            ),
          ),
          // ── Metadata ──────────────────────────────────────────────────
          const SectionHeader('Details'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.lg),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(DokkiSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        EntryTypeBadge(entry.type),
                        const Spacer(),
                        Text(
                          '${current.currentVersion?.meta.width ?? '?'} × '
                          '${current.currentVersion?.meta.height ?? '?'}',
                          style: text.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DokkiSpace.md),
                    Text(title, style: text.titleMedium),
                    if (entry.note?.isNotEmpty ?? false) ...[
                      const SizedBox(height: DokkiSpace.sm),
                      Text(entry.note!, style: text.bodyMedium),
                    ],
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: DokkiSpace.md),
                      Wrap(
                        spacing: DokkiSpace.sm,
                        runSpacing: DokkiSpace.sm,
                        children: [
                          for (final tag in entry.tags)
                            Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: DokkiSpace.md),
                    Text(
                      'Added ${relativeTime(entry.createdAt, ref.read(appGraphProvider).context.now())}'
                      ' · Updated ${relativeTime(entry.updatedAt, ref.read(appGraphProvider).context.now())}',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Pages strip (documents) ───────────────────────────────────
          if (entry.type == EntryType.document && assets.length > 1) ...[
            const SectionHeader('Pages'),
            _PageStrip(
              assets: assets,
              selected: index,
              type: entry.type,
              busy: _busy,
              onSelect: (i) => _pages.animateToPage(
                i,
                duration: DokkiDuration.normal,
                curve: Curves.easeOutCubic,
              ),
              onReorder: (ordered) => _run(
                () => ref
                    .read(appGraphProvider)
                    .reorderPages
                    .execute(entry.id, ordered),
              ),
            ),
          ],
          const SectionHeader('Export'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.lg),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.ios_share_outlined),
                title: const Text('Export'),
                subtitle: const Text(
                  'JPEG, PNG and PDF export arrive with the export engine.',
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: false,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _slotLabel(EntryType type, Asset asset, int index, int total) =>
      switch (asset.role) {
        AssetRole.idFront => 'Front',
        AssetRole.idBack => 'Back',
        AssetRole.page => 'Page ${index + 1} of $total',
        AssetRole.primary => '${index + 1} / $total',
      };
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.label});

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
        padding: const EdgeInsets.symmetric(
          horizontal: DokkiSpace.md,
          vertical: DokkiSpace.xs,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onInverseSurface),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DokkiRadius.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DokkiSpace.sm),
          child: Column(
            children: [
              Badge(
                isLabelVisible: badge != null,
                label: Text(badge ?? ''),
                child: Icon(
                  icon,
                  color: onTap == null ? scheme.outline : scheme.primary,
                ),
              ),
              const SizedBox(height: DokkiSpace.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageStrip extends StatelessWidget {
  const _PageStrip({
    required this.assets,
    required this.selected,
    required this.type,
    required this.busy,
    required this.onSelect,
    required this.onReorder,
  });

  final List<Asset> assets;
  final int selected;
  final EntryType type;
  final bool busy;
  final ValueChanged<int> onSelect;
  final ValueChanged<List<AssetId>> onReorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DokkiSpace.lg),
        buildDefaultDragHandles: false,
        itemCount: assets.length,
        onReorder: (from, to) {
          if (busy) {
            return;
          }
          final ids = assets.map((a) => a.id).toList();
          final moved = ids.removeAt(from);
          ids.insert(to > from ? to - 1 : to, moved);
          onReorder(ids);
        },
        itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
          key: ValueKey(assets[i].id),
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(right: DokkiSpace.sm),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: DokkiDuration.fast,
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DokkiRadius.chip),
                  border: Border.all(
                    color: i == selected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ThumbnailImage(
                      versionId: assets[i].currentVersionId,
                      size: ThumbnailSizeClass.s,
                      type: type,
                      borderRadius: BorderRadius.circular(DokkiRadius.chip - 2),
                    ),
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: _PageIndicator(label: '${i + 1}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
