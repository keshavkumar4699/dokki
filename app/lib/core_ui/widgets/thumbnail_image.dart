/// Renders a version's thumbnail from the sealed cache, with a type-tinted
/// placeholder while decrypting and a quiet failure state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_domain/vault_domain.dart';

import '../../bootstrap/providers.dart';
import '../motion.dart';
import '../tokens.dart';

class ThumbnailImage extends ConsumerWidget {
  const ThumbnailImage({
    required this.versionId,
    required this.size,
    this.type,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.standIn,
    super.key,
  });

  final VersionId versionId;
  final ThumbnailSizeClass size;

  /// Drives the placeholder's icon and tint.
  final EntryType? type;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// A smaller size class to show while [size] is still being built — but
  /// only if it is already decrypted (e.g. the grid's cover when opening
  /// the detail screen). Never triggers extra thumbnail work.
  final ThumbnailSizeClass? standIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(
      thumbnailBytesProvider((versionId: versionId, size: size)),
    );
    final scheme = Theme.of(context).colorScheme;
    final style = type == null ? null : EntryTypeStyle.of(type!);
    final tint = style?.tintOn(scheme) ?? scheme.surfaceContainer;

    final standInKey = standIn == null
        ? null
        : (versionId: versionId, size: standIn!);
    final standInBytes =
        standInKey != null && ref.exists(thumbnailBytesProvider(standInKey))
        ? ref.watch(thumbnailBytesProvider(standInKey)).valueOrNull
        : null;

    final child = switch (bytes) {
      AsyncData(:final value) => Image.memory(
        value,
        fit: fit,
        gaplessPlayback: true,
        // Previews are already ≤ the requested edge; never upsample.
      ),
      AsyncError() => _Placeholder(
        tint: tint,
        child: Icon(
          Icons.broken_image_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
      _ when standInBytes != null => Image.memory(
        standInBytes,
        fit: fit,
        gaplessPlayback: true,
      ),
      _ => _Placeholder(tint: tint, child: null),
    };

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: AnimatedSwitcher(
        duration: reduceMotion(context) ? Duration.zero : DokkiDuration.slow,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(bytes.hasValue || standInBytes != null),
          child: child,
        ),
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
