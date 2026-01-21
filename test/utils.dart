import 'dart:async';
import 'dart:math';

final rnd = Random();

Future<T> delayed<T>(FutureOr<T> Function() res) {
  final delay = 50 * rnd.nextInt(10);
  return Future.delayed(Duration(milliseconds: delay), () => res());
}

T delayedSync<T>(T Function() res) {
  final delay = 50 * rnd.nextInt(10);
  final sw = Stopwatch()..start();
  while (sw.elapsedMilliseconds < delay) {
    for (var i = 0; i < 10000; i++) {
      /* cpu delay */
    }
  }
  return res();
}

class ExpectedTestException implements Exception {
  ExpectedTestException(this.message);
  final String message;
}

Never throwIntended(String message) => throw ExpectedTestException(message);
