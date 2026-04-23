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
  Object? _result;
  Object? error;
  StackTrace? stackTrace;

  final _completer = Completer<void>();

  Object? get result {
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

  bool get isSuccess => _completer.isCompleted && (error == null);
  bool get isFailure => _completer.isCompleted && (error != null);

  void run(Results results) {
    // completion
    void $completeError(Object error, [StackTrace? stackTrace]) {
      if (!_completer.isCompleted) {
        this.error = error;
        this.stackTrace = stackTrace;
        _completer.complete();
        _progress(this);
      }
    }

    void $complete(FutureOr value) {
      if (value case Future f) {
        f.then($complete, onError: $completeError);
      } else if (!_completer.isCompleted) {
        _result = value;
        _completer.complete();
        _progress(this);
      }
    }

    // start computation
    try {
      $complete(_pending = _start(results));
    } catch (err, st) {
      $completeError(err, st);
    }
  }

  Future<Object?> get future {
    final pending = _pending;
    return (pending is Future<Object?>) ? pending : Future.value(pending);
  }

  void cleanup() {
    if (_cleanup == null || error != null) {
      // no cleanup provided, or completed with an error: nothing to do
    } else if (!_completer.isCompleted) {
      // not completed yet: ensure cleanup on completion
      _completer.future.whenComplete(cleanup);
    } else if (_result case Object res) {
      // completed and non-null result: cleanup
      _cleanup(res);
    }
  }
}
