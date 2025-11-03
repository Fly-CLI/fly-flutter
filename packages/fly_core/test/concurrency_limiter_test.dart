import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/fly_core.dart';

void main() {
  group('ConcurrencyLimiter', () {
    late ConcurrencyLimiter limiter;

    setUp(() {
      limiter = ConcurrencyLimiter(maxConcurrency: 2);
    });

    test('should allow operations within limit', () {
      expect(limiter.canStart('tool1'), isTrue);
      limiter.start('tool1');
      expect(limiter.canStart('tool2'), isTrue);
      limiter.start('tool2');
      expect(limiter.canStart('tool3'), isFalse);
    });

    test('should track current concurrency', () {
      expect(limiter.currentConcurrency, equals(0));
      limiter.start('tool1');
      expect(limiter.currentConcurrency, equals(1));
      limiter.start('tool2');
      expect(limiter.currentConcurrency, equals(2));
      limiter.complete('tool1');
      expect(limiter.currentConcurrency, equals(1));
    });

    test('should track per-tool concurrency', () {
      limiter.start('tool1');
      limiter.start('tool1');
      expect(limiter.getToolConcurrency('tool1'), equals(2));
      expect(limiter.getToolConcurrency('tool2'), equals(0));
    });

    test('should enforce per-tool limits', () {
      final limiter = ConcurrencyLimiter(
        maxConcurrency: 10,
        perToolLimits: {'tool1': 2},
      );

      expect(limiter.canStart('tool1'), isTrue);
      limiter.start('tool1');
      expect(limiter.canStart('tool1'), isTrue);
      limiter.start('tool1');
      expect(limiter.canStart('tool1'), isFalse);
      expect(limiter.canStart('tool2'), isTrue);
    });

    test('should execute with concurrency limiting', () async {
      var executed = 0;
      await limiter.execute('tool1', () async {
        executed++;
        return executed;
      });
      expect(executed, equals(1));
    });

    test('should throw exception when limit exceeded', () {
      limiter.start('tool1');
      limiter.start('tool2');
      expect(
        () => limiter.execute('tool3', () async => 1),
        throwsA(isA<ConcurrencyLimitException>()),
      );
    });

    test('should complete operations and free up slots', () {
      limiter.start('tool1');
      limiter.start('tool2');
      expect(limiter.canStart('tool3'), isFalse);
      limiter.complete('tool1');
      expect(limiter.canStart('tool3'), isTrue);
    });

    test('should handle multiple complete calls gracefully', () {
      limiter.start('tool1');
      limiter.complete('tool1');
      expect(() => limiter.complete('tool1'), returnsNormally);
      expect(limiter.getToolConcurrency('tool1'), equals(0));
    });

    test('should remove tool from tracking when concurrency reaches zero', () {
      limiter.start('tool1');
      expect(limiter.getToolConcurrency('tool1'), equals(1));
      limiter.complete('tool1');
      expect(limiter.getToolConcurrency('tool1'), equals(0));
    });
  });

  group('ConcurrencyLimitException', () {
    test('should contain error information', () {
      final exception = ConcurrencyLimitException(
        'Limit exceeded',
        toolName: 'tool1',
        current: 5,
        limit: 3,
      );

      expect(exception.message, equals('Limit exceeded'));
      expect(exception.toolName, equals('tool1'));
      expect(exception.current, equals(5));
      expect(exception.limit, equals(3));
      expect(exception.toString(), equals('Limit exceeded'));
    });
  });
}

