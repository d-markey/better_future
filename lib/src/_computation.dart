import 'dart:async';

import '_wait_results.dart';
import 'better_results.dart';

class Computation {
  Computation(this.id, this._start, this._cleanup, this._progress);

  final String id;
  late final FutureOr Function(BetterResults) _start;

  final void Function(Object)? _cleanup;
  final void Function(Computation) _progress;

  FutureOr? _pending;
  dynamic _result;
  Object? error;
  StackTrace? stackTrace;

  dynamic get result {
    if (!_completer.isCompleted) {
      // too early: not completed yet
      throw StateError('Asynchronous computation is still pending.');
    } else if (error != null) {
      // failed
      Error.throwWithStackTrace(error!, stackTrace ?? StackTrace.current);
    } else {
      // success
      return _result;
    }
  }

  final _completer = Completer<void>();

  bool get isSuccess => _completer.isCompleted && (error == null);
  bool get isFailure => _completer.isCompleted && (error != null);

  void compute(Results results) {
    // completion
    void $complete(dynamic value) {
      if (!_completer.isCompleted) {
        _result = value;
        _completer.complete();
        _progress(this);
      }
    }

    void $completeError(Object error, [StackTrace? stackTrace]) {
      if (!_completer.isCompleted) {
        this.error = error;
        this.stackTrace = stackTrace;
        _completer.complete();
        _progress(this);
      }
    }

    // start computation
    try {
      final res = _pending = _start(results);
      if (res case Future f) {
        // async route
        f.then($complete, onError: $completeError);
      } else {
        // sync route (no error)
        $complete(res);
      }
    } catch (err, st) {
      // sync route (error)
      $completeError(err, st);
    }
  }

  Future get future {
    final pending = _pending;
    return (pending is Future) ? pending : Future.value(pending);
  }

  void cleanup() {
    if (_cleanup == null || error != null) {
      // completed with an error: nothing to do
    } else if (!_completer.isCompleted) {
      // not completed yet: ensure cleanup on completion
      _completer.future.whenComplete(cleanup);
    } else if (_result != null) {
      // completed and non-null result: cleanup
      _cleanup(_result);
    }
  }
}
