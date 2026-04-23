part of 'better_outcome.dart';

/// Class for successful outcomes.
class BetterSuccess<T> extends BetterOutcome<T> {
  /// Constructs a successful outcome with [result].
  BetterSuccess(this.result) : super._();

  /// Result of the operation.
  @override
  final T result;

  @override
  BetterOutcome<V> cast<V>() => (V == dynamic || V == T)
      ? this as BetterSuccess<V>
      : BetterSuccess<V>(result as V);
}
