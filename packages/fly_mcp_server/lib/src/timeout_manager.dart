import 'dart:async';

/// Manages timeouts for tool execution
class TimeoutManager {
  /// Execute a function with timeout
  static Future<T> withTimeout<T>(
    Future<T> Function() computation, {
    required Duration timeout,
    String? operationName,
  }) async {
    try {
      return await computation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Operation${operationName != null ? ' ($operationName)' : ''} timed out after ${timeout.inSeconds}s',
            timeout,
          );
        },
      );
    } on TimeoutException {
      rethrow;
    }
  }
}

/// Exception thrown when an operation times out
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => message;
}

