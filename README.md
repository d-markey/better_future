# BetterFuture 🚀

`BetterFuture` is a powerful Dart library designed to orchestrate complex asynchronous workflows with ease. It goes beyond `Future.wait` by providing **named results**, **automatic dependency management**, and **natural syntax** for inter-computation communication.

## Key Features ✨

- 📦 **Parallel Execution**: Run multiple asynchronous computations concurrently.
- ⚡ **FutureOr Support**: Mix synchronous values and asynchronous futures seamlessly.
- 🏷️ **Named Results**: Access results by keys instead of positional indices.
- 🔗 **Dependency Injection**: Use the result of one computation in another within the same block.
- 🪄 **Dynamic Syntax**: Access results elegantly using `$.key` or `$.key<T>()`.
- 🛡️ **Type Safety**: Explicit casting support with built-in primitives and custom type registration.
- 🧹 **Automatic Cleanup**: Clean up resources if a parallel task fails.
- ⚡ **Web & WASM Ready**: Fully compatible with JS and WASM compilation targets.
- ⚡ **Error Orchestration**: Choose between eager or lazy failure.

## Installation 📥

Add `better_future` to your `pubspec.yaml`:

```yaml
dependencies:
  better_future: ^1.0.1
```

## Quick Start 🚀

```dart
import 'package:better_future/better_future.dart';

void main() async {
  final results = await BetterFuture.wait({
    // Supports both synchronous values and asynchronous futures (FutureOr)
    'user_id': () => 42,
    
    // A computation depending on 'user_id'
    'profile': ($) async {
      // Notice the dynamic type-safe access using $.key<T>()
      final id = await $.user_id<int>(); 
      return fetchUserProfile(id);
    },
    
    // Another computation running in parallel
    'settings': ($) => fetchSettings(),
  });

  print(results['profile']);
  print(results['settings']);
}
```

### Value Destructuring 🧩

Since `BetterFuture.wait` returns a standard Dart `Map`, you can use Dart 3's powerful map patterns to destructure results immediately:

```dart
final {
  'profile': UserProfile profile, 
  'settings': AppSettings settings,
} = await BetterFuture.wait<dynamic>({
  'profile': ($) => fetchProfile(),
  'settings': ($) => fetchSettings(),
});

// Now use profile and settings directly!
```

## Advanced Usage 🛠️

### Dependency Management with `$`

The `BetterResults` object (conventionally named `$`) allows you to await other computations by their keys. If a computation hasn't finished yet, it will be awaited automatically.

```dart
'b': ($) async {
  final a = await $.a; // Getter syntax (returns dynamic)
  final c = await $.c<double>(); // Method syntax with casting
  return a + c;
}
```

> **Pro Tip 💡**: If your keys are numeric (e.g., `'1'`, `'2'`), you can access them using the `$` prefix: `await $.$1`.

### Automatic Cleanup

When performing operations that require cleanup (like opening a file or a database transaction), `BetterFuture` ensures that if *any* task fails, the successful ones are cleaned up properly.

```dart
final results = await BetterFuture.wait<Resource>(
  {
    'res1': ($) => openResource(1),
    'res2': ($) => throw Exception('Oops!'),
  },
  cleanUp: (res) => res.dispose(), // Called for 'res1' when 'res2' fails
);
```

### Registering Custom Types

To use `$.key<MyCustomType>()`, you need to register the type first:

```dart
BetterFuture.registerType<User>();

// Later...
final user = await $.current_user<User>();
```

### Error Handling

- **Eager (Default `false`)**: Set `eagerError: true` to fail immediately as soon as any computation throws an error.
- **Lazy**: Wait for all computations to finish (or fail) before throwing the first encountered error.

### Getting Detailed Outcomes

BetterFuture also provides `BetterFuture.settle<T>(computations)`.

This static method returns a `Map<String, BetterOutcome<T>>` which holds the final outcome of each computation. Concrete instances of `BetterOutcome<T>` can only be:

* either a `BetterSuccess<T>` instance (successful computation);
* or a `BetterFailure<T>` instance (failed computation).

Keep in mind that `BetterFuture.settle<T>()` will only complete when all computations have completed. It will never complete with an error. But if a computation never completes, `BetterFuture.settle<T>()` will never complete either.

## Best Practices & Considerations ⚠️

### 🔄 Avoid Cyclic Dependencies
Ensure your computations do not have circular dependencies. If computation `A` awaits `B`, and `B` awaits `A`, the orchestration will **deadlock** and never complete. Always design your workflows as a Directed Acyclic Graph (DAG).

### ⚡ Synchronous vs Asynchronous
`BetterFuture` supports both synchronous values and `FutureOr` functions for maximum flexibility. However:
* **Synchronous functions** run immediately when `BetterFuture.wait` is called.
* If a computation is CPU-intensive and implemented synchronously, it will **block the event loop**, potentially causing UI jank.
* **Recommendation**: Use synchronous functions only for lightweight constants or simple state access. For heavy processing, always offload the work to an `async` function.

## Why BetterFuture? 🤔

While standard `Future.wait` is useful for simple parallelization, it falls short in complex real-world scenarios:

*   **Orchestration, Simplified**: If task `B` depends on task `A`, you often have to split your `Future.wait` into multiple stages or nest `await` calls, which can accidentally serialize tasks that could have run in parallel. `BetterFuture` turns your computations into a self-organizing dependency graph.
*   **No More Positional Fragility**: `Future.wait` returns a `List`. If you add a new future to the middle of the list, every index after it changes. `BetterFuture` uses **named keys**, making your code robust and easy to refactor.
*   **Maximum Flexibility**: Handle mixed workloads with ease. Mix synchronous values and asynchronous tasks, manage heterogeneous result types in a single map, and leverage **Dart 3 Map patterns** for clean, declarative destructuring. The library normalizes synchronization automatically.
*   **Unified Reliability**: Managing resource cleanup when one task in a group fails is difficult. `BetterFuture` handles the "rollback" logic for you via the `cleanUp` hook.

## Examples 📚

Check out the `example/` folder for focused demonstrations:
- `main.dart`: Simple quick start.
- `orchestration.dart`: Complex dependency graphs and timing.
- `cleanup.dart`: Resource management and error recovery.
- `destructuring.dart`: Dart 3 Map pattern usage.

---

## Inspiration 💡

This package is a complete rewrite and evolution of the [better-all](https://github.com/shuding/better-all) TypeScript package. It brings a reimagined approach to elegant, object-based asynchronous orchestration for the Flutter and Dart ecosystem.

## Support & Sponsorship ☕

If you find `BetterFuture` useful, consider supporting its development:
- **Sponsor me on GitHub**: [github.com/sponsors/d-markey](https://github.com/sponsors/d-markey)
- Star the repository to help others find it!

Built with ❤️ for better Dart development.
