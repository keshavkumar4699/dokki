/// Renders a version's thumbnail from the sealed cache, with a type-tinted
/// placeholder while decrypting and a quiet failure state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../tokens.dart';

class ThumbnailImage extends ConsumerWidget {
  const ThumbnailImage({
    required this.versionId,
    required this.size,
    this.type,
    this.fit = BoxFit.cover,
    this.borderRadius,
    super.key,
  });

  final VersionId versionId;
  final ThumbnailSizeClass size;

  /// Drives the placeholder's icon and tint.
  final EntryType? type;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(
      thumbnailBytesProvider((versionId: versionId, size: size)),
    );
    final scheme = Theme.of(context).colorScheme;
    final style = type == null ? null : EntryTypeStyle.of(type!);
    final tint = style?.tintOn(scheme) ?? scheme.surfaceContainer;

    final child = bytes.when(
      data: (data) => Image.memory(
        data,
        fit: fit,
        gaplessPlayback: true,

        // Previews are already ≤ the requested edge; never upsample.
      ),
      loading: () => _Placeholder(tint: tint, child: null),
      error: (_, _) => _Placeholder(
        tint: tint,
        child: Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: AnimatedSwitcher(
        duration: DokkiDuration.normal,
        child: KeyedSubtree(key: ValueKey(bytes.hasValue), child: child),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.tint, required this.child});

  final Color tint;
  final Widget? child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: tint,
    child: Center(child: child),
  );
}
