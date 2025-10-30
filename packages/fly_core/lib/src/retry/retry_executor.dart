import 'dart:async';

import 'package:fly_core/src/retry/retry_policy.dart';
import 'package:fly_core/src/retry/retry_strategy.dart';
import 'package:fly_core/src/retry/retryable_exception.dart';

/// Main retry execution engine
/// 
/// Executes operations with retry logic according to the provided policy
/// and strategy.
class RetryExecutor {
  /// Creates a retry executor
  const RetryExecutor({
    required this.policy,
    this.strategy = const ExponentialBackoffStrategy(),
    this.onRetry,
    this.onFailure,
    this.customRetryCondition,
  });

  /// The retry policy configuration
  final RetryPolicy policy;

  /// The retry strategy for calculating delays
  final RetryStrategy strategy;

  /// Optional callback when a retry occurs
  final void Function(int attempt, Object error, Duration nextDelay)? onRetry;

  /// Optional callback when all retries are exhausted
  final void Function(int totalAttempts, Object finalError)? onFailure;

  /// Custom condition to determine if an error is retryable
  /// 
  /// If provided, this overrides the default retryable exception checking.
  final bool Function(Object error)? customRetryCondition;

  /// Execute an operation with retry logic
  /// 
  /// Returns the result of the operation if successful.
  /// Throws the last error if all retries are exhausted.
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (!policy.allowsRetries) {
      return _executeWithTimeout(operation);
    }

    final maxRetries = policy.maxAttempts - 1; // Subtract initial attempt
    var attempt = 0;
    Exception? lastException;

    while (attempt < policy.maxAttempts) {
      attempt++;
      try {
        return await _executeWithTimeout(operation);
      } catch (e) {
        lastException = _wrapException(e);

        // Check if we should retry
        if (!_shouldRetry(e, attempt, maxRetries)) {
          if (onFailure != null) {
            onFailure!(attempt, lastException);
          }
          throw lastException;
        }

        // Calculate delay for next attempt (attempt-1 because calculateDelay is 0-indexed)
        final delay = strategy.calculateDelay(attempt - 1, policy);

        if (onRetry != null) {
          onRetry!(attempt, lastException, delay);
        }

        // Wait before retrying (don't wait if this is the last attempt)
        if (attempt < policy.maxAttempts) {
          await Future.delayed(delay);
        }
      }
    }

    // All retries exhausted
    if (onFailure != null && lastException != null) {
      onFailure!(policy.maxAttempts, lastException!);
    }
    throw lastException ?? Exception('Retry operation failed after ${policy.maxAttempts} attempts');
  }

  /// Execute an operation with optional timeout
  Future<T> _executeWithTimeout<T>(Future<T> Function() operation) async {
    if (policy.enableTimeout) {
      return await operation().timeout(
        policy.timeout,
        onTimeout: () => throw TimeoutException(
          'Operation timed out after ${policy.timeout.inSeconds}s',
          policy.timeout,
        ),
      );
    }
    return await operation();
  }

  /// Check if an error should be retried
  bool _shouldRetry(Object error, int currentAttempt, int maxRetries) {
    // Don't retry if we've exceeded max attempts
    if (currentAttempt > maxRetries) {
      return false;
    }

    // Use custom condition if provided
    if (customRetryCondition != null) {
      return customRetryCondition!(error);
    }

    // Use default retryable exception checker
    return RetryableExceptionChecker.isRetryable(error);
  }

  /// Wrap an error in an exception if needed
  Exception _wrapException(Object error) {
    if (error is Exception) {
      return error;
    }
    return Exception(error.toString());
  }

  /// Create a copy of this executor with modified configuration
  RetryExecutor copyWith({
    RetryPolicy? policy,
    RetryStrategy? strategy,
    void Function(int, Object, Duration)? onRetry,
    void Function(int, Object)? onFailure,
    bool Function(Object)? customRetryCondition,
  }) {
    return RetryExecutor(
      policy: policy ?? this.policy,
      strategy: strategy ?? this.strategy,
      onRetry: onRetry ?? this.onRetry,
      onFailure: onFailure ?? this.onFailure,
      customRetryCondition: customRetryCondition ?? this.customRetryCondition,
    );
  }

  /// Create an executor with default configuration
  factory RetryExecutor.defaults() {
    return const RetryExecutor(
      policy: RetryPolicy.network,
      strategy: RetryStrategies.exponential,
    );
  }

  /// Create an executor for quick operations
  factory RetryExecutor.quick() {
    return const RetryExecutor(
      policy: RetryPolicy.quick,
      strategy: RetryStrategies.exponential,
    );
  }

  /// Create an executor with no retries
  factory RetryExecutor.noRetries() {
    return const RetryExecutor(
      policy: RetryPolicy.none,
      strategy: RetryStrategies.fixed,
    );
  }

  /// Create an executor with aggressive retries
  factory RetryExecutor.aggressive() {
    return const RetryExecutor(
      policy: RetryPolicy.aggressive,
      strategy: RetryStrategies.adaptive,
    );
  }
}

/// Timeout exception with timeout duration
class TimeoutException implements Exception {
  const TimeoutException(this.message, this.duration);

  final String message;
  final Duration duration;

  @override
  String toString() => message;
}

