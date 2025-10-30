import 'dart:async';

import 'package:fly_mcp_server/src/concurrency_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('ConcurrencyLimiter', () {
    test('should allow operations within limit', () async {
      final limiter = ConcurrencyLimiter(maxConcurrency: 2);
      
      expect(limiter.canStart('tool1'), isTrue);
      expect(limiter.canStart('tool2'), isTrue);
    });

    test('should reject operations exceeding global limit', () async {
      final limiter = ConcurrencyLimiter(maxConcurrency: 1);
      
      expect(limiter.canStart('tool1'), isTrue);
      limiter.start('tool1');
      expect(limiter.canStart('tool2'), isFalse);
      
      limiter.complete('tool1');
      expect(limiter.canStart('tool2'), isTrue);
    });

    test('should enforce per-tool limits', () async {
      final limiter = ConcurrencyLimiter(
        maxConcurrency: 10,
        perToolLimits: {'tool1': 2},
      );
      
      expect(limiter.canStart('tool1'), isTrue);
      limiter.start('tool1');
      expect(limiter.canStart('tool1'), isTrue);
      limiter.start('tool1');
      expect(limiter.canStart('tool1'), isFalse); // Exceeded per-tool limit
      
      // Other tools should still work
      expect(limiter.canStart('tool2'), isTrue);
    });

    test('should execute operations with limiting', () async {
      final limiter = ConcurrencyLimiter(maxConcurrency: 1);
      
      final result = await limiter.execute(
        'tool1',
        () async => Future.value('success'),
      );
      
      expect(result, equals('success'));
    });

    test('should throw ConcurrencyLimitException when limit exceeded',
        () async {
      final limiter = ConcurrencyLimiter(maxConcurrency: 1);
      
      // Start first operation
      limiter.start('tool1');
      
      // Try to start second operation
      expect(
        () => limiter.execute(
          'tool2',
          () async => Future.value('success'),
        ),
        throwsA(isA<ConcurrencyLimitException>()),
      );
      
      // Cleanup
      limiter.complete('tool1');
    });

    test('should track current concurrency correctly', () async {
      final limiter = ConcurrencyLimiter(maxConcurrency: 5);
      
      expect(limiter.currentConcurrency, equals(0));
      
      limiter.start('tool1');
      expect(limiter.currentConcurrency, equals(1));
      expect(limiter.getToolConcurrency('tool1'), equals(1));
      
      limiter.start('tool2');
      expect(limiter.currentConcurrency, equals(2));
      
      limiter.complete('tool1');
      expect(limiter.currentConcurrency, equals(1));
      expect(limiter.getToolConcurrency('tool1'), equals(0));
    });
  });
}

