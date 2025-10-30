import 'dart:async';

/// Cancellation token for long-running operations
class CancellationToken {
  final Completer<void> _completer = Completer<void>();
  bool _isCancelled = false;

  /// Whether cancellation was requested
  bool get isCancelled => _isCancelled;

  /// Request cancellation
  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  /// Wait for cancellation (completes immediately if already cancelled)
  Future<void> get onCancel => _completer.future;

  /// Throw if cancellation was requested
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancellationException('Operation was cancelled');
    }
  }
}

/// Exception thrown when an operation is cancelled
class CancellationException implements Exception {
  final String message;
  CancellationException(this.message);
  
  @override
  String toString() => message;
}

/// Registry for active cancellable operations
class CancellationRegistry {
  final Map<Object, CancellationToken> _tokens = {};

  /// Register a cancellation token for a request ID
  void register(Object requestId, CancellationToken token) {
    _tokens[requestId] = token;
  }

  /// Cancel a request by ID
  void cancel(Object requestId) {
    _tokens[requestId]?.cancel();
    _tokens.remove(requestId);
  }

  /// Get cancellation token for a request
  CancellationToken? getToken(Object requestId) => _tokens[requestId];

  /// Remove token after operation completes
  void remove(Object requestId) {
    _tokens.remove(requestId);
  }
}

