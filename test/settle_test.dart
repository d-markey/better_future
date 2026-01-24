import 'package:better_future/better_future.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('Empty tasks', () {
    test('- 0 tasks', () async {
      final results = await BetterFuture.settle({});
      expect(results, isEmpty);
    });
  });

  group('Independent tasks', () {
    test('- 3 async tasks', () async {
      final results = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        'b': () => delayed(() => 2),
        'c': () => delayed(() => 3),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 2);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 3);
    });

    test('- 3 sync tasks', () async {
      final results = await BetterFuture.settle({
        'a': () => 1,
        'b': () => 2,
        'c': () => 3,
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 2);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 3);
    });

    test('- 2 async tasks, 1 sync', () async {
      final results = await BetterFuture.settle({
        'a': () => 1,
        'b': () => delayed(() => 2),
        'c': () => delayed(() => 3),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 2);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 3);
    });

    test('- 3 tasks, synchronous error', () async {
      final results = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        'b': () => throwIntended('thrown from b'),
        'c': () => delayed(() => 3),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterFailure>());
      expect(
        (results['b'] as BetterFailure).error,
        isA<ExpectedTestException>(),
      );
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 3);
    });

    test('- 3 tasks, asynchronous error', () async {
      final results = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        'b': () => delayed(() => throwIntended('thrown from b')),
        'c': () => delayed(() => 3),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterFailure>());
      expect(
        (results['b'] as BetterFailure).error,
        isA<ExpectedTestException>(),
      );
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 3);
    });
  });

  group('Dependent tasks', () {
    test('- 3 tasks (one independent), dynamic dependency', () async {
      final results = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        // 'b' depends on 'a' being resolved first.
        'b': ($) => delayed(() async => 2 * await $.a + 1),
        // 'c' depends on 'b'. BetterFuture handles this chain automatically.
        'c': ($) => delayed(() async => 3 * await $.b),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 3);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 9);
    });

    test('- 3 tasks (one synchronous), dynamic dependency', () async {
      final results = await BetterFuture.settle({
        'a': () => 1,
        'b': ($) => delayed(() async => 2 * await $.a + 1),
        'c': ($) => delayed(() async => 3 * await $.b),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 3);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 9);
    });

    test('- 3 tasks (one independent), BetterResult dependency', () async {
      final results = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        'b': (BetterResults $) => delayed(() async => 2 * await $['a'] + 1),
        'c': (BetterResults $) => delayed(() async => 3 * await $['b']),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 3);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 9);
    });

    test('Destructure results', () async {
      final {'a': a, 'b': b, 'c': c} = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        'b': ($) => delayed(() async => 1 + 2 * await $.a),
        'c': ($) => delayed(() async => 3 * await $.b),
      });
      expect(a, isA<BetterSuccess>());
      expect((a as BetterSuccess).result, 1);
      expect(b, isA<BetterSuccess>());
      expect((b as BetterSuccess).result, 3);
      expect(c, isA<BetterSuccess>());
      expect((c as BetterSuccess).result, 9);
    });

    test('Destructure results, mixed types', () async {
      final {
        'a': a,
        'b': b,
        'c': c,
      } = await BetterFuture.settle<
        dynamic /* mandatory for diverse maps to avoid inference as Map<String, Never> or Map<String, Null> */
      >({
        'a': () => delayed(() => 'A'),
        'b': ($) => delayed(() => 1),
        'c': ($) => delayed(() async => await $.b == 1),
      });
      expect(a, isA<BetterSuccess>());
      expect((a as BetterSuccess).result, 'A');
      expect(b, isA<BetterSuccess>());
      expect((b as BetterSuccess).result, 1);
      expect(c, isA<BetterSuccess>());
      expect((c as BetterSuccess).result, true);
    });

    test('- 4 tasks (one synchronous), synchronous error', () async {
      final results = await BetterFuture.settle({
        'a': () => 1,
        'b': (BetterResults $) =>
            delayed(() async => 2 * await $.get<int>('a') + 1),
        'c': ($) => delayed(() async => 3 * await $.b),
        'd': ($) => delayedSync(() => throwIntended('thrown from d')),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 3);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 9);
      expect(results['d'], isA<BetterFailure>());
      expect(
        (results['d'] as BetterFailure).error,
        isA<ExpectedTestException>(),
      );
    });

    test('- 4 tasks (one independent), asynchronous error', () async {
      final results = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        'b': (BetterResults $) =>
            delayed(() async => 2 * await $.get<int>('a') + 1),
        'c': ($) => delayed(() async => 3 * await $.b<int>()),
        'd': ($) => delayed(() => throwIntended('thrown from d')),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterSuccess>());
      expect((results['b'] as BetterSuccess).result, 3);
      expect(results['c'], isA<BetterSuccess>());
      expect((results['c'] as BetterSuccess).result, 9);
      expect(results['d'], isA<BetterFailure>());
      expect(
        (results['d'] as BetterFailure).error,
        isA<ExpectedTestException>(),
      );
    });

    test('- 4 tasks, cascaded error', () async {
      final results = await BetterFuture.settle({
        'a': () => delayed(() => 1),
        'b': ($) => delayed(() async => throwIntended('thrown from b')),
        // will fail because of b
        'c': ($) => delayed(() async => 3 * await $.b<int>()),
        'd': ($) => delayed(() => throwIntended('thrown from d')),
      });
      expect(results['a'], isA<BetterSuccess>());
      expect((results['a'] as BetterSuccess).result, 1);
      expect(results['b'], isA<BetterFailure>());
      expect(results['c'], isA<BetterFailure>());
      expect(
        identical(
          (results['b'] as BetterFailure).error as ExpectedTestException,
          (results['c'] as BetterFailure).error as ExpectedTestException,
        ),
        true,
      );
      expect(results['d'], isA<BetterFailure>());
      expect(
        ((results['d'] as BetterFailure).error as ExpectedTestException)
            .message,
        contains('from d'),
      );
    });
  });
}
