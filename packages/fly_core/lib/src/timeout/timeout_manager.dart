import 'dart:async';

import 'package:fly_core/src/retry/retry_executor.dart';

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

