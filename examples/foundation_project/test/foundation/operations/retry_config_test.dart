import 'package:flutter_test/flutter_test.dart';
import 'package:fly_errors/fly_errors.dart';
import 'package:fly_flow_guard/fly_flow_guard.dart';

void main() {
  group('RetryConfig', () {
    test('should create config with default values', () {
      const config = RetryConfig();
      expect(config.maxAttempts, equals(3));
      expect(config.baseDelay, equals(const Duration(seconds: 1)));
      expect(config.maxDelay, equals(const Duration(seconds: 30)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.useJitter, isTrue);
      expect(config.jitterFactor, equals(0.3));
    });

    test('should create config with custom values', () {
      const config = RetryConfig(
        maxAttempts: 5,
        baseDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 60),
        backoffMultiplier: 3.0,
        useJitter: false,
        jitterFactor: 0.5,
      );
      expect(config.maxAttempts, equals(5));
      expect(config.baseDelay, equals(const Duration(seconds: 2)));
      expect(config.maxDelay, equals(const Duration(seconds: 60)));
      expect(config.backoffMultiplier, equals(3.0));
      expect(config.useJitter, isFalse);
      expect(config.jitterFactor, equals(0.5));
    });

    group('factory constructors', () {
      test('standard should create standard config', () {
        final config = RetryConfig.standard();
        expect(config.maxAttempts, equals(3));
        expect(config.baseDelay, equals(const Duration(seconds: 1)));
        expect(config.useJitter, isTrue);
      });

      test('aggressive should create aggressive config', () {
        final config = RetryConfig.aggressive();
        expect(config.maxAttempts, equals(5));
        expect(config.baseDelay, equals(const Duration(milliseconds: 500)));
        expect(config.backoffMultiplier, equals(1.5));
      });

      test('conservative should create conservative config', () {
        final config = RetryConfig.conservative();
        expect(config.maxAttempts, equals(2));
        expect(config.baseDelay, equals(const Duration(seconds: 2)));
        expect(config.backoffMultiplier, equals(3.0));
      });

      test('noRetry should create no-retry config', () {
        final config = RetryConfig.noRetry();
        expect(config.maxAttempts, equals(0));
        expect(config.baseDelay, equals(Duration.zero));
        expect(config.useJitter, isFalse);
      });

      test('quick should create quick config', () {
        final config = RetryConfig.quick();
        expect(config.maxAttempts, equals(3));
        expect(config.baseDelay, equals(const Duration(milliseconds: 200)));
        expect(config.maxDelay, equals(const Duration(seconds: 5)));
      });
    });

    group('calculateDelay', () {
      test('should return zero for negative attempt', () {
        const config = RetryConfig();
        expect(config.calculateDelay(-1), equals(Duration.zero));
      });

      test('should calculate exponential delay', () {
        const config = RetryConfig(
          baseDelay: Duration(seconds: 1),
          backoffMultiplier: 2.0,
          useJitter: false,
        );
        expect(config.calculateDelay(0).inSeconds, equals(1));
        expect(config.calculateDelay(1).inSeconds, equals(2));
        expect(config.calculateDelay(2).inSeconds, equals(4));
        expect(config.calculateDelay(3).inSeconds, equals(8));
      });

      test('should cap delay at maxDelay', () {
        const config = RetryConfig(
          baseDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 5),
          backoffMultiplier: 2.0,
          useJitter: false,
        );
        final delay = config.calculateDelay(10);
        expect(delay.inSeconds, lessThanOrEqualTo(5));
      });

      test('should add jitter when enabled', () {
        const config = RetryConfig(
          baseDelay: Duration(seconds: 10),
          backoffMultiplier: 1.0,
          useJitter: true,
          jitterFactor: 0.3,
        );
        // Run multiple times to verify jitter is applied
        final delays = List.generate(10, (i) => config.calculateDelay(0));
        // All delays should be between 7s and 10s (10 * (1 - 0.3) to 10 * 1.0)
        for (final delay in delays) {
          expect(delay.inSeconds, greaterThanOrEqualTo(7));
          expect(delay.inSeconds, lessThanOrEqualTo(10));
        }
      });
    });

    group('isRetryable', () {
      test('should use custom shouldRetry function when provided', () {
        final config = RetryConfig(
          shouldRetry: (error) => error.toString().contains('retry') && !error.toString().contains('dont'),
        );
        expect(config.isRetryable('retry this'), isTrue);
        expect(config.isRetryable('dont retry'), isFalse);
      });

      test('should use NetworkError.isRetryable for NetworkError', () {
        const config = RetryConfig();
        final retryableError = ConnectionError();
        final nonRetryableError = NoInternetError();
        expect(config.isRetryable(retryableError), isTrue);
        expect(config.isRetryable(nonRetryableError), isFalse);
      });

      test('should return true for unknown errors', () {
        const config = RetryConfig();
        expect(config.isRetryable(Exception('unknown')), isTrue);
      });
    });

    group('copyWith', () {
      test('should create copy with modified values', () {
        const original = RetryConfig(maxAttempts: 3);
        final copy = original.copyWith(maxAttempts: 5);
        expect(copy.maxAttempts, equals(5));
        expect(copy.baseDelay, equals(original.baseDelay));
      });

      test('should preserve original values when not specified', () {
        const original = RetryConfig(
          maxAttempts: 3,
          baseDelay: Duration(seconds: 1),
        );
        final copy = original.copyWith(maxAttempts: 5);
        expect(copy.maxAttempts, equals(5));
        expect(copy.baseDelay, equals(const Duration(seconds: 1)));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        const config1 = RetryConfig(maxAttempts: 3);
        const config2 = RetryConfig(maxAttempts: 3);
        expect(config1, equals(config2));
      });

      test('should not be equal when properties differ', () {
        const config1 = RetryConfig(maxAttempts: 3);
        const config2 = RetryConfig(maxAttempts: 5);
        expect(config1, isNot(equals(config2)));
      });
    });

    group('toString', () {
      test('should include key properties', () {
        const config = RetryConfig(maxAttempts: 3);
        final str = config.toString();
        expect(str, contains('maxAttempts'));
        expect(str, contains('3'));
      });
    });
  });

  group('RetryStats', () {
    test('should create stats with required properties', () {
      const stats = RetryStats(
        totalAttempts: 3,
        retryAttempts: 2,
        totalDuration: Duration(seconds: 5),
        delays: [Duration(seconds: 1), Duration(seconds: 2)],
        succeeded: true,
      );
      expect(stats.totalAttempts, equals(3));
      expect(stats.retryAttempts, equals(2));
      expect(stats.totalDuration, equals(const Duration(seconds: 5)));
      expect(stats.delays.length, equals(2));
      expect(stats.succeeded, isTrue);
      expect(stats.finalError, isNull);
    });

    test('should include finalError when failed', () {
      final error = Exception('error');
      final stats = RetryStats(
        totalAttempts: 3,
        retryAttempts: 2,
        totalDuration: const Duration(seconds: 5),
        delays: const [],
        succeeded: false,
        finalError: error,
      );
      expect(stats.succeeded, isFalse);
      expect(stats.finalError, equals(error));
    });

    test('toString should include key properties', () {
      const stats = RetryStats(
        totalAttempts: 3,
        retryAttempts: 2,
        totalDuration: Duration(seconds: 5),
        delays: [],
        succeeded: true,
      );
      final str = stats.toString();
      expect(str, contains('attempts'));
      expect(str, contains('succeeded'));
    });
  });
}

