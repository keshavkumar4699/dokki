/// "Add" bottom sheet: pick a type, then camera or gallery. Creation runs
/// through `CreateEntryUseCase`; progress and failures are surfaced here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vault_app_core/vault_app_core.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/motion.dart';
import '../../core_ui/tokens.dart';
import '../../routing/routes.dart';
import '../capture_import/image_source_picker.dart';

final imageSourcePickerProvider = Provider<ImageSourcePicker>(
  (_) => ImageSourcePicker(),
);

Future<void> showAddEntrySheet(
  BuildContext context, {
  EntryType? preselected,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AddEntrySheet(preselected: preselected),
);

class _AddEntrySheet extends ConsumerStatefulWidget {
  const _AddEntrySheet({this.preselected});

  final EntryType? preselected;

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  late EntryType _type = widget.preselected ?? EntryType.photo;
  bool _busy = false;
  double? _progress;

  Future<void> _capture(CaptureSource source) async {
    final picker = ref.read(imageSourcePickerProvider);
    final picked = await picker.pick(source);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _progress = null;
    });
    final result = await ref
        .read(appGraphProvider)
        .createEntry
        .execute(
          CreateEntryCommand(type: _type, source: picked),
          progress: (done, total) {
            if (mounted && total != null && total > 0) {
              setState(() => _progress = done / total);
            }
          },
        );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    result.fold((entry) {
      Navigator.of(context).pop();
      context.push(Routes.entry(entry.id));
    }, (failure) => showFailureSnack(context, failure));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = EntryTypeStyle.of(_type);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DokkiSpace.lg,
        0,
        DokkiSpace.lg,
        DokkiSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add to vault', style: text.titleLarge),
          const SizedBox(height: DokkiSpace.lg),
          Wrap(
            spacing: DokkiSpace.sm,
            runSpacing: DokkiSpace.sm,
            children: [
              for (final type in EntryType.values)
                ChoiceChip(
                  avatar: Icon(EntryTypeStyle.of(type).icon, size: 16),
                  label: Text(EntryTypeStyle.of(type).label),
                  selected: _type == type,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: DokkiSpace.md),
          AnimatedSwitcher(
            duration: DokkiDuration.fast,
            child: Text(
              style.hint,
              key: ValueKey(_type),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: DokkiSpace.xl),
          // The sheet keeps its footprint while the buttons give way to
          // the progress bar; the height eases rather than jumps.
          AnimatedSize(
            duration: DokkiDuration.normal,
            curve: DokkiCurves.standard,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: DokkiDuration.normal,
              child: _busy
                  ? Column(
                      key: const ValueKey('busy'),
                      children: [
                        LinearProgressIndicator(
                          value: _progress,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: DokkiSpace.md),
                        Text(
                          'Encrypting and saving…',
                          style: text.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('sources'),
                      children: [
                        Expanded(
                          child: _SourceButton(
                            icon: Icons.photo_camera_outlined,
                            label: 'Camera',
                            onTap: () => _capture(CaptureSource.camera),
                          ),
                        ),
                        const SizedBox(width: DokkiSpace.md),
                        Expanded(
                          child: _SourceButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () => _capture(CaptureSource.gallery),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DokkiRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DokkiRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DokkiSpace.xl),
            child: Column(
              children: [
                Icon(icon, size: 28, color: scheme.primary),
                const SizedBox(height: DokkiSpace.sm),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
