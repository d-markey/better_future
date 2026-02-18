import 'dart:math';

import 'package:better_future/better_future.dart';

/// This example demonstrates complex orchestration with inter-dependent tasks,
/// random delays, and simulated failures.
/// It shows how BetterFuture handles the dependency graph automatically.

final rnd = Random();
final sw = Stopwatch();
int maxDelay = 0;

void report(String message) {
  final delta = sw.elapsed.inMilliseconds - maxDelay;
  print(
    '[${sw.elapsed}] maxDelay = $maxDelay ms (${delta > 0 ? '+$delta' : '$delta'} ms)',
  );
  print('[${sw.elapsed}] $message');
}

void main() async {
  try {
    final workloads = {
      'L': () => 'L', // independent sync task
      'O': () => compute('O'), // independent async task
      '1': ($) async {
        // Depends on L and O
        final l = await $.L<String>();
        final o = await $.O;
        return 'HE${l * 2}$o';
      },
      '2': ($) async {
        // Depends on O and L
        return 'W${await $.O}R${await $.L}D';
      },
      'final_result': (BetterResults $) async {
        // Depends on results 1 and 2
        return '${await $['1']} ${await $['2']}';
      },
    };

    void $cleanup(String res) {
      print('[${sw.elapsed}] cleaning up: $res');
    }

    sw.start();

    final results = await BetterFuture.wait(
      workloads,
      eagerError: true,
      cleanUp: $cleanup,
    );

    report('Result Map: $results');
    print('Final String: ${results['final_result']}');
  } catch (ex) {
    report('Caught expected error: $ex');
  }
}

Future<String> compute(String id) async {
  final delay = 100 + rnd.nextInt(1000);
  maxDelay = max(maxDelay, delay);

  print('[${sw.elapsed}] Task $id: starting (delay: $delay ms)');
  await Future.delayed(Duration(milliseconds: delay));

  return id;
}
