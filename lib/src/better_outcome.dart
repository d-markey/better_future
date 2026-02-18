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
}

/// Class for successful outcomes.
class BetterSuccess<T> extends BetterOutcome<T> {
  /// Constructs a successful outcome with [result].
  BetterSuccess(this.result) : super._();

  /// Result of the operation.
  @override
  final T result;
}

/// Class for failed outcomes.
class BetterFailure<T> extends BetterOutcome<T> {
  /// Constructs a failed outcome with [error] and optional [stackTrace].
  BetterFailure(this.error, [this.stackTrace]) : super._();

  /// Error thrown by the operation.
  final Object error;

  /// If available, stack trace where the error occurred.
  final StackTrace? stackTrace;

  /// Result of the operation (will throw).
  @override
  T get result =>
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
}
