import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/src/retry/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    test('default policy has correct values', () {
      const policy = RetryPolicy();
      
      expect(policy.maxAttempts, 3);
      expect(policy.initialDelay, const Duration(seconds: 1));
      expect(policy.backoffMultiplier, 2.0);
      expect(policy.maxDelay, const Duration(seconds: 30));
      expect(policy.timeout, const Duration(seconds: 30));
      expect(policy.enableTimeout, true);
      expect(policy.jitterEnabled, false);
    });

    test('allowsRetries returns true for maxAttempts > 1', () {
      const policy = RetryPolicy(maxAttempts: 3);
      expect(policy.allowsRetries, true);
    });

    test('allowsRetries returns false for maxAttempts = 1', () {
      const policy = RetryPolicy(maxAttempts: 1);
      expect(policy.allowsRetries, false);
    });

    test('getDelayForAttempt returns initialDelay for first attempt', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 5),
        maxAttempts: 3,
      );
      expect(policy.getDelayForAttempt(0), const Duration(seconds: 5));
    });

    test('getDelayForAttempt applies exponential backoff', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 2.0,
        maxAttempts: 5,
      );
      
      // First retry (attempt 1)
      expect(policy.getDelayForAttempt(1).inSeconds, closeTo(2, 0.5));
      
      // Second retry (attempt 2)
      expect(policy.getDelayForAttempt(2).inSeconds, closeTo(4, 0.5));
      
      // Third retry (attempt 3)
      expect(policy.getDelayForAttempt(3).inSeconds, closeTo(8, 0.5));
    });

    test('getDelayForAttempt caps at maxDelay', () {
      const policy = RetryPolicy(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 10.0,
        maxDelay: Duration(seconds: 5),
        maxAttempts: 5,
      );
      
      // Should cap at maxDelay
      final delay = policy.getDelayForAttempt(2);
      expect(delay, equals(const Duration(seconds: 5)));
      expect(delay.inSeconds, lessThanOrEqualTo(5));
    });

    test('copyWith creates new policy with modified values', () {
      const original = RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 1),
      );
      
      final modified = original.copyWith(
        maxAttempts: 5,
        initialDelay: const Duration(seconds: 2),
      );
      
      expect(modified.maxAttempts, 5);
      expect(modified.initialDelay, const Duration(seconds: 2));
      expect(modified.backoffMultiplier, original.backoffMultiplier);
    });

    test('default network policy has correct settings', () {
      const policy = RetryPolicy.network;
      
      expect(policy.maxAttempts, 3);
      expect(policy.initialDelay, const Duration(seconds: 1));
      expect(policy.timeout, const Duration(seconds: 30));
    });

    test('default quick policy has shorter delays', () {
      const policy = RetryPolicy.quick;
      
      expect(policy.maxAttempts, 3);
      expect(policy.initialDelay, const Duration(milliseconds: 50));
      expect(policy.maxDelay, const Duration(seconds: 5));
    });

    test('none policy has no retries', () {
      const policy = RetryPolicy.none;
      
      expect(policy.maxAttempts, 1);
      expect(policy.allowsRetries, false);
    });

    test('aggressive policy has more attempts and jitter', () {
      const policy = RetryPolicy.aggressive;
      
      expect(policy.maxAttempts, 5);
      expect(policy.jitterEnabled, true);
    });
  });
}

