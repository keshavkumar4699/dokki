/// Retry policy with full jitter (§9.7).
///
/// Full jitter, not plain exponential backoff: plain backoff makes every
/// device in a rate-limited state retry in lockstep, which is how a 429
/// becomes a sustained 429.
library;

import '../ports/clock.dart';

final class RetryPolicy {
  const RetryPolicy({
    this.base = const Duration(seconds: 2),
    this.cap = const Duration(hours: 6),
    this.maxAttempts = 12,
  });

  final Duration base;
  final Duration cap;
  final int maxAttempts;

  /// `sleep = random(0, min(cap, base * 2^attempt))` — full jitter.
  Duration delayForAttempt(int attempt, RandomSource random) {
    if (attempt < 0) {
      return Duration.zero;
    }
    final shift = attempt < 30 ? 1 << attempt : 1 << 30;
    var ceilingMs = base.inMilliseconds * shift;
    final capMs = cap.inMilliseconds;
    if (ceilingMs <= 0 || ceilingMs > capMs) {
      ceilingMs = capMs;
    }
    final delayMs = random.nextInt(ceilingMs);
    return Duration(milliseconds: delayMs);
  }

  bool hasAttemptsLeft(int attempt) => attempt < maxAttempts;
}
