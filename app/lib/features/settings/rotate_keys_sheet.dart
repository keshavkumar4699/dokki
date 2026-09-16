/// The §8.6 key-rotation flow: both factors (PIN + recovery passphrase),
/// then rotate → rewrap → rekey, with honest progress and failure copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/providers.dart';
import '../../core_ui/failure_messages.dart';
import '../../core_ui/tokens.dart';

Future<void> showRotateKeysSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _RotateKeysSheet(),
    );

class _RotateKeysSheet extends ConsumerStatefulWidget {
  const _RotateKeysSheet();

  @override
  ConsumerState<_RotateKeysSheet> createState() => _RotateKeysSheetState();
}

class _RotateKeysSheetState extends ConsumerState<_RotateKeysSheet> {
  final _pin = TextEditingController();
  final _passphrase = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _rotate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(appGraphProvider)
        .rotateKeys(pin: _pin.text, recoveryPassphrase: _passphrase.text);
    if (!mounted) {
      return;
    }
    result.fold((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Keys rotated. Everything is re-wrapped under the new key.',
            ),
          ),
        );
    }, (failure) => setState(() => _error = describeFailure(failure).detail));
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DokkiSpace.lg,
        0,
        DokkiSpace.lg,
        MediaQuery.of(context).viewInsets.bottom + DokkiSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rotate encryption keys', style: text.titleLarge),
          const SizedBox(height: DokkiSpace.xs),
          Text(
            'A new master key is created. Every file is re-wrapped to it '
            '(their contents are not re-encrypted), and the old key stays '
            'readable until the job finishes.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: DokkiSpace.lg),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          const SizedBox(height: DokkiSpace.md),
          TextField(
            controller: _passphrase,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Recovery passphrase',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: DokkiSpace.md),
            Text(
              _error!,
              style: text.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: DokkiSpace.lg),
          FilledButton.icon(
            onPressed: _busy ? null : _rotate,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.vpn_key_outlined),
            label: Text(_busy ? 'Rotating…' : 'Rotate keys'),
          ),
          const SizedBox(height: DokkiSpace.sm),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
