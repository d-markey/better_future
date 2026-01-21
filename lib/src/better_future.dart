import 'dart:async';

import 'package:better_future/src/better_results.dart';

import '_results.dart' as impl;
import '_future_casters.dart' as impl;
import '_utils.dart';

/// A utility class for orchestrating complex asynchronous workflows.
///
/// [BetterFuture] allows running multiple computations in parallel,
/// managing their dependencies, and providing a clean, keyed result map.
class BetterFuture {
  BetterFuture._();

  /// Executes multiple [computations] in parallel and returns their results.
  ///
  /// Computations can be:
  /// * Constant values of type [T].
  /// * Functions that return [T] or [Future<T>].
  /// * Functions that take a [BetterResults] argument to depend on other computations.
  ///
  /// If [eagerError] is true, the returned future fails immediately if any
  /// computation throws an error. Otherwise, it waits for all computations
  /// to complete or fail.
  ///
  /// The [cleanUp] callback is invoked for every successful result if the
  /// overall orchestration fails.
  static Future<Map<String, T>> wait<T>(
    Map<String, Function> computations, {
    bool eagerError = false,
    void Function(T)? cleanUp,
  }) async {
    // check computation types
    final workloads = <String, FutureOr Function(BetterResults)>{};
    for (var entry in computations.entries) {
      // == Fallback ==
      // If the strict type check fails, we try wrapping with `dynamic`.
      // This handles cases where the function return type is inferred as `dynamic`
      // or a super-type of `T` (like `num` for `int`).
      // The final `m.cast<String, T>()` will enforce type safety at runtime.
      var invocation = _wrap<T>(entry.value) ?? _wrap<dynamic>(entry.value);
      if (invocation == null) {
        throw UnsupportedError(
          'Unsupported computation signature: ${entry.value.runtimeType}. '
          'Functions must take zero arguments or a single BetterResults/dynamic argument.',
        );
      }
      workloads[entry.key] = invocation;
    }

    // get results
    return impl.Results(
      workloads,
      eagerError: eagerError,
      cleanUp: (cleanUp == null) ? null : ($) => cleanUp($ as T),
    ).future.then((m) => m.cast<String, T>());
  }

  /// Registers a custom type for generic noSuchMethod calls.
  /// This allows using `$.key<T>()` for types other than primitives.
  static void registerType<T>() => impl.registerType<T>();

  static FutureOr Function(BetterResults)? _wrap<T>(Function computation) {
    if (computation.hasNoArguments<T>()) {
      return (BetterResults _) => computation();
    } else if (computation.acceptsBetterResults<T>()) {
      if (computation.acceptsDynamic<T>()) {
        return (BetterResults r) => computation(r as dynamic);
      } else {
        return (BetterResults r) => computation(r);
      }
    }
    return null;
  }
}
