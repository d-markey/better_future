import 'package:better_future/better_future.dart';

/// This example demonstrates using Dart 3 Map Patterns
/// to destructure the results of BetterFuture.wait.

void main() async {
  print('--- Map Destructuring Example ---');

  // Using Dart 3 pattern matching to extract results into local variables
  final {
    'user': String userName,
    'points': int userPoints,
    'is_admin': bool isAdmin,
  } = await BetterFuture.wait<dynamic>({
    'user': ($) async {
      await Future.delayed(Duration(milliseconds: 50));
      return 'Alice';
    },
    'points': ($) => 42,
    'is_admin': ($) => true,
  });

  print('Successfully destructured:');
  print(' - Name: $userName');
  print(' - Points: $userPoints');
  print(' - Administrator: $isAdmin');
}
