sealed class BetterOutcome<T> {
  BetterOutcome._();

  bool get isSuccess => this is BetterSuccess;
  bool get isFailure => this is BetterFailure;

  T get result;
}

class BetterSuccess<T> extends BetterOutcome<T> {
  BetterSuccess(this.result) : super._();

  @override
  final T result;

  V get<V extends T>() => result as V;
}

class BetterFailure<T> extends BetterOutcome<T> {
  BetterFailure(this.error, [this.stackTrace]) : super._();

  final Object error;
  final StackTrace? stackTrace;

  @override
  T get result =>
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
}
