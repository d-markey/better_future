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
