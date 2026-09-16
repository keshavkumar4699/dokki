/// A minimal, hand-rolled `Result` type. Four combinators, nothing more.
///
/// Failures are values, not exceptions (§12.1 of the architecture document).
library;

/// The result of an operation that can fail.
///
/// [T] is the success value type, [E] the error type. In this codebase [E]
/// is always [VaultFailure].
sealed class Result<T, E> {
  const Result();

  const factory Result.ok(T value) = Ok<T, E>;

  const factory Result.err(E error) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;

  bool get isErr => this is Err<T, E>;

  /// Returns the success value, or [fallback] when this is an error.
  T getOrElse(T Function(E error) fallback) => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => fallback(error),
  };

  /// Unwraps both sides into a single value.
  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };

  /// Transforms the success value.
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok<R, E>(transform(value)),
    Err(:final error) => Err<R, E>(error),
  };

  /// Transforms the error value.
  Result<T, E2> mapErr<E2>(E2 Function(E error) transform) => switch (this) {
    Ok(:final value) => Ok<T, E2>(value),
    Err(:final error) => Err<T, E2>(transform(error)),
  };

  /// Chains another fallible operation.
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) =>
      switch (this) {
        Ok(:final value) => transform(value),
        Err(:final error) => Err<R, E>(error),
      };

  /// Async variant of [map].
  Future<Result<R, E>> asyncMap<R>(
    Future<R> Function(T value) transform,
  ) async => switch (this) {
    Ok(:final value) => Ok<R, E>(await transform(value)),
    Err(:final error) => Err<R, E>(error),
  };

  /// Async variant of [flatMap].
  Future<Result<R, E>> asyncFlatMap<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async => switch (this) {
    Ok(:final value) => transform(value),
    Err(:final error) => Err<R, E>(error),
  };

  /// The success value, or `null`.
  T? get okOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The error value, or `null`.
  E? get errOrNull => switch (this) {
    Ok() => null,
    Err(:final error) => error,
  };

  @override
  String toString() => switch (this) {
    Ok(:final value) => 'Ok($value)',
    Err(:final error) => 'Err($error)',
  };
}

/// The success case.
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash('Ok', value);
}

/// The failure case.
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;

  @override
  bool operator ==(Object other) => other is Err<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash('Err', error);
}

/// Chaining directly on `Future<Result>` so async pipelines read top-down
/// without an `await` at every step.
extension FutureResultX<T, E> on Future<Result<T, E>> {
  Future<Result<R, E>> map<R>(R Function(T value) transform) async =>
      (await this).map(transform);

  Future<Result<R, E>> flatMap<R>(
    Result<R, E> Function(T value) transform,
  ) async => (await this).flatMap(transform);

  Future<Result<R, E>> asyncMap<R>(
    Future<R> Function(T value) transform,
  ) async => (await this).asyncMap(transform);

  Future<Result<R, E>> asyncFlatMap<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async => (await this).asyncFlatMap(transform);
}

/// Convenience constructors.
Result<T, E> ok<T, E>(T value) => Ok<T, E>(value);

/// Convenience constructors.
Result<T, E> err<T, E>(E error) => Err<T, E>(error);
