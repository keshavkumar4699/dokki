/// Public export surface of `vault_sync`: the engine, the merge reducer,
/// the segment sealer, and the queue executor. Zero Google dependencies —
/// the cloud is the domain's `CloudProvider` port (§3, rule 7).
library;

export 'src/error_boundary.dart'
    show SyncException, SegmentRequiresUpgrade;
export 'src/merge_reducer.dart';
export 'src/op_codec.dart';
export 'src/segment_sealer.dart';
export 'src/sync_engine.dart';
export 'src/sync_executor.dart';
