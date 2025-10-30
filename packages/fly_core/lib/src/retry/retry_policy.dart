/// Configuration for retry behavior
/// 
/// Provides default settings and configuration for retry operations
/// across all packages in the Fly CLI ecosystem.
class RetryPolicy {
  /// Creates a retry policy
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.timeout = const Duration(seconds: 30),
    this.enableTimeout = true,
    this.jitterEnabled = false,
  });

  /// Maximum number of attempts (including initial attempt)
  final int maxAttempts;

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Timeout for each individual attempt
  final Duration timeout;

  /// Whether to apply timeout to each attempt
  final bool enableTimeout;

  /// Whether to add random jitter to delays
  final bool jitterEnabled;

  /// Check if this policy allows retries
  bool get allowsRetries => maxAttempts > 1;

  /// Get the effective delay for a given attempt number (0-indexed)
  Duration getDelayForAttempt(int attemptNumber) {
    if (attemptNumber <= 0) return initialDelay;

    // Calculate exponential backoff: initial * multiplier^attemptNumber
    num multiplier = 1;
    for (int i = 0; i < attemptNumber; i++) {
      multiplier *= backoffMultiplier;
    }
    
    final calculatedDelay = Duration(
      milliseconds: (initialDelay.inMilliseconds * multiplier).round(),
    );

    final cappedDelay = calculatedDelay > maxDelay ? maxDelay : calculatedDelay;

    if (jitterEnabled) {
      // Add ±20% jitter
      final jitterRange = (cappedDelay.inMilliseconds * 0.2).round();
      final jitter = (jitterRange * 2 * (0.5 - 0.5)).round(); // TODO: Implement random
      return Duration(milliseconds: cappedDelay.inMilliseconds + jitter);
    }

    return cappedDelay;
  }

  /// Create a copy of this policy with modified values
  RetryPolicy copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    double? backoffMultiplier,
    Duration? maxDelay,
    Duration? timeout,
    bool? enableTimeout,
    bool? jitterEnabled,
  }) {
    return RetryPolicy(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      maxDelay: maxDelay ?? this.maxDelay,
      timeout: timeout ?? this.timeout,
      enableTimeout: enableTimeout ?? this.enableTimeout,
      jitterEnabled: jitterEnabled ?? this.jitterEnabled,
    );
  }

  /// Default retry policy for network operations
  static const network = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 30),
    timeout: Duration(seconds: 30),
    enableTimeout: true,
    jitterEnabled: false,
  );

  /// Default retry policy for quick operations
  static const quick = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 50),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 5),
    timeout: Duration(seconds: 10),
    enableTimeout: true,
    jitterEnabled: false,
  );

  /// Retry policy with no retries (single attempt only)
  static const none = RetryPolicy(
    maxAttempts: 1,
    initialDelay: Duration.zero,
    backoffMultiplier: 1.0,
    maxDelay: Duration.zero,
    timeout: Duration(seconds: 30),
    enableTimeout: true,
    jitterEnabled: false,
  );

  /// Retry policy for aggressive retries
  static const aggressive = RetryPolicy(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 100),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 60),
    timeout: Duration(seconds: 60),
    enableTimeout: true,
    jitterEnabled: true,
  );
}

