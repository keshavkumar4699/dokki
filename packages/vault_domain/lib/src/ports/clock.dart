/// Determinism ports (§13.2).
///
/// `DateTime.now()`, `Random.secure()`, and `Uuid()` are banned everywhere
/// except the composition root; these three interfaces are how time,
/// identifiers, and randomness enter the system.
library;

/// Source of wall-clock time.
abstract interface class Clock {
  DateTime now();
}

/// Source of identifiers.
///
/// Entities use time-ordered UUIDv7; blobs use UUIDv4.
abstract interface class IdGenerator {
  /// Time-ordered UUIDv7 for entities (entries, assets, versions).
  String newEntityId();

  /// Opaque UUIDv4 for blob names.
  String newBlobId();
}

/// Source of cryptographically secure randomness.
abstract interface class RandomSource {
  /// Fills [out] with random bytes.
  void fillBytes(List<int> out);

  /// Uniform random integer in `[0, max)`.
  int nextInt(int max);
}
