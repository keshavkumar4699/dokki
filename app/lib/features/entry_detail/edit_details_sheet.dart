/// Title / note / tags editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/tokens.dart';

Future<void> showEditDetailsSheet(BuildContext context, VaultEntry entry) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditDetailsSheet(entry: entry),
    );

class _EditDetailsSheet extends ConsumerStatefulWidget {
  const _EditDetailsSheet({required this.entry});

  final VaultEntry entry;

  @override
  ConsumerState<_EditDetailsSheet> createState() => _EditDetailsSheetState();
}

class _EditDetailsSheetState extends ConsumerState<_EditDetailsSheet> {
  late final _title = TextEditingController(text: widget.entry.title ?? '');
  late final _note = TextEditingController(text: widget.entry.note ?? '');
  late final _tags = TextEditingController(text: widget.entry.tags.join(', '));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(appGraphProvider)
        .updateEntryDetails
        .execute(
          widget.entry.id,
          title: _title.text,
          note: _note.text,
          tags: _tags.text.split(',').map((t) => t.trim()).toList(),
        );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    result.fold(
      (_) => Navigator.of(context).pop(),
      (failure) => showFailureSnack(context, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DokkiSpace.lg,
        0,
        DokkiSpace.lg,
        DokkiSpace.xl + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: DokkiSpace.lg),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
            autofocus: true,
          ),
          const SizedBox(height: DokkiSpace.md),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: DokkiSpace.md),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
              labelText: 'Tags',
              helperText: 'Separate with commas',
            ),
          ),
          const SizedBox(height: DokkiSpace.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
