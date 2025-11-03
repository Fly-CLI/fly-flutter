import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/fly_core.dart';

void main() {
  group('TimeoutManager', () {
    test('should execute operation successfully within timeout', () async {
      final result = await TimeoutManager.withTimeout(
        () async => Future.value('success'),
        timeout: Duration(seconds: 1),
      );

      expect(result, equals('success'));
    });

    test('should throw TimeoutException when operation exceeds timeout',
        () async {
      await expectLater(
        () => TimeoutManager.withTimeout(
          () async => Future.delayed(Duration(seconds: 2)),
          timeout: Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should include operation name in exception message', () async {
      try {
        await TimeoutManager.withTimeout(
          () async => Future.delayed(Duration(seconds: 2)),
          timeout: Duration(milliseconds: 100),
          operationName: 'test-operation',
        );
        fail('Should have thrown TimeoutException');
      } on TimeoutException catch (e) {
        expect(e.message, contains('test-operation'));
        expect(e.message, contains('timed out'));
        expect(e.duration, equals(Duration(milliseconds: 100)));
      }
    });

    test('should preserve timeout duration in exception', () async {
      try {
        await TimeoutManager.withTimeout(
          () async => Future.delayed(Duration(seconds: 10)),
          timeout: Duration(milliseconds: 100),
          operationName: 'test',
        );
        fail('Should have thrown TimeoutException');
      } on TimeoutException catch (e) {
        expect(e.duration, equals(Duration(milliseconds: 100)));
      }
    });
  });

  group('TimeoutException', () {
    test('should have message and duration', () {
      const exception = TimeoutException('Test timeout', Duration(seconds: 30));

      expect(exception.message, equals('Test timeout'));
      expect(exception.duration, equals(Duration(seconds: 30)));
      expect(exception.toString(), equals('Test timeout'));
    });
  });
}

