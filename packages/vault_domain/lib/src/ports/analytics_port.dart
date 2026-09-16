/// `AnalyticsPort` (§8.5, Phase 9): an allowlist of content-free
/// operational events, so product questions ("how often is rotate used?")
/// are answerable without shipping an SDK.
///
/// NO analytics SDK ships in v1 (§15.9); the default implementation drops
/// every event. Adding a backend later means implementing this port and
/// proving each event is content-free in review — the allowlist is the
/// entire contract, and it carries no identifiers, no titles, no sizes.
library;

enum VaultEvent {
  vaultOpened,
  entryCreated,
  exportCompleted,
  syncCycleCompleted,
  keyRotationCompleted,
}

abstract interface class AnalyticsPort {
  void report(VaultEvent event);
}

/// The v1 backend: drops everything. Documented non-behavior, not an
/// oversight (§15.9 "no analytics SDK in v1").
final class NoopAnalytics implements AnalyticsPort {
  const NoopAnalytics();

  @override
  void report(VaultEvent event) {}
}
