/// One entry: a full-bleed viewer over its assets (pages / ID sides), the
/// metadata card, and the actions that exercise the version model.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/motion.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';
import '../../core_ui/widgets/thumbnail_image.dart';
import '../capture_import/image_source_picker.dart';
import '../vault_list/add_entry_sheet.dart';
import '../vault_list/entry_card.dart' show coverHeroTag;
import 'edit_details_sheet.dart';
import 'version_history_sheet.dart';

/// Above this width the viewer and the details sit side by side.
const _wideBreakpoint = 720.0;

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

  /// Rotate is previewed optimistically: the viewer turns the pixels it
  /// already has while the real edit is committed. Requests count taps,
  /// commits count successes; the difference is what is still pending.
  final Map<AssetId, int> _rotateRequests = {};
  final Map<AssetId, int> _rotateCommits = {};

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<bool> _run(
    Future<Result<Object?, VaultFailure>> Function() action, {
    String? success,
  }) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) {
      return false;
    }
    setState(() => _busy = false);
    return result.fold(
      (_) {
        if (success != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(success)));
        }
        return true;
      },
      (failure) {
        showFailureSnack(context, failure);
        return false;
      },
    );
  }

  Future<void> _rotate(Asset asset) async {
    setState(
      () => _rotateRequests[asset.id] = (_rotateRequests[asset.id] ?? 0) + 1,
    );
    final ok = await _run(
      () => ref
          .read(appGraphProvider)
          .commitEdit
          .execute(asset.id, const EditRecipe([RotateOp(1)])),
      success: 'Rotated. The previous version is kept in history.',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      if (ok) {
        _rotateCommits[asset.id] = (_rotateCommits[asset.id] ?? 0) + 1;
      } else {
        _rotateRequests[asset.id] = _rotateRequests[asset.id]! - 1;
      }
    });
  }

  /// Phase 8: auto edge detection + perspective correction (§17). A
  /// failed detection is honest — the snackbar says so; the previous
  /// version is always kept in history either way.
  Future<void> _enhance(Asset asset) async {
    final enhance = ref.read(appGraphProvider).enhance;
    if (enhance == null) {
      return;
    }
    await _run(
      () => enhance.execute(asset.id),
      success: 'Edges corrected. The previous version is kept in history.',
    );
  }

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
    final style = EntryTypeStyle.of(entry.type);
    final assets = entry.liveAssets.toList(growable: false);
    final index = _index.clamp(0, assets.length - 1);
    final current = assets[index];
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;
          final viewer = _viewer(entry, assets, index, current);
          final details = _details(entry, assets, index, current, title);
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: viewer),
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: DokkiSpace.xxl),
                    children: details,
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: DokkiSpace.xxl),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.48,
                child: viewer,
              ),
              ...details,
            ],
          );
        },
      ),
    );
  }

  // ── Viewer ────────────────────────────────────────────────────────────
  Widget _viewer(
    VaultEntry entry,
    List<Asset> assets,
    int index,
    Asset current,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: assets.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _PageParallax(
              controller: _pages,
              page: i,
              fallbackPage: index,
              child: Padding(
                padding: const EdgeInsets.all(DokkiSpace.lg),
                child: _AssetViewer(
                  key: ValueKey(assets[i].id),
                  versionId: assets[i].currentVersionId,
                  aspectRatio: _aspectOf(assets[i]),
                  type: entry.type,
                  heroTag: i == 0 ? coverHeroTag(entry.id) : null,
                  rotateRequests: _rotateRequests[assets[i].id] ?? 0,
                  rotateCommits: _rotateCommits[assets[i].id] ?? 0,
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
                child: AnimatedSwitcher(
                  duration: DokkiDuration.fast,
                  child: _PageIndicator(
                    key: ValueKey(index),
                    label: _slotLabel(
                      entry.type,
                      current,
                      index,
                      assets.length,
                    ),
                  ),
                ),
              ),
            ),
          // Work in progress: a thin brass line along the bottom edge and
          // a touch of dimming, instead of a modal spinner over the image.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_busy,
              child: AnimatedOpacity(
                duration: DokkiDuration.normal,
                opacity: _busy ? 1 : 0,
                child: ColoredBox(
                  color: scheme.scrim.withValues(alpha: 0.12),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: scheme.tertiary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _aspectOf(Asset asset) {
    final meta = asset.currentVersion?.meta;
    if (meta == null || meta.width <= 0 || meta.height <= 0) {
      return 1;
    }
    return meta.width / meta.height;
  }

  // ── Everything below the viewer ───────────────────────────────────────
  List<Widget> _details(
    VaultEntry entry,
    List<Asset> assets,
    int index,
    Asset current,
    String title,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final spec = specFor(entry.type);
    final canAddPage = spec.ordinalIsMeaningful;
    final canAddBack =
        entry.type == EntryType.id &&
        !assets.any((a) => a.role == AssetRole.idBack);
    final now = ref.read(appGraphProvider).context.now();

    final enhance = ref.watch(appGraphProvider).enhance;
    final actions = [
      _Action(
        icon: Icons.rotate_90_degrees_cw_outlined,
        label: 'Rotate',
        onTap: _busy ? null : () => _rotate(current),
      ),
      if (enhance != null)
        _Action(
          icon: Icons.crop_free,
          label: 'Enhance',
          onTap: _busy ? null : () => _enhance(current),
        ),
      _Action(
        icon: Icons.history,
        label: 'History',
        badge: current.versions.length > 1
            ? '${current.versions.length}'
            : null,
        onTap: _busy ? null : () => showVersionHistorySheet(context, current),
      ),
      if (canAddPage)
        _Action(
          icon: Icons.add_photo_alternate_outlined,
          label: 'Add page',
          onTap: _busy ? null : () => _addAsset(entry, AssetRole.page),
        ),
      if (canAddBack)
        _Action(
          icon: Icons.flip_outlined,
          label: 'Add back',
          onTap: _busy ? null : () => _addAsset(entry, AssetRole.idBack),
        ),
      if (assets.length > 1)
        _Action(
          icon: Icons.remove_circle_outline,
          label: 'Remove',
          onTap: _busy ? null : () => _deleteAsset(current),
        ),
    ];

    return [
      // ── Quick actions on the visible asset ────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(
          DokkiSpace.lg,
          DokkiSpace.md,
          DokkiSpace.lg,
          0,
        ),
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++)
              Expanded(child: FadeSlideIn.staggered(i + 1, child: actions[i])),
          ],
        ),
      ),
      // ── Metadata ──────────────────────────────────────────────────────
      const SectionHeader('Details'),
      FadeSlideIn.staggered(
        3,
        child: Padding(
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
                      AnimatedSwitcher(
                        duration: DokkiDuration.normal,
                        child: Text(
                          '${current.currentVersion?.meta.width ?? '?'} × '
                          '${current.currentVersion?.meta.height ?? '?'}',
                          key: ValueKey(current.currentVersionId),
                          style: text.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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
                    'Added ${relativeTime(entry.createdAt, now)}'
                    ' · Updated ${relativeTime(entry.updatedAt, now)}',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ── Pages strip (documents) ───────────────────────────────────────
      if (entry.type == EntryType.document && assets.length > 1) ...[
        const SectionHeader('Pages'),
        FadeSlideIn.staggered(
          4,
          child: _PageStrip(
            assets: assets,
            selected: index,
            type: entry.type,
            busy: _busy,
            onSelect: (i) => _pages.animateToPage(
              i,
              duration: DokkiDuration.normal,
              curve: DokkiCurves.standard,
            ),
            onReorder: (ordered) => _run(
              () => ref
                  .read(appGraphProvider)
                  .reorderPages
                  .execute(entry.id, ordered),
            ),
          ),
        ),
      ],
      const SectionHeader('Export'),
      FadeSlideIn.staggered(
        5,
        child: Padding(
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
      ),
    ];
  }

  static String _slotLabel(EntryType type, Asset asset, int index, int total) =>
      switch (asset.role) {
        AssetRole.idFront => 'Front',
        AssetRole.idBack => 'Back',
        AssetRole.page => 'Page ${index + 1} of $total',
        AssetRole.primary => '${index + 1} / $total',
      };
}

/// Shrinks and dims a page in proportion to its distance from the
/// viewport centre, so swiping between pages reads as depth, not a slide.
class _PageParallax extends StatelessWidget {
  const _PageParallax({
    required this.controller,
    required this.page,
    required this.fallbackPage,
    required this.child,
  });

  final PageController controller;
  final int page;
  final int fallbackPage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) {
      return child;
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final position =
            controller.hasClients && controller.position.hasContentDimensions
            ? controller.page ?? fallbackPage.toDouble()
            : fallbackPage.toDouble();
        final distance = (position - page).abs().clamp(0.0, 1.0);
        return Transform.scale(
          scale: 1 - 0.08 * distance,
          child: Opacity(opacity: 1 - 0.35 * distance, child: child),
        );
      },
      child: child,
    );
  }
}

