/// A value that must never appear in logs or error messages.
///
/// `toString()` returns `***`. Wrapping key material, IDs, and byte arrays
/// makes an accidental `log('$blob')` print a redaction instead of a secret
/// (§8.5).
library;

final class SensitiveValue<T> {
  const SensitiveValue(this.value);

  final T value;

  @override
  String toString() => '***';

  @override
  bool operator ==(Object other) =>
      other is SensitiveValue<T> && other.value == value;

  @override
  int get hashCode => Object.hash(T, value);
}

/// A sensitive byte array.
typedef SensitiveBytes = SensitiveValue<List<int>>;
