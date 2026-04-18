import 'package:test/test.dart';

import 'cast_test_suite.dart' as cast_tests;
import 'cleanup_test_suite.dart' as cleanup_tests;
import 'settle_test_suite.dart' as settle_tests;
import 'wait_test_suite.dart' as wait_tests;

void main() {
  group('CAST -', cast_tests.main);
  group('CLEANUP -', cleanup_tests.main);
  group('SETTLE -', settle_tests.main);
  group('WAIT -', wait_tests.main);
}
