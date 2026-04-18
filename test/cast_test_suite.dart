import 'dart:async';
import 'package:better_future/better_future.dart';
import 'package:test/test.dart';

void main() {
  test('dynamic cast test', () async {
    final results = await BetterFuture.wait({
      'a': ($) => 42,
      'b': ($) async {
        // This is what the user wants to do:
        final val = await $.a<int>();
        return val + 1;
      },
    });

    expect(results['b'], equals(43));
  });

  test('strict type test', () async {
    await BetterFuture.wait({
      'a': ($) => 42,
      'b': ($) async {
        // This should fail if it returns Future<dynamic> and we expect Future<int>.
        // This validates that our reification logic correctly produces a Future<int>.
        Future<int> f = $.a<int>();
        int val = await f;
        return val + 1;
      },
    });
  });

  test('custom type registration test', () async {
    // We must register non-primitive types if we want to use the $.key<T>() syntax,
    // as noSuchMethod cannot reflect on the type argument without help in some environments.
    BetterFuture.registerType<User>();

    final results = await BetterFuture.wait({
      'a': ($) => User(name: 'Alice'),
      'b': ($) async {
        // Should return Future<User>
        Future<User> f = $.a<User>();
        final user = await f;
        return user.name;
      },
    });

    expect(results['b'], equals('Alice'));
  });

  test('num inference test', () async {
    // Validates the fallback mechanism in BetterFuture.wait that handles cases where
    // Dart infers a super-type (like 'num') for an 'int' result.
    final results = await BetterFuture.wait<int>({
      'a': ($) => (42 as num), // statically num
    });
    expect(results['a'], equals(42));
  });

  test('dynamic inference test', () async {
    final results = await BetterFuture.wait<int>({
      'a': ($) => (42 as dynamic), // dynamic
    });
    expect(results['a'], equals(42));
  });

  test('mixed types inference test', () async {
    final results = await BetterFuture.wait({
      'a': ($) => 42,
      'b': ($) => 'hello',
    });

    expect(results['a'], equals(42));
    expect(results['b'], equals('hello'));
  });

  test('explicit Never test', () async {
    // If the user specifies <Never>, but the computation returns something else,
    // it should throw a TypeError when the final results map is cast.
    expect(
      () => BetterFuture.wait<Never>({'a': ($) => 42}),
      throwsA(isA<TypeError>()),
    );
  });

  test('cleanUp inference and type error', () async {
    // If cleanUp expects String, T becomes String
    final future = BetterFuture.wait({'a': ($) => 42}, cleanUp: (String s) {});

    // This throws TypeError because it tries to cast the Map<String, dynamic>
    // to Map<String, String> at the end.
    await expectLater(future, throwsA(isA<TypeError>()));
  });
}

class User {
  final String name;
  User({required this.name});
}
