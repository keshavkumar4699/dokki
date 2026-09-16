/// Retention policy: a pure function choosing which versions may be
/// evicted (§10.2). Replaceable via DI — the number 3 appears in exactly
/// one place, as a constructor default.
library;

import '../ids.dart';
import 'pin_set.dart';
import 'version_graph.dart';

abstract interface class VersionRetentionPolicy {
  /// Pure. No I/O. Returns the set of version ids whose binaries may be
  /// evicted. Must never include the original, the current version, or any
  /// pinned version.
  Set<VersionId> selectEvictable(VersionGraph graph, PinSet pins);
}

/// Keep the original, the current version, the newest `historyDepth`
/// derived versions, and everything pinned.
final class KeepOriginalCurrentAndNPolicy implements VersionRetentionPolicy {
  const KeepOriginalCurrentAndNPolicy({this.historyDepth = 3});

  final int historyDepth;

  @override
  Set<VersionId> selectEvictable(VersionGraph graph, PinSet pins) {
    final protected = <VersionId>{
      graph.original.id,
      graph.currentId,
      ...pins.pinned,
    };
    final candidates = graph.materializedDerived
        .where((v) => !protected.contains(v.id))
        .toList(growable: false);
    return candidates.skip(historyDepth).map((v) => v.id).toSet();
  }
}
