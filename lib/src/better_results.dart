/// An interface for accessing the results of parallel computations.
///
/// In a [BetterFuture.wait] block, the `$` object implements this interface.
/// It allows computations to depend on each other by awaiting their keys.
abstract interface class BetterResults {
  BetterResults._();

  /// Resolves the result of the computation matching [key].
  ///
  /// If the computation for [key] has not finished yet, it will be awaited.
  Future<dynamic> operator [](String key);

  /// Resolves and casts the result of the computation matching [key].
  ///
  /// This is equivalent to `results[key].then((v) => v as T)`.
  Future<T> get<T>(String key);

  /// **Dynamic Access**
  ///
  /// `BetterResults` supports dynamic access via `noSuchMethod`.
  ///
  /// You can access results using getters:
  /// ```dart
  /// final a = await $.my_key;
  /// ```
  ///
  /// Or using methods for type-safe casting:
  /// ```dart
  /// final b = await $.my_key<int>();
  /// ```
  ///
  /// Common primitive types and collections are supported out of the box.
  /// For custom types, use [BetterFuture.registerType].
  @override
  dynamic noSuchMethod(Invocation invocation);
}
