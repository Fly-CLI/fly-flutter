/// Exception classification for retry operations
/// 
/// Defines how exceptions should be handled in retry scenarios.
/// This interface allows custom exception types to be marked as retryable.
abstract class RetryableException {
  /// Whether this exception indicates the operation should be retried
  bool get isRetryable;

  /// Optional message explaining why the operation should/shouldn't be retried
  String? get retryMessage;

  /// The underlying exception
  Object get originalException;
}

/// Default implementation for classifying standard Dart exceptions
class RetryableExceptionClassifier {
  RetryableExceptionClassifier(this.isRetryable, [this.message]);

  final bool isRetryable;
  final String? message;
}

/// Utility class for checking if exceptions are retryable
class RetryableExceptionChecker {
  /// Check if an exception is retryable
  static bool isRetryable(Object exception) {
    // If it implements RetryableException interface, use that
    if (exception is RetryableException) {
      return exception.isRetryable;
    }

    // Check for common retryable exceptions
    return _isStandardRetryable(exception);
  }

  /// Check if a standard exception is retryable
  static bool _isStandardRetryable(Object exception) {
    // Network-related exceptions
    if (exception.toString().contains('SocketException')) return true;
    if (exception.toString().contains('TimeoutException')) return true;
    if (exception.toString().contains('HttpException')) return true;

    // Generic connection errors
    if (exception.toString().contains('Connection refused')) return true;
    if (exception.toString().contains('Connection reset')) return true;
    if (exception.toString().contains('Connection timed out')) return true;
    if (exception.toString().contains('Network is unreachable')) return true;

    // HTTP errors that are typically retryable
    if (exception.toString().contains('504 Gateway Timeout')) return true;
    if (exception.toString().contains('503 Service Unavailable')) return true;
    if (exception.toString().contains('502 Bad Gateway')) return true;
    if (exception.toString().contains('429 Too Many Requests')) return true;

    return false;
  }

  /// Get a human-readable reason for retrying
  static String? getRetryReason(Object exception) {
    if (exception is RetryableException && exception.retryMessage != null) {
      return exception.retryMessage;
    }

    // Return standard reasons
    if (exception.toString().contains('Timeout')) {
      return 'Operation timed out';
    }
    if (exception.toString().contains('Connection')) {
      return 'Network connection issue';
    }
    if (exception.toString().contains('503') || exception.toString().contains('502')) {
      return 'Server temporarily unavailable';
    }
    if (exception.toString().contains('429')) {
      return 'Rate limited, will retry';
    }

    return 'Temporary failure detected';
  }
}

