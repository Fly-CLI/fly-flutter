import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/src/retry/retry_policy.dart';
import 'package:fly_core/src/retry/retry_strategy.dart';

void main() {
  const policy = RetryPolicy(
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 30),
    maxAttempts: 5,
  );

  group('ExponentialBackoffStrategy', () {
    test('calculates exponential delays correctly', () {
      const strategy = ExponentialBackoffStrategy();
      
      expect(strategy.calculateDelay(0, policy), const Duration(seconds: 1));
      expect(strategy.calculateDelay(1, policy).inSeconds, closeTo(2, 0.5));
      expect(strategy.calculateDelay(2, policy).inSeconds, closeTo(4, 0.5));
      expect(strategy.calculateDelay(3, policy).inSeconds, closeTo(8, 0.5));
    });

    test('caps delays at maxDelay', () {
      const strategy = ExponentialBackoffStrategy();
      const shortMaxDelay = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 10.0,
        maxDelay: Duration(seconds: 5),
        maxAttempts: 5,
      );
      
      expect(strategy.calculateDelay(2, shortMaxDelay).inSeconds, lessThanOrEqualTo(5));
    });

    test('has correct name', () {
      const strategy = ExponentialBackoffStrategy();
      expect(strategy.name, 'exponential');
    });
  });

  group('FixedDelayStrategy', () {
    test('returns same delay for all attempts', () {
      const strategy = FixedDelayStrategy();
      
      final delay1 = strategy.calculateDelay(0, policy);
      final delay2 = strategy.calculateDelay(1, policy);
      final delay3 = strategy.calculateDelay(2, policy);
      
      expect(delay1, equals(delay2));
      expect(delay2, equals(delay3));
    });

    test('returns initialDelay', () {
      const strategy = FixedDelayStrategy();
      expect(strategy.calculateDelay(0, policy), policy.initialDelay);
    });

    test('has correct name', () {
      const strategy = FixedDelayStrategy();
      expect(strategy.name, 'fixed');
    });
  });

  group('LinearBackoffStrategy', () {
    test('calculates linear delays correctly', () {
      const strategy = LinearBackoffStrategy();
      
      expect(strategy.calculateDelay(0, policy).inSeconds, 1);
      expect(strategy.calculateDelay(1, policy).inSeconds, 2);
      expect(strategy.calculateDelay(2, policy).inSeconds, 3);
      expect(strategy.calculateDelay(3, policy).inSeconds, 4);
    });

    test('caps at maxDelay', () {
      const strategy = LinearBackoffStrategy();
      const shortMaxDelay = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 2),
        maxAttempts: 5,
      );
      
      expect(strategy.calculateDelay(3, shortMaxDelay).inSeconds, lessThanOrEqualTo(2));
    });

    test('has correct name', () {
      const strategy = LinearBackoffStrategy();
      expect(strategy.name, 'linear');
    });
  });

  group('AdaptiveStrategy', () {
    test('uses exponential backoff as base', () {
      const strategy = AdaptiveStrategy(useJitter: false);
      
      final delay = strategy.calculateDelay(2, policy);
      expect(delay.inSeconds, greaterThan(1));
      expect(delay.inSeconds, lessThan(30));
    });

    test('has correct name', () {
      const strategy = AdaptiveStrategy();
      expect(strategy.name, 'adaptive');
    });
  });

  group('RetryStrategies', () {
    test('byName returns correct strategies', () {
      expect(RetryStrategies.byName('exponential'), isA<ExponentialBackoffStrategy>());
      expect(RetryStrategies.byName('fixed'), isA<FixedDelayStrategy>());
      expect(RetryStrategies.byName('linear'), isA<LinearBackoffStrategy>());
      expect(RetryStrategies.byName('adaptive'), isA<AdaptiveStrategy>());
    });

    test('byName is case insensitive', () {
      expect(RetryStrategies.byName('EXPONENTIAL'), isA<ExponentialBackoffStrategy>());
      expect(RetryStrategies.byName('Fixed'), isA<FixedDelayStrategy>());
    });

    test('byName returns null for unknown strategy', () {
      expect(RetryStrategies.byName('unknown'), null);
    });
  });
}

