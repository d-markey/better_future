import 'dart:async';

import 'better_results.dart';

/// Casts the result of a [future] to [T].
Future<T> futureCast<T>(Future future) => future.then<T>((v) => v as T);

/// Returns the [Type] object for [T].
Type typeOf<T>() => T;

extension FunctionCheckExt on Function {
  bool hasNoArguments<T>() =>
      this is FutureOr<T> Function() ||
      this is Future<T> Function() ||
      this is T Function();

  bool acceptsBetterResults<T>() =>
      this is FutureOr<T> Function(BetterResults) ||
      this is Future<T> Function(BetterResults) ||
      this is T Function(BetterResults);

  bool acceptsDynamic<T>() =>
      this is FutureOr<T> Function(dynamic) ||
      this is Future<T> Function(dynamic) ||
      this is T Function(dynamic);
}
