import 'dart:math' as math;

import 'package:foundation_project/foundation/error/network_errors.dart';

/// Configuration for retry behavior with exponential backoff
class RetryConfig {
  /// Maximum number of retry attempts (not including the initial attempt)
  final int maxAttempts;

  /// Base delay before first retry
  final Duration baseDelay;

  /// Maximum delay between retries (caps exponential growth)
  final Duration maxDelay;

  /// Multiplier for exponential backoff (typically 2)
  final double backoffMultiplier;

  /// Whether to add jitter to prevent thundering herd
  final bool useJitter;

  /// Maximum jitter factor (0.0 to 1.0)
  /// Actual delay will be multiplied by random value between (1 - jitterFactor) and 1
  final double jitterFactor;

  /// Predicate to determine if an error should be retried
  /// If null, uses NetworkError.isRetryable for NetworkErrors, true for others
  final bool Function(Object error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
    this.jitterFactor = 0.3,
    this.shouldRetry,
  });

  /// Standard retry config for most operations
  /// 3 attempts, exponential backoff starting at 1s, with jitter
  factory RetryConfig.standard() {
    return const RetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 30),
      backoffMultiplier: 2.0,
      useJitter: true,
    );
  }

  /// Aggressive retry for critical operations
  /// More attempts with faster initial retries
  factory RetryConfig.aggressive() {
    return const RetryConfig(
      maxAttempts: 5,
      baseDelay: Duration(milliseconds: 500),
      maxDelay: Duration(seconds: 20),
      backoffMultiplier: 1.5,
      useJitter: true,
    );
  }

  /// Conservative retry for non-critical operations
  /// Fewer attempts with longer delays
  factory RetryConfig.conservative() {
    return const RetryConfig(
      maxAttempts: 2,
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 60),
      backoffMultiplier: 3.0,
      useJitter: true,
    );
  }

  /// No retry - for operations that should fail immediately
  factory RetryConfig.noRetry() {
    return const RetryConfig(
      maxAttempts: 0,
      baseDelay: Duration.zero,
      maxDelay: Duration.zero,
      backoffMultiplier: 1.0,
      useJitter: false,
    );
  }

  /// Quick retry for fast operations
  /// Short delays, good for idempotent operations
  factory RetryConfig.quick() {
    return const RetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(milliseconds: 200),
      maxDelay: Duration(seconds: 5),
      backoffMultiplier: 2.0,
      useJitter: true,
    );
  }

  /// Calculate delay before the next retry attempt
  /// 
  /// Uses exponential backoff formula: baseDelay * (multiplier ^ attempt)
  /// Capped at maxDelay
  /// Optionally adds jitter to prevent thundering herd
  /// 
  /// [attempt] - Zero-based attempt number (0 = first retry, 1 = second retry, etc.)
  Duration calculateDelay(int attempt) {
    if (attempt < 0) {
      return Duration.zero;
    }

    // Calculate exponential delay: baseDelay * (multiplier ^ attempt)
    final exponentialDelay = baseDelay.inMilliseconds *
        math.pow(backoffMultiplier, attempt);

    // Cap at max delay
    var delayMs = math.min(exponentialDelay, maxDelay.inMilliseconds.toDouble());

    // Add jitter if enabled
    if (useJitter && jitterFactor > 0) {
      final random = math.Random();
      // Random factor between (1 - jitterFactor) and 1.0
      // Example: jitterFactor = 0.3 means factor between 0.7 and 1.0
      final factor = (1 - jitterFactor) + (random.nextDouble() * jitterFactor);
      delayMs = delayMs * factor;
    }

    return Duration(milliseconds: delayMs.round());
  }

  /// Check if the given error should be retried
  bool isRetryable(Object error) {
    if (shouldRetry != null) {
      return shouldRetry!(error);
    }

    // Use NetworkError's built-in retry logic
    if (error is NetworkError) {
      return error.isRetryable;
    }

    // Default to retryable for unknown errors (conservative approach)
    return true;
  }

  /// Create a copy with modified parameters
  RetryConfig copyWith({
    int? maxAttempts,
    Duration? baseDelay,
    Duration? maxDelay,
    double? backoffMultiplier,
    bool? useJitter,
    double? jitterFactor,
    bool Function(Object error)? shouldRetry,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      baseDelay: baseDelay ?? this.baseDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      useJitter: useJitter ?? this.useJitter,
      jitterFactor: jitterFactor ?? this.jitterFactor,
      shouldRetry: shouldRetry ?? this.shouldRetry,
    );
  }

  @override
  String toString() {
    return 'RetryConfig('
        'maxAttempts: $maxAttempts, '
        'baseDelay: ${baseDelay.inMilliseconds}ms, '
        'maxDelay: ${maxDelay.inSeconds}s, '
        'multiplier: $backoffMultiplier, '
        'jitter: $useJitter'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetryConfig &&
        other.maxAttempts == maxAttempts &&
        other.baseDelay == baseDelay &&
        other.maxDelay == maxDelay &&
        other.backoffMultiplier == backoffMultiplier &&
        other.useJitter == useJitter &&
        other.jitterFactor == jitterFactor;
  }

  @override
  int get hashCode {
    return Object.hash(
      maxAttempts,
      baseDelay,
      maxDelay,
      backoffMultiplier,
      useJitter,
      jitterFactor,
    );
  }
}

/// Statistics about retry attempts for observability
class RetryStats {
  /// Total number of attempts made (including initial)
  final int totalAttempts;

  /// Number of retry attempts (excluding initial)
  final int retryAttempts;

  /// Total time spent on all attempts including delays
  final Duration totalDuration;

  /// List of delays used between attempts
  final List<Duration> delays;

  /// Whether the operation ultimately succeeded
  final bool succeeded;

  /// Final error if operation failed
  final Object? finalError;

  const RetryStats({
    required this.totalAttempts,
    required this.retryAttempts,
    required this.totalDuration,
    required this.delays,
    required this.succeeded,
    this.finalError,
  });

  @override
  String toString() {
    return 'RetryStats('
        'attempts: $totalAttempts, '
        'retries: $retryAttempts, '
        'duration: ${totalDuration.inMilliseconds}ms, '
        'succeeded: $succeeded'
        ')';
  }
}