/// One asset in the viewer: the current version's large preview, with the
/// grid's medium preview as a stand-in, a hero for the cover, and the
/// optimistic rotate preview (see `_EntryDetailScreenState`).
class _AssetViewer extends ConsumerStatefulWidget {
  const _AssetViewer({
    required this.versionId,
    required this.aspectRatio,
    required this.type,
    required this.rotateRequests,
    required this.rotateCommits,
    this.heroTag,
    super.key,
  });

  final VersionId versionId;
  final double aspectRatio;
  final EntryType type;
  final String? heroTag;
  final int rotateRequests;
  final int rotateCommits;

  @override
  ConsumerState<_AssetViewer> createState() => _AssetViewerState();
}

class _AssetViewerState extends ConsumerState<_AssetViewer> {
  /// The version whose pixels are on screen. Lags behind
  /// `widget.versionId` until the new version's preview is decrypted, so
  /// a rotate never flashes a placeholder.
  VersionId? _shown;
  double _shownAspect = 1;

  /// `rotateCommits` when [_shown] was captured: those turns are already
  /// baked into its pixels.
  int _commitsAtShown = 0;

  @override
  Widget build(BuildContext context) {
    final current = widget.versionId;
    final ready = ref.watch(
      thumbnailBytesProvider((
        versionId: current,
        size: ThumbnailSizeClass.l,
      )).select((state) => !state.isLoading),
    );
    if (_shown == null || (ready && _shown != current)) {
      _shown = current;
      _shownAspect = widget.aspectRatio;
      _commitsAtShown = widget.rotateCommits;
    }
    final shown = _shown!;
    final turns = widget.rotateRequests - _commitsAtShown;

    Widget image = ThumbnailImage(
      versionId: shown,
      size: ThumbnailSizeClass.l,
      standIn: ThumbnailSizeClass.m,
      type: widget.type,
      fit: BoxFit.contain,
      borderRadius: BorderRadius.circular(DokkiRadius.tile),
    );
    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.biggest;
        return Center(
          // A fresh subtree per shown version: the new pixels already
          // include the turn, so they must start at zero — no spin-back.
          child: KeyedSubtree(
            key: ValueKey(shown),
            child: AnimatedRotation(
              turns: turns / 4,
              duration: DokkiDuration.slow,
              curve: DokkiCurves.enter,
              child: AnimatedScale(
                scale: _fitScale(box, _shownAspect, turns),
                duration: DokkiDuration.slow,
                curve: DokkiCurves.enter,
                child: AspectRatio(aspectRatio: _shownAspect, child: image),
              ),
            ),
          ),
        );
      },
    );
  }

  /// How much a contain-fitted image of [aspect] must shrink so that,
  /// turned by [turns] quarter turns, it still fits [box].
  static double _fitScale(Size box, double aspect, int turns) {
    if (turns.isEven || box.isEmpty) {
      return 1;
    }
    final widthLimited = aspect >= box.width / box.height;
    final w = widthLimited ? box.width : box.height * aspect;
    final h = widthLimited ? box.width / aspect : box.height;
    return math.min(1, math.min(box.width / h, box.height / w));
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.label, super.key});

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
    return PressScale(
      scale: 0.9,
      enabled: onTap != null,
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
                child: AnimatedOpacity(
                  duration: DokkiDuration.fast,
                  opacity: onTap == null ? 0.45 : 1,
                  child: Icon(icon, color: scheme.primary),
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
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.06 * Curves.easeOut.transform(animation.value),
            child: child,
          ),
          child: child,
        ),
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
