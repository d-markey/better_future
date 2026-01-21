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
