import 'dart:async';

import 'package:better_future/better_future.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('Empty tasks', () {
    test('- 0 tasks', () async {
      final results = await BetterFuture.wait({});
      expect(results, isEmpty);
    });
  });

  group('Independent tasks', () {
    test('- 3 async tasks', () async {
      final results = await BetterFuture.wait({
        'a': () => delayed(() => 1),
        'b': () => delayed(() => 2),
        'c': () => delayed(() => 3),
      });
      expect(results, equals(const {'a': 1, 'b': 2, 'c': 3}));
    });

    test('- 3 sync tasks', () async {
      final results = await BetterFuture.wait({
        'a': () => 1,
        'b': () => 2,
        'c': () => 3,
      });
      expect(results, equals(const {'a': 1, 'b': 2, 'c': 3}));
    });

    test('- 2 async tasks, 1 sync', () async {
      final results = await BetterFuture.wait({
        'a': () => 1,
        'b': () => delayed(() => 2),
        'c': () => delayed(() => 3),
      });
      expect(results, equals(const {'a': 1, 'b': 2, 'c': 3}));
    });

    test('- 3 tasks, synchronous error', () async {
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait({
          'a': () => delayed(() => 1),
          'b': () => throwIntended('thrown from b'),
          'c': () => delayed(() => 3),
        }, cleanUp: cleaned.add);
        throw Exception('Unexpected success: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from b');
        expect(cleaned, allOf(contains(1), contains(3)));
      }
    });

    test('- 3 tasks, asynchronous error', () async {
      // Lazy error handling: we wait for all tasks to complete/fail
      // before returning the first error encountered.
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait({
          'a': () => delayed(() => 1),
          'b': () => delayed(() => throwIntended('thrown from b')),
          'c': () => delayed(() => 3),
        }, cleanUp: cleaned.add);
        throw Exception('Unexpected success: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from b');
        expect(cleaned, allOf(contains(1), contains(3)));
      }
    });

    test('- 3 tasks, synchronous error, eager', () async {
      // Eager error handling: we fail as soon as B throws.
      // However, A and C might still be running in the background.
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait(
          {
            'a': () => delayed(() => 1),
            'b': () => throwIntended('thrown from b'),
            'c': () => delayed(() => 3),
          },
          eagerError: true,
          cleanUp: cleaned.add,
        );
        throw Exception('Unexpected success: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from b');
        // Wait long enough for background tasks A and C to finish
        // and trigger their cleanup callbacks.
        await Future.delayed(Duration(milliseconds: 500));
        expect(cleaned, allOf(contains(1), contains(3)));
      }
    });

    test('- 3 tasks, asynchronous error, eager', () async {
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait(
          {
            'a': () => delayed(() => 1),
            'b': () => delayed(() => throwIntended('thrown from b')),
            'c': () => delayed(() => 3),
          },
          eagerError: true,
          cleanUp: cleaned.add,
        );
        throw Exception('Unexpected success: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from b');
        await Future.delayed(Duration(milliseconds: 500));
        expect(cleaned, allOf(contains(1), contains(3)));
      }
    });
  });

  group('Dependent tasks', () {
    test('- 3 tasks (one independent), dynamic dependency', () async {
      final results = await BetterFuture.wait({
        'a': () => delayed(() => 1),
        // 'b' depends on 'a' being resolved first.
        'b': ($) => delayed(() async => 2 * await $.a + 1),
        // 'c' depends on 'b'. BetterFuture handles this chain automatically.
        'c': ($) => delayed(() async => 3 * await $.b),
      });
      expect(results, equals(const {'a': 1, 'b': 3, 'c': 9}));
    });

    test('- 3 tasks (one synchronous), dynamic dependency', () async {
      final results = await BetterFuture.wait({
        'a': () => 1,
        'b': ($) => delayed(() async => 2 * await $.a + 1),
        'c': ($) => delayed(() async => 3 * await $.b),
      });
      expect(results, equals(const {'a': 1, 'b': 3, 'c': 9}));
    });

    test('- 3 tasks (one independent), BetterResult dependency', () async {
      final results = await BetterFuture.wait({
        'a': () => delayed(() => 1),
        'b': (BetterResults $) => delayed(() async => 2 * await $['a'] + 1),
        'c': (BetterResults $) => delayed(() async => 3 * await $['b']),
      });
      expect(results, equals(const {'a': 1, 'b': 3, 'c': 9}));
    });

    test('Destructure results', () async {
      final {'a': int a, 'b': int b, 'c': int c} = await BetterFuture.wait({
        'a': () => delayed(() => 1),
        'b': ($) => delayed(() async => 1 + 2 * await $.a),
        'c': ($) => delayed(() async => 3 * await $.b),
      });
      expect(a, 1);
      expect(b, 3);
      expect(c, 9);
    });

    test('Destructure results, mixed types', () async {
      final {
        'a': String a,
        'b': int b,
        'c': bool c,
      } = await BetterFuture.wait<
        dynamic /* mandatory for diverse maps to avoid inference as Map<String, Never> or Map<String, Null> */
      >({
        'a': () => delayed(() => 'A'),
        'b': ($) => delayed(() => 1),
        'c': ($) => delayed(() async => await $.b == 1),
      });
      expect(a, 'A');
      expect(b, 1);
      expect(c, true);
    });

    test('- 4 tasks (one synchronous), synchronous error', () async {
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait({
          'a': () => 1,
          'b': (BetterResults $) =>
              delayed(() async => 2 * await $.get<int>('a') + 1),
          'c': ($) => delayed(() async => 3 * await $.b),
          'd': ($) => delayedSync(() => throwIntended('thrown from d')),
        }, cleanUp: cleaned.add);
        throw Exception('Unexpected results: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from d');
        expect(cleaned, allOf(contains(1), contains(3), contains(9)));
      }
    });

    test('- 4 tasks (one independent), asynchronous error', () async {
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait({
          'a': () => delayed(() => 1),
          'b': (BetterResults $) =>
              delayed(() async => 2 * await $.get<int>('a') + 1),
          'c': ($) => delayed(() async => 3 * await $.b<int>()),
          'd': ($) => delayed(() => throwIntended('thrown from d')),
        }, cleanUp: cleaned.add);
        throw Exception('Unexpected results: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from d');
        expect(cleaned, allOf(contains(1), contains(3), contains(9)));
      }
    });

    test('- 4 tasks (one synchronous), synchronous error, eager', () async {
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait(
          {
            'a': () => 1,
            'b': (BetterResults $) =>
                delayed(() async => 2 * await $.get<int>('a') + 1),
            'c': ($) => delayed(() async => 3 * await $.b),
            'd': ($) => delayedSync(() => throwIntended('thrown from d')),
          },
          eagerError: true,
          cleanUp: cleaned.add,
        );
        throw Exception('Unexpected results: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from d');
        await Future.delayed(Duration(milliseconds: 1000));
        expect(cleaned, allOf(contains(1), contains(3), contains(9)));
      }
    });

    test('- 4 tasks (one independent), asynchronous error, eager', () async {
      final cleaned = <int>[];
      try {
        final results = await BetterFuture.wait(
          {
            'a': () => delayed(() => 1),
            'b': (BetterResults $) => delayed(() async => 2 * await $['a'] + 1),
            'c': ($) => delayed(() async => 3 * await $.b),
            'd': ($) => delayed(() => throwIntended('thrown from d')),
          },
          eagerError: true,
          cleanUp: cleaned.add,
        );
        throw Exception('Unexpected results: $results');
      } on ExpectedTestException catch (ex) {
        expect(ex.message, 'thrown from d');
        await Future.delayed(Duration(milliseconds: 500));
        expect(cleaned, allOf(contains(1), contains(3), contains(9)));
      }
    });
  });
}
