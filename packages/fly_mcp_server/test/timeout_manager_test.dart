import 'dart:async';

import 'package:fly_mcp_server/src/timeout_manager.dart';
import 'package:test/test.dart';

void main() {
  group('TimeoutManager', () {
    test('should complete successfully within timeout', () async {
      final result = await TimeoutManager.withTimeout(
        () async => Future.value('success'),
        timeout: const Duration(seconds: 5),
      );
      expect(result, equals('success'));
    });

    test('should throw TimeoutException when operation exceeds timeout',
        () async {
      expect(
        () => TimeoutManager.withTimeout(
          () async {
            await Future.delayed(const Duration(seconds: 2));
            return 'success';
          },
          timeout: const Duration(milliseconds: 100),
          operationName: 'test_op',
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('should include operation name in timeout message', () async {
      try {
        await TimeoutManager.withTimeout(
          () async {
            await Future.delayed(const Duration(seconds: 2));
            return 'success';
          },
          timeout: const Duration(milliseconds: 100),
          operationName: 'my_operation',
        );
        fail('Should have thrown TimeoutException');
      } on TimeoutException catch (e) {
        expect(e.message, contains('my_operation'));
        expect(e.message, contains('timed out'));
      }
    });
  });
}

