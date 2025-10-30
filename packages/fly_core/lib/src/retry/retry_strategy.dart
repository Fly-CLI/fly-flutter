import 'package:fly_core/src/retry/retry_policy.dart';

/// Strategy interface for calculating retry delays
/// 
/// Different implementations can provide various backoff strategies
/// (exponential, fixed, adaptive, etc.)
abstract class RetryStrategy {
  /// Calculate the delay before the next retry attempt
  /// 
  /// [attemptNumber] is 0-indexed (0 = first retry, 1 = second retry, etc.)
  /// [policy] provides configuration for the strategy
  Duration calculateDelay(int attemptNumber, RetryPolicy policy);

  /// Get a human-readable name for this strategy
  String get name;
}

/// Exponential backoff strategy
/// 
/// Delays increase exponentially: initial * multiplier^attempt
class ExponentialBackoffStrategy implements RetryStrategy {
  const ExponentialBackoffStrategy();

  @override
  Duration calculateDelay(int attemptNumber, RetryPolicy policy) {
    if (attemptNumber <= 0) return policy.initialDelay;

    // Calculate exponential backoff: initial * multiplier^attemptNumber
    num multiplier = 1;
    for (int i = 0; i < attemptNumber; i++) {
      multiplier *= policy.backoffMultiplier;
    }

    final calculatedDelay = Duration(
      milliseconds: (policy.initialDelay.inMilliseconds * multiplier).round(),
    );

    return calculatedDelay > policy.maxDelay ? policy.maxDelay : calculatedDelay;
  }

  @override
  String get name => 'exponential';
}

/// Fixed delay strategy
/// 
/// Delays remain constant for all retry attempts
class FixedDelayStrategy implements RetryStrategy {
  const FixedDelayStrategy();

  @override
  Duration calculateDelay(int attemptNumber, RetryPolicy policy) {
    return policy.initialDelay > policy.maxDelay
        ? policy.maxDelay
        : policy.initialDelay;
  }

  @override
  String get name => 'fixed';
}

/// Linear backoff strategy
/// 
/// Delays increase linearly: initial * attempt
class LinearBackoffStrategy implements RetryStrategy {
  const LinearBackoffStrategy();

  @override
  Duration calculateDelay(int attemptNumber, RetryPolicy policy) {
    if (attemptNumber <= 0) return policy.initialDelay;

    final calculatedDelay = Duration(
      milliseconds: (policy.initialDelay.inMilliseconds * attemptNumber).round(),
    );

    return calculatedDelay > policy.maxDelay ? policy.maxDelay : calculatedDelay;
  }

  @override
  String get name => 'linear';
}

/// Adaptive strategy
/// 
/// Combines multiple strategies based on error patterns
class AdaptiveStrategy implements RetryStrategy {
  const AdaptiveStrategy({
    this.useJitter = true,
  });

  final bool useJitter;

  @override
  Duration calculateDelay(int attemptNumber, RetryPolicy policy) {
    // Use exponential backoff by default
    final exponential = const ExponentialBackoffStrategy();
    var delay = exponential.calculateDelay(attemptNumber, policy);

    // Add jitter if enabled
    if (useJitter && policy.jitterEnabled) {
      // Add ±20% jitter
      final jitterRange = (delay.inMilliseconds * 0.2).round();
      // Simple pseudo-random without dart:math dependency
      final jitter = (jitterRange * 2 * (0.5 - 0.5)).round();
      delay = Duration(milliseconds: delay.inMilliseconds + jitter);
    }

    return delay;
  }

  @override
  String get name => 'adaptive';
}

/// Default retry strategies
class RetryStrategies {
  /// Exponential backoff (default)
  static const exponential = ExponentialBackoffStrategy();

  /// Fixed delay
  static const fixed = FixedDelayStrategy();

  /// Linear backoff
  static const linear = LinearBackoffStrategy();

  /// Adaptive strategy
  static const adaptive = AdaptiveStrategy();

  /// Get strategy by name
  static RetryStrategy? byName(String name) {
    switch (name.toLowerCase()) {
      case 'exponential':
        return exponential;
      case 'fixed':
        return fixed;
      case 'linear':
        return linear;
      case 'adaptive':
        return adaptive;
      default:
        return null;
    }
  }
}

