import 'package:flutter_test/flutter_test.dart';
import 'package:fly_logger/fly_logger.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('ErrorReporter', () {
    test('MockErrorReporter should record errors', () {
      final reporter = MockErrorReporter();
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      reporter.recordError(
        error,
        stackTrace,
        reason: 'Test reason',
        customKeys: {'key': 'value'},
      );

      expect(reporter.errors.length, equals(1));
      expect(reporter.errors.first, equals(error));
      expect(reporter.stackTraces.length, equals(1));
      expect(reporter.stackTraces.first, equals(stackTrace));
      expect(reporter.reasons.length, equals(1));
      expect(reporter.reasons.first, equals('Test reason'));
      expect(reporter.customKeys.length, equals(1));
      expect(reporter.customKeys.first, equals({'key': 'value'}));
    });

    test('MockErrorReporter should handle optional parameters', () {
      final reporter = MockErrorReporter();
      final error = Exception('Test error');

      reporter.recordError(error, null);

      expect(reporter.errors.length, equals(1));
      expect(reporter.stackTraces.first, isNull);
      expect(reporter.reasons.first, isNull);
      expect(reporter.customKeys.first, isNull);
    });

    test('MockErrorReporter clear should reset all recorded data', () {
      final reporter = MockErrorReporter();
      reporter.recordError(Exception('Error 1'), null);
      reporter.recordError(Exception('Error 2'), null);

      expect(reporter.errors.length, equals(2));

      reporter.clear();

      expect(reporter.errors.length, equals(0));
      expect(reporter.stackTraces.length, equals(0));
      expect(reporter.reasons.length, equals(0));
      expect(reporter.customKeys.length, equals(0));
    });
  });
}

