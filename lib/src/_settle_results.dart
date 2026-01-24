import 'dart:async';

import '_wait_results.dart';
import 'better_outcome.dart';

// Results for [BetterFuture.settle]. Computations return [SettledResult].
class SettledResults extends Results {
  SettledResults(super.computations);

  @override
  Future<T> get<T>(String key) => tasks[key]!.future.then(($) {
    $ as BetterOutcome;
    switch ($) {
      case BetterSuccess():
        return $.result as T;
      case BetterFailure():
        Error.throwWithStackTrace($.error, $.stackTrace ?? StackTrace.current);
    }
  });
}

extension on Symbol {
  static final _pattern = RegExp('Symbol\\("\\\$?([^"]+)=?"\\)');

  String get $name => _pattern.firstMatch(toString())?.group(1) ?? '';
}
