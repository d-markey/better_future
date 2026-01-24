import 'dart:async';

import '_future_casters.dart' as impl;
import '_settle_results.dart' as impl;
import '_utils.dart';
import '_wait_results.dart' as impl;
import 'better_outcome.dart';
import 'better_results.dart';

/// A utility class for orchestrating complex asynchronous workflows.
///
/// [BetterFuture] allows running multiple computations in parallel,
/// managing their dependencies, and providing a clean, keyed result map.
class BetterFuture {
  BetterFuture._();

  /// Executes multiple [computations] in parallel and returns their results.
  ///
  /// The results are returned as a map where the keys match those in the
  /// [computations] input.
  ///
  /// The returned future will succeed if all computations complete
  /// successfully. It will fail with the first encountered error if any
  /// computation fails. It could also never complete if computations contain
  /// cyclical dependencies, or if a computation never completes.
  ///
  /// When a computation fails, the future will complete:
  /// * immediately after the first error if [eagerError] is `true` (pending
  /// futures will continue to completion but their outcomes will be ignored);
  /// * after all computations complete if [eagerError] is `false` (the
  /// default);
  /// * or never if a computation never completes!
  ///
  /// When any computation fails and [cleanUp] is provided, it will be called
  /// for all non-`null` successful computation results.
  ///
  /// Computations must be functions that:
  /// * return [T], [Future<T>], or [FutureOr<T>];
  /// * accept 0 arguments (for independent tasks) or 1 argument (for dependent
  /// tasks, in which case the argument must be `dynamic` or a [BetterResults]
  /// object to access results from dependent computations).
  ///
  /// Example:
  /// ```dart
  /// final results = await BetterFuture.wait({
  ///   'users': () => fetchUsers(),
  ///   'stats': ($) async {
  ///     final users = await $.users; // Depends on 'users'
  ///     return calculateStats(users);
  ///   },
  /// });
  /// ```
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
      // This handles cases where the function return type is inferred as
      // `dynamic` or a super-type of `T` (like `num` for `int`).
      // The final `m.cast<String, T>()` will enforce type safety at runtime.
      var invocation = _waiter<T>(entry.value) ?? _waiter<dynamic>(entry.value);
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

  /// Executes multiple [computations] in parallel and returns their outcomes.
  ///
  /// The results are returned as a map where the keys match those in the
  /// [computations] input: they're either a [Success<T>] or a [Failure<T>].
  ///
  /// The returned future will always succeed if all computations complete
  /// (regardless of errors); it could never complete if computations contain
  /// cyclical dependencies, or if a computation never completes.
  ///
  /// Computations must be functions that:
  /// * return [T], [Future<T>], or [FutureOr<T>];
  /// * accept 0 arguments (for independent tasks) or 1 argument (for dependent
  /// tasks, in which case the argument must be `dynamic` or a [BetterResults]
  /// object to access results from dependent computations).
  ///
  /// Example:
  /// ```dart
  /// final outcomes = await BetterFuture.settle({
  ///   'users': () => fetchUsers(),
  ///   'roles': () => fetchRoles(),
  ///   'stats': ($) async {
  ///     final users = await $.users; // Depends on 'users'
  ///     final roles = await $.roles; // Depends on 'roles'
  ///     return calculateStats(users, roles);
  ///   },
  /// });
  /// ```
  static Future<Map<String, BetterOutcome<T>>> settle<T>(
    Map<String, Function> computations,
  ) async {
    // check computation types
    final workloads =
        <String, FutureOr<BetterOutcome> Function(BetterResults)>{};
    for (var entry in computations.entries) {
      // == Fallback ==
      // If the strict type check fails, we try wrapping with `dynamic`.
      // This handles cases where the function return type is inferred as
      // `dynamic` or a super-type of `T` (like `num` for `int`).
      // The final `m.cast<String, T>()` will enforce type safety at runtime.
      var invocation =
          _settler<T>(entry.value) ?? _settler<dynamic>(entry.value);
      if (invocation == null) {
        throw UnsupportedError(
          'Unsupported computation signature: ${entry.value.runtimeType}. '
          'Functions must take zero arguments or a single BetterResults/dynamic argument.',
        );
      }

      workloads[entry.key] = invocation;
    }

    // get results
    return impl.SettledResults(workloads).future.then(
      (m) => Map.fromEntries(
        m.entries.map(
          (e) => MapEntry(e.key, resultCast<T>(e.value as BetterOutcome)),
        ),
      ),
    );
  }

  /// Registers a custom type for generic noSuchMethod calls.
  /// This allows using `$.key<T>()` for types other than primitives.
  static void registerType<T>() => impl.registerType<T>();

  static FutureOr Function(BetterResults)? _waiter<T>(Function computation) {
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

  static FutureOr<BetterOutcome<T>> Function(BetterResults)? _settler<T>(
    Function computation,
  ) {
    final invocation = _waiter<T>(computation);
    if (invocation == null) return null;

    return (BetterResults results) {
      final completer = Completer<BetterOutcome<T>>();
      // completion
      void $complete(dynamic value) {
        if (!completer.isCompleted) {
          completer.complete(BetterSuccess<T>(value));
        }
      }

      void $completeError(Object error, [StackTrace? stackTrace]) {
        if (!completer.isCompleted) {
          completer.complete(BetterFailure<T>(error, stackTrace));
        }
      }

      // start computation
      try {
        final res = invocation(results);
        if (res case Future f) {
          // async route
          f.then($complete, onError: $completeError);
        } else {
          // sync route (no error)
          $complete(res);
        }
      } catch (err, st) {
        // sync route (error)
        $completeError(err, st);
      }

      return completer.future;
    };
  }
}
