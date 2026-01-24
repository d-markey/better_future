import 'package:better_future/better_future.dart';

void main() async {
  print('--- Basic BetterFuture Example ---');

  final locale = 'fr';

  final results = await BetterFuture.wait({
    // A simple independent computation
    'greeting': () => switch (locale) {
      'fr' => 'Bonjour',
      _ => 'Hello',
    },

    // A computation depending on another result
    'message': ($) async {
      final greeting = await $.greeting<String>();
      return '$greeting BetterFuture!';
    },

    // A task running in parallel
    'timestamp': ($) => DateTime.now(),
  });

  print('Greeting: ${results['greeting']}');
  print('Full Message: ${results['message']}');
  print('Computed at: ${results['timestamp']}');
}
