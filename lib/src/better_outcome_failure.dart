part of 'better_outcome.dart';

/// Class for failed outcomes.
class BetterFailure<T> extends BetterOutcome<T> {
  /// Constructs a failed outcome with [error] and optional [stackTrace].
  BetterFailure(this.error, [this.stackTrace]) : super._();

  /// Error thrown by the operation.
  final Object error;

  /// If available, stack trace where the error occurred.
  final StackTrace? stackTrace;

  /// Result of the operation (will throw [error]).
  @override
  T get result =>
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);

  @override
  BetterOutcome<V> cast<V>() => (V == dynamic || V == T)
      ? this as BetterFailure<V>
      : BetterFailure<V>(error, stackTrace);
}
