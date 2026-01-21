import 'dart:async';
import 'package:better_future/better_future.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('cleanup is called on eager failure', () async {
    final cleanedUp = <int>[];
    final future = BetterFuture.wait<int>(
      {
        'a': ($) async {
          await Future.delayed(Duration(milliseconds: 10));
          return 42;
        },
        'b': ($) async {
          await Future.delayed(Duration(milliseconds: 30));
          throwIntended('abort');
        },
      },
      eagerError: true,
      cleanUp: (val) => cleanedUp.add(val),
    );

    await expectLater(future, throwsA(isA<ExpectedTestException>()));
    // Give a tiny bit of time for the cleanup to process if needed,
    // though in this implementation it's immediate.
    expect(cleanedUp, contains(42));
  });

  test('cleanup is called on lazy failure', () async {
    final cleanedUp = <int>[];
    final future = BetterFuture.wait<int>(
      {
        'a': ($) async {
          await Future.delayed(Duration(milliseconds: 10));
          return 42;
        },
        'b': ($) async {
          await Future.delayed(Duration(milliseconds: 30));
          throwIntended('abort');
        },
      },
      eagerError: false,
      cleanUp: (val) => cleanedUp.add(val),
    );

    // Should wait for both to finish (approx 30ms)
    await expectLater(future, throwsA(isA<ExpectedTestException>()));
    expect(cleanedUp, contains(42));
  });

  test('cleanup is called for slow success after lazy failure', () async {
    final cleanedUp = <int>[];
    final future = BetterFuture.wait<int>(
      {
        'a': ($) async {
          // Slower than the error
          await Future.delayed(Duration(milliseconds: 50));
          return 42;
        },
        'b': ($) async {
          await Future.delayed(Duration(milliseconds: 10));
          throwIntended('abort');
        },
      },
      eagerError: false,
      cleanUp: (val) => cleanedUp.add(val),
    );

    await expectLater(future, throwsA(isA<ExpectedTestException>()));
    // In lazy mode, we wait for A to finish before returning the error from B.
    // So 42 should already be in cleanedUp.
    expect(cleanedUp, contains(42));
  });

  test('cleanup is called for slow success after eager failure', () async {
    final cleanedUp = <int>[];
    final future = BetterFuture.wait<int>(
      {
        'a': ($) async {
          // Much slower than the error in B
          await Future.delayed(Duration(milliseconds: 50));
          return 42;
        },
        'b': ($) async {
          await Future.delayed(Duration(milliseconds: 10));
          throwIntended('abort');
        },
      },
      eagerError: true,
      cleanUp: (val) => cleanedUp.add(val),
    );

    // Should fail quickly (approx 10ms)
    await expectLater(future, throwsA(isA<ExpectedTestException>()));

    // At this point, 'a' hasn't finished yet, so cleanedUp should be empty
    expect(cleanedUp, isEmpty);

    // Wait for 'a' to finish
    await Future.delayed(Duration(milliseconds: 100));

    // Now cleanedUp should contain 42 because BetterFuture registered
    // a cleanup listener on the pending future.
    expect(cleanedUp, contains(42));
  });
}
