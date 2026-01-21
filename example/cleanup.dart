import 'package:better_future/better_future.dart';

/// This example demonstrates resource cleanup.
/// When one task fails, BetterFuture ensures all successfully completed tasks
/// are cleaned up via the provided `cleanUp` callback.

class DatabaseConnection {
  final String id;
  bool isOpen = true;

  DatabaseConnection(this.id) {
    print('DB $id: Connection opened');
  }

  void close() {
    isOpen = false;
    print('DB $id: Connection closed via cleanup');
  }

  @override
  String toString() => 'DBConnection($id)';
}

void main() async {
  print('--- Resource Cleanup Example ---');

  try {
    await BetterFuture.wait<DatabaseConnection>(
      {
        'conn1': ($) async {
          await Future.delayed(Duration(milliseconds: 100));
          return DatabaseConnection('Primary');
        },
        'conn2': ($) async {
          await Future.delayed(Duration(milliseconds: 200));
          return DatabaseConnection('Secondary');
        },
        'failing_task': ($) async {
          await Future.delayed(Duration(milliseconds: 300));
          print('Failing task: throwing error...');
          throw Exception('Network Timeout');
        },
      },
      eagerError: true,
      cleanUp: (conn) => conn.close(),
    );
  } catch (e) {
    print('Main: Caught expected error -> $e');
  }

  print('Example finished.');
}
