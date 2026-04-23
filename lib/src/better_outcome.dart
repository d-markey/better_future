part 'better_outcome_failure.dart';
part 'better_outcome_success.dart';

/// Union class for outcomes: concrete instances can be either [BetterSuccess]
/// or [BetterFailure].
sealed class BetterOutcome<T> {
  BetterOutcome._();

  /// Returns `true` if the operation was successful.
  bool get isSuccess => this is BetterSuccess;

  /// Returns `true` if the operation failed.
  bool get isFailure => this is BetterFailure;

  /// Result of the operation. When [BetterSuccess], returns the value returned
  /// by the operation; when [BetterFailure], throws the exception thrown by
  /// the operation.
  T get result;

  /// Casts the result of an [outcome] to [T].
  BetterOutcome<V> cast<V>();
}

extension OutcomeMapExt<T> on Map<String, BetterOutcome<T>> {
  /// Get succesful entries (key + result).
  Iterable<MapEntry<String, T>> get results => entries
      .where((e) => e.value is BetterSuccess<T>)
      .map((e) => MapEntry(e.key, e.value.result));

  /// Get failed entries (key + error).
  Iterable<MapEntry<String, Object>> get errors => entries
      .where((e) => e.value is BetterFailure<T>)
      .map((e) => MapEntry(e.key, (e.value as BetterFailure<T>).error));

  /// Get succesful entries (key + result).
  Iterable<V> getResults<V>() => entries
      .where((e) => e.value is BetterSuccess)
      .map((e) => e.value.result)
      .whereType<V>();

  /// Get failed entries with stack traces (key + error/stack trace).
  Iterable<MapEntry<String, ({Object error, StackTrace? stackTrace})>>
  get errorsWithStackTrace => entries
      .where((e) => e.value is BetterFailure<T>)
      .map(
        (e) => MapEntry(e.key, (
          error: (e.value as BetterFailure<T>).error,
          stackTrace: (e.value as BetterFailure<T>).stackTrace,
        )),
      );
}
