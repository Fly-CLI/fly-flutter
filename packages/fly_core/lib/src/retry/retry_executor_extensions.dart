import 'dart:async';

import 'package:fly_core/src/retry/retry_executor.dart';
import 'package:fly_core/src/retry/retry_policy.dart';
import 'package:fly_core/src/retry/retry_strategy.dart';

/// Extensions for RetryExecutor to support parallel operations
extension RetryExecutorExtensions on RetryExecutor {
  /// Execute multiple operations in parallel with retry
  /// 
  /// Each operation uses its own retry logic. Returns a list of results
  /// where failed operations result in null entries.
  Future<List<T?>> retryAll<T>(
    List<Future<T> Function()> operations, {
    RetryPolicy? policyOverride,
    RetryStrategy? strategyOverride,
  }) async {
    // Create individual executors for each operation
    final executor = policyOverride != null || strategyOverride != null
        ? copyWith(
            policy: policyOverride ?? this.policy,
            strategy: strategyOverride ?? this.strategy,
          )
        : this;

    final results = <T?>[];

    for (int i = 0; i < operations.length; i++) {
      try {
        final result = await executor.execute(operations[i]);
        results.add(result);
      } catch (e) {
        results.add(null);
      }
    }

    return results;
  }

  /// Execute multiple operations in parallel with retry, throwing on failures
  /// 
  /// All operations must succeed or the first failure is thrown.
  Future<List<T>> retryAllOrThrow<T>(
    List<Future<T> Function()> operations, {
    RetryPolicy? policyOverride,
    RetryStrategy? strategyOverride,
  }) async {
    final executor = policyOverride != null || strategyOverride != null
        ? copyWith(
            policy: policyOverride ?? this.policy,
            strategy: strategyOverride ?? this.strategy,
          )
        : this;

    final results = <T>[];

    for (int i = 0; i < operations.length; i++) {
      final result = await executor.execute(operations[i]);
      results.add(result);
    }

    return results;
  }

  /// Execute multiple operations in parallel without retry
  /// 
  /// A simpler version that doesn't apply retry logic to each operation.
  Future<List<T?>> executeAll<T>(
    List<Future<T> Function()> operations,
  ) async {
    final results = await Future.wait(
      operations.map((op) => op().catchError((e) => null)),
    );

    return results;
  }
}

