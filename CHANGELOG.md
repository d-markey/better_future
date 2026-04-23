## 2.0.3

- Handle edge case where a settler could complete with a `Future<T>` instead of a `T`.
- Sync/async routes are now handled by completion methods (except for sync errors).

## 2.0.2

- Provide extension methods on `Map<String, BetterOutcome<T>>` for easier access to results and errors.
- Swapped function signature detection to avoid optional argument functions being accepted as no-argument functions.
  - Functions with optional named arguments will be handled as no-argument functions.
  - Functions with required named arguments are not supported.

## 2.0.1

- Improved documentation.

## 2.0.0

- Implemented `BetterFuture.settle`: similar to `BetterFuture.wait`, but returns a map of `BetterOutcome<T>` instead of `T`. Each outcome contains either a computation result or an error. As a result, `BetterFuture.settle` never fails (though it may never complete).

## 1.0.1

- Changed `BetterResults` to an `abstract interface class` for better encapsulation and testing support.
- Improved API documentation for `BetterFuture.wait` with detailed usage examples; also clarified return map behavior and dependency management.

## 1.0.0

- Initial release.
- Features:
  - Parallel execution of asynchronous tasks with `FutureOr` support.
  - Automatic dependency management via the `$` (BetterResults) object.
  - Elegant dynamic syntax for result access (`$.key` and `$.key<T>()`).
  - Robust built-in type casting for primitives, collections, and common core types.
  - Custom type registration for cross-platform type-safe dynamic access.
  - Automatic resource cleanup on orchestration failure via `cleanUp` callback.
  - Full compatibility with VM, Web (JavaScript), and WASM.
  - Optimized for Dart 3 Map destructuring patterns.
