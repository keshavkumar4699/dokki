/// The export sheet (§11 quick export): pick a preset, optionally narrow
/// to the visible page or side, export, read the honest summary, share.
/// Two taps from the entry to a shared file; no editor.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/app_graph.dart';
import '../../bootstrap/providers.dart';
import '../../core_ui/export_copy.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/motion.dart';
import '../../core_ui/tokens.dart';
import '../../core_ui/widgets/common.dart';

/// Opens the sheet for [entry]; [visible] is the asset on screen, offered
/// as a "just this page/side" scope when the entry has several.
Future<void> showExportSheet(
  BuildContext context,
  VaultEntry entry, {
  Asset? visible,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ExportSheet(entry: entry, visible: visible),
);

/// Re-runs a past export and offers to share it (§11.7 "Export Again").
Future<void> showExportAgainSheet(BuildContext context, ExportId exportId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExportSheet(again: exportId),
    );

enum _Scope { all, visible }

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({this.entry, this.visible, this.again});

  final VaultEntry? entry;
  final Asset? visible;
  final ExportId? again;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  String _presetId = 'full';
  _Scope _scope = _Scope.visible;
  bool _busy = false;
  int _stage = 0;
  int _stages = 1;
  ExportResult? _result;
  VaultFailure? _failure;
  bool _sharing = false;
  CancellationToken? _cancel;

  bool get _multi => (widget.entry?.liveAssets.length ?? 0) > 1;

  @override
  void initState() {
    super.initState();
    if (widget.again != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    final exports = ref.read(appGraphProvider).exports;
    final cancel = CancellationToken();
    setState(() {
      _busy = true;
      _failure = null;
      _result = null;
      _stage = 0;
      _cancel = cancel;
    });
    void progress(int done, int? total) {
      if (mounted) {
        setState(() {
          _stage = done;
          _stages = total ?? 1;
        });
      }
    }

    final again = widget.again;
    final result = again != null
        ? await exports.again(again, progress: progress, cancel: cancel)
        : await exports.quick(
            widget.entry!.id,
            presetId: _presetId,
            onlyVersion: _multi && _scope == _Scope.visible
                ? widget.visible?.currentVersionId
                : null,
            progress: progress,
            cancel: cancel,
          );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _cancel = null;
      result.fold((r) => _result = r, (f) => _failure = f);
    });
    final entryId = widget.entry?.id;
    if (entryId != null) {
      ref.invalidate(exportHistoryProvider(entryId));
    }
  }

  Future<void> _share() async {
    final result = _result;
    if (result == null || _sharing) {
      return;
    }
    setState(() => _sharing = true);
    final prepared = await ref.read(appGraphProvider).prepareShare(result.id);
    if (!mounted) {
      return;
    }
    await prepared.fold(
      _shareHandle,
      (failure) async => showFailureSnack(context, failure),
    );
    if (mounted) {
      setState(() => _sharing = false);
    }
  }

  Future<void> _shareHandle(ShareHandle handle) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(handle.path, mimeType: handle.mimeType)],
          fileNameOverrides: [handle.fileName],
        ),
      );
    } finally {
      // The plaintext copy lives exactly as long as the share sheet.
      await handle.discard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final presets = ref.read(appGraphProvider).exports.presets;
    final entry = widget.entry;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DokkiSpace.lg,
        0,
        DokkiSpace.lg,
        DokkiSpace.xl,
      ),
      child: AnimatedSize(
        duration: DokkiDuration.normal,
        curve: DokkiCurves.standard,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: DokkiDuration.normal,
          child: switch ((_busy, _result, _failure)) {
            (true, _, _) => _Progress(
              key: const ValueKey('busy'),
              stage: _stage,
              stages: _stages,
              onCancel: () => _cancel?.cancel(),
            ),
            (_, final ExportResult result, _) => _Summary(
              key: const ValueKey('done'),
              result: result,
              sharing: _sharing,
              onShare: _share,
              onDone: () => Navigator.of(context).pop(),
            ),
            (_, _, final VaultFailure failure) => _Failed(
              key: const ValueKey('failed'),
              failure: failure,
              onRetry: _run,
              onClose: () => Navigator.of(context).pop(),
            ),
            _ => Column(
              key: const ValueKey('form'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export', style: text.titleLarge),
                const SizedBox(height: DokkiSpace.xs),
                Text(
                  'The file leaves the vault when you share it.',
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry != null && _multi) ...[
                  const SizedBox(height: DokkiSpace.lg),
                  _ScopeChips(
                    entry: entry,
                    visible: widget.visible,
                    scope: _scope,
                    onChanged: (s) => setState(() => _scope = s),
                  ),
                ],
                const SizedBox(height: DokkiSpace.lg),
                for (final preset in presets.forType(
                  entry?.type ?? EntryType.photo,
                ))
                  _PresetTile(
                    preset: preset,
                    selected: preset.id == _presetId,
                    onTap: () => setState(() => _presetId = preset.id),
                  ),
                const SizedBox(height: DokkiSpace.lg),
                FilledButton.icon(
                  onPressed: _run,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Export'),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

/// "This page" vs "All pages" — the latter only as a PDF, which is the
/// next phase, so it is shown disabled with an honest hint.
class _ScopeChips extends StatelessWidget {
  const _ScopeChips({
    required this.entry,
    required this.visible,
    required this.scope,
    required this.onChanged,
  });

  final VaultEntry entry;
  final Asset? visible;
  final _Scope scope;
  final ValueChanged<_Scope> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = switch (visible?.role) {
      AssetRole.idFront => 'Front only',
      AssetRole.idBack => 'Back only',
      _ => 'This page',
    };
    final all = entry.type == EntryType.id ? 'Both sides (PDF)' : 'All pages (PDF)';
    return Wrap(
      spacing: DokkiSpace.sm,
      children: [
        ChoiceChip(
          label: Text(label),
          selected: scope == _Scope.visible,
          onSelected: (_) => onChanged(_Scope.visible),
        ),
        Tooltip(
          message: 'PDF export arrives with the next release.',
          child: ChoiceChip(label: Text(all), selected: scope == _Scope.all),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final ExportPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, hint) = switch (preset.id) {
      'email' => (
        Icons.mail_outline,
        'Aims at about 200 KB; tells you where it landed.',
      ),
      'png' => (Icons.grid_on_outlined, 'Every pixel kept. Larger file.'),
      _ => (Icons.high_quality_outlined, 'Best for printing and records.'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: DokkiSpace.sm),
      child: PressScale(
        child: AnimatedContainer(
          duration: DokkiDuration.fast,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.45)
                : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(DokkiRadius.tile),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DokkiRadius.tile),
            child: Padding(
              padding: const EdgeInsets.all(DokkiSpace.md),
              child: Row(
                children: [
                  Icon(icon, color: scheme.primary),
                  const SizedBox(width: DokkiSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(preset.displayName, style: text.titleSmall),
                        Text(
                          hint,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    duration: DokkiDuration.fast,
                    opacity: selected ? 1 : 0,
                    child: Icon(Icons.check_circle, color: scheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.stage,
    required this.stages,
    required this.onCancel,
    super.key,
  });

  final int stage;
  final int stages;
  final VoidCallback onCancel;

  static const _labels = [
    'Checking the request…',
    'Finding the pages…',
    'Decrypting and preparing…',
    'Finding the right size…',
    'Encoding…',
    'Sealing the result…',
    'Recording…',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exporting', style: text.titleLarge),
        const SizedBox(height: DokkiSpace.lg),
        TweenAnimationBuilder<double>(
          tween: Tween(end: (stage + 1) / (stages + 1)),
          duration: DokkiDuration.normal,
          curve: DokkiCurves.standard,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: DokkiSpace.md),
        AnimatedSwitcher(
          duration: DokkiDuration.fast,
          child: Text(
            _labels[stage.clamp(0, _labels.length - 1)],
            key: ValueKey(stage),
            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: DokkiSpace.lg),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.result,
    required this.sharing,
    required this.onShare,
    required this.onDone,
    super.key,
  });

  final ExportResult result;
  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final facts = [
      formatLabel(result.format),
      formatBytes(result.actualBytes),
      if (result.format != OutputFormat.pdf)
        '${result.outWidth} × ${result.outHeight}',
      if (result.pageCount > 1) '${result.pageCount} pages',
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PopIn(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DokkiSpace.sm),
                  child: Icon(
                    Icons.check_rounded,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DokkiSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ready to share', style: text.titleLarge),
                  Text(
                    facts,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: DokkiSpace.lg),
          for (var i = 0; i < result.warnings.length; i++)
            FadeSlideIn.staggered(
              i + 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: DokkiSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DokkiSpace.sm),
                    Expanded(
                      child: Text(
                        describeExportWarning(result.warnings[i]),
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: DokkiSpace.lg),
        const SecurityChip(
          'Leaves the vault unencrypted when shared',
          icon: Icons.lock_open_outlined,
        ),
        const SizedBox(height: DokkiSpace.lg),
        FilledButton.icon(
          onPressed: sharing ? null : onShare,
          icon: sharing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share_outlined),
          label: const Text('Share'),
        ),
        const SizedBox(height: DokkiSpace.sm),
        OutlinedButton(onPressed: onDone, child: const Text('Done')),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({
    required this.failure,
    required this.onRetry,
    required this.onClose,
    super.key,
  });

  final VaultFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final copy = describeFailure(failure);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.title, style: text.titleLarge),
        const SizedBox(height: DokkiSpace.sm),
        Text(
          copy.detail,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: DokkiSpace.lg),
        if (failure is! OperationCancelled)
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        const SizedBox(height: DokkiSpace.sm),
        OutlinedButton(onPressed: onClose, child: const Text('Close')),
      ],
    );
  }
}
