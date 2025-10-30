import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/src/retry/retry_executor.dart';
import 'package:fly_core/src/retry/retry_policy.dart';
import 'package:fly_core/src/retry/retry_strategy.dart';

void main() {
  group('RetryExecutor', () {
    test('succeeds on first attempt', () async {
      final executor = RetryExecutor.defaults();
      var callCount = 0;

      final result = await executor.execute(() async {
        callCount++;
        return 'success';
      });

      expect(result, 'success');
      expect(callCount, 1);
    });

    test('retries on failure and eventually succeeds', () async {
      final executor = RetryExecutor.defaults();
      var attemptCount = 0;

      final result = await executor.execute(() async {
        attemptCount++;
        if (attemptCount < 3) {
          throw Exception('SocketException: Connection failed');
        }
        return 'success';
      });

      expect(result, 'success');
      expect(attemptCount, 3);
    });

    test('throws after max attempts exhausted', () async {
      final executor = RetryExecutor.defaults();
      var attemptCount = 0;

      expect(
        () async => await executor.execute(() async {
          attemptCount++;
          throw Exception('SocketException: Connection failed');
        }),
        throwsException,
      );

      expect(attemptCount, 3); // maxAttempts
    });

    test('respects maxAttempts limit', () async {
      final policy = const RetryPolicy(maxAttempts: 2);
      final executor = RetryExecutor(
        policy: policy,
        strategy: const ExponentialBackoffStrategy(),
      );
      var attemptCount = 0;

      expect(
        () async => await executor.execute(() async {
          attemptCount++;
          throw Exception('SocketException: Connection failed');
        }),
        throwsException,
      );

      expect(attemptCount, 2); // Only 2 attempts
    });

    test('applies timeout to operations', () async {
      final policy = const RetryPolicy(
        maxAttempts: 2,
        timeout: Duration(milliseconds: 100),
        enableTimeout: true,
      );
      final executor = RetryExecutor(
        policy: policy,
        strategy: const ExponentialBackoffStrategy(),
      );

      expect(
        () async => await executor.execute(() async {
          await Future.delayed(const Duration(milliseconds: 200));
          return 'success';
        }),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('does not timeout when disabled', () async {
      final policy = const RetryPolicy(
        maxAttempts: 1,
        timeout: Duration(milliseconds: 1),
        enableTimeout: false,
      );
      final executor = RetryExecutor(
        policy: policy,
        strategy: const ExponentialBackoffStrategy(),
      );

      final result = await executor.execute(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'success';
      });

      expect(result, 'success');
    });

    test('calls onRetry callback', () async {
      var retryCalls = 0;
      var attemptNumbers = <int>[];

      final executor = RetryExecutor(
        policy: const RetryPolicy(maxAttempts: 3),
        strategy: const ExponentialBackoffStrategy(),
        onRetry: (attempt, error, delay) {
          retryCalls++;
          attemptNumbers.add(attempt);
        },
      );

      try {
        await executor.execute(() async {
          throw Exception('SocketException: Connection failed');
        });
      } catch (e) {
        // Expected
      }

      expect(retryCalls, 2); // 2 retries
      expect(attemptNumbers, [1, 2]);
    });

    test('calls onFailure callback', () async {
      var failureCalled = false;
      var totalAttempts = 0;

      final executor = RetryExecutor(
        policy: const RetryPolicy(maxAttempts: 2),
        strategy: const ExponentialBackoffStrategy(),
        onFailure: (attempts, error) {
          failureCalled = true;
          totalAttempts = attempts;
        },
      );

      try {
        await executor.execute(() async {
          throw Exception('SocketException: Connection failed');
        });
      } catch (e) {
        // Expected
      }

      expect(failureCalled, true);
      expect(totalAttempts, 2);
    });

    test('uses custom retry condition', () async {
      var attempts = 0;

      final executor = RetryExecutor(
        policy: const RetryPolicy(maxAttempts: 3),
        strategy: const ExponentialBackoffStrategy(),
        customRetryCondition: (error) {
          // Only retry on specific error
          return error.toString().contains('Retry me');
        },
      );

      expect(
        () async => await executor.execute(() async {
          attempts++;
          throw Exception('Do not retry me');
        }),
        throwsException,
      );

      expect(attempts, 1); // No retries because condition was false
    });

    test('waits between retry attempts', () async {
      final policy = const RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 50),
      );
      final executor = RetryExecutor(
        policy: policy,
        strategy: const ExponentialBackoffStrategy(),
      );

      final stopwatch = Stopwatch()..start();
      
      try {
        await executor.execute(() async {
          throw Exception('SocketException: Connection failed');
        });
      } catch (e) {
        // Expected
      }
      
      stopwatch.stop();

      // Should have waited for retries (2 retries with delays)
      expect(stopwatch.elapsedMilliseconds, greaterThan(50));
    });

    test('noRetries factory creates executor with no retries', () {
      final executor = RetryExecutor.noRetries();
      expect(executor.policy.maxAttempts, 1);
      expect(executor.policy.allowsRetries, false);
    });

    test('defaults factory creates executor with default policy', () {
      final executor = RetryExecutor.defaults();
      expect(executor.policy, RetryPolicy.network);
    });

    test('quick factory creates executor with quick policy', () {
      final executor = RetryExecutor.quick();
      expect(executor.policy, RetryPolicy.quick);
    });

    test('aggressive factory creates executor with aggressive policy', () {
      final executor = RetryExecutor.aggressive();
      expect(executor.policy, RetryPolicy.aggressive);
    });

    test('copyWith creates new executor with modified config', () {
      final original = RetryExecutor.defaults();
      final modified = original.copyWith(
        policy: const RetryPolicy(maxAttempts: 5),
      );

      expect(modified.policy.maxAttempts, 5);
      expect(modified.strategy, original.strategy);
    });

    group('TimeoutException', () {
      test('includes timeout message and duration', () {
        const exception = TimeoutException('Test timeout', Duration(seconds: 5));
        
        expect(exception.message, 'Test timeout');
        expect(exception.duration, const Duration(seconds: 5));
        expect(exception.toString(), 'Test timeout');
      });
    });
  });
}

