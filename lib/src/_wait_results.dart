import 'dart:async';

import '_computation.dart';
import '_future_casters.dart';
import 'better_results.dart';

// Results for [BetterFuture.wait].
class Results implements BetterResults {
  Results(
    Map<String, FutureOr Function(BetterResults)> computations, {
    bool eagerError = false,
    void Function(Object)? cleanUp,
  }) : _eagerError = eagerError {
    if (computations.isEmpty) {
      // done already
      _done();
    } else {
      // initialize computations
      for (var entry in computations.entries) {
        _pending++;
        tasks[entry.key] = Computation(
          entry.key,
          entry.value,
          cleanUp,
          _progress,
        );
      }
      // start computations
      for (var computation in tasks.values) {
        computation.compute(this);
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.$name;
    if (invocation.isGetter) {
      return get(name);
    }

    if (invocation.isMethod &&
        invocation.namedArguments.isEmpty &&
        invocation.positionalArguments.isEmpty) {
      final types = invocation.typeArguments;
      if (types.isEmpty) {
        return get(name);
      } else if (types.length == 1) {
        return reify(get(name), types[0]);
      }
    }
    return super.noSuchMethod(invocation);
  }

  final bool _eagerError;
  int _pending = 0;

  final tasks = <String, Computation>{};
  final _completer = Completer<Map<String, Object?>>();
  Future<Map<String, Object?>> get future => _completer.future;

  // failure
  void _fail(Object error, StackTrace? stackTrace) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
      for (var computation in tasks.values) {
        computation.cleanup();
      }
    }
  }

  // done
  void _done() {
    if (!_completer.isCompleted) {
      final firstError = tasks.values.where((c) => c.isFailure).firstOrNull;
      if (firstError == null) {
        _completer.complete(tasks.map((k, c) => MapEntry(k, c.result)));
      } else {
        _fail(firstError.error!, firstError.stackTrace);
      }
    }
  }

  void _progress(Computation computation) {
    _pending--;
    if ((computation.isFailure && _eagerError) ||
        (_pending == 0 && !_completer.isCompleted)) {
      _done();
    }
  }

  @override
  Future<dynamic> operator [](String key) => get(key);

  @override
  Future<T> get<T>(String key) => tasks[key]!.future.then(($) => $ as T);
}

extension on Symbol {
  static final _pattern = RegExp('Symbol\\("\\\$?([^"]+)=?"\\)');

  String get $name => _pattern.firstMatch(toString())?.group(1) ?? '';
}
