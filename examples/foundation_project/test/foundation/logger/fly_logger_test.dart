import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/logger/fly_logger.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('LogLevel', () {
    test('should have correct severity values', () {
      expect(LogLevel.trace.severity, equals(0));
      expect(LogLevel.debug.severity, equals(1));
      expect(LogLevel.info.severity, equals(2));
      expect(LogLevel.warn.severity, equals(3));
      expect(LogLevel.error.severity, equals(4));
      expect(LogLevel.fatal.severity, equals(5));
    });

    test('should have correct labels', () {
      expect(LogLevel.trace.label, equals('TRACE'));
      expect(LogLevel.debug.label, equals('DEBUG'));
      expect(LogLevel.info.label, equals('INFO'));
      expect(LogLevel.warn.label, equals('WARN'));
      expect(LogLevel.error.label, equals('ERROR'));
      expect(LogLevel.fatal.label, equals('FATAL'));
    });

    test('isAtLeast should return true for same or higher severity', () {
      expect(LogLevel.info.isAtLeast(LogLevel.debug), isTrue);
      expect(LogLevel.info.isAtLeast(LogLevel.info), isTrue);
      expect(LogLevel.info.isAtLeast(LogLevel.warn), isFalse);
    });

    test('fromString should parse valid level strings', () {
      expect(LogLevel.fromString('TRACE'), equals(LogLevel.trace));
      expect(LogLevel.fromString('DEBUG'), equals(LogLevel.debug));
      expect(LogLevel.fromString('INFO'), equals(LogLevel.info));
      expect(LogLevel.fromString('WARN'), equals(LogLevel.warn));
      expect(LogLevel.fromString('WARNING'), equals(LogLevel.warn));
      expect(LogLevel.fromString('ERROR'), equals(LogLevel.error));
      expect(LogLevel.fromString('FATAL'), equals(LogLevel.fatal));
    });

    test('fromString should return null for invalid strings', () {
      expect(LogLevel.fromString('INVALID'), isNull);
      expect(LogLevel.fromString(''), isNull);
    });
  });

  group('FlyLoggerImpl', () {
    test('should create logger with name', () {
      final logger = FlyLoggerImpl('TestLogger');
      expect(logger.name, equals('TestLogger'));
    });

    test('should use default minLevel based on debug mode', () {
      final logger = FlyLoggerImpl('TestLogger');
      if (kDebugMode) {
        expect(logger.isEnabled(LogLevel.debug), isTrue);
      } else {
        expect(logger.isEnabled(LogLevel.debug), isFalse);
        expect(logger.isEnabled(LogLevel.info), isTrue);
      }
    });

    test('should use custom minLevel', () {
      final logger = FlyLoggerImpl(
        'TestLogger',
        minLevel: LogLevel.warn,
      );
      expect(logger.isEnabled(LogLevel.info), isFalse);
      expect(logger.isEnabled(LogLevel.warn), isTrue);
      expect(logger.isEnabled(LogLevel.error), isTrue);
    });

    test('should create child logger with inherited context', () {
      final parent = FlyLoggerImpl(
        'Parent',
        contextFields: {'parent': 'value'},
      );
      final child = parent.child({'child': 'value'});
      expect(child.name, equals('Parent'));
      expect(child, isA<FlyLoggerImpl>());
    });

    test('should create logger with fields', () {
      final logger = FlyLoggerImpl('TestLogger');
      final loggerWithFields = logger.withFields({'key': 'value'});
      expect(loggerWithFields, isA<FlyLogger>());
      expect(loggerWithFields.name, equals('TestLogger'));
    });

    test('should log trace messages', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.trace);
      expect(() => logger.trace('Trace message'), returnsNormally);
    });

    test('should log debug messages', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.debug);
      expect(() => logger.debug('Debug message'), returnsNormally);
    });

    test('should log info messages', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.info);
      expect(() => logger.info('Info message'), returnsNormally);
    });

    test('should log warn messages', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.warn);
      expect(() => logger.warn('Warn message'), returnsNormally);
    });

    test('should log error messages', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.error);
      expect(() => logger.error('Error message'), returnsNormally);
    });

    test('should log fatal messages', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.fatal);
      expect(() => logger.fatal('Fatal message'), returnsNormally);
    });

    test('should not log messages below minLevel', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.warn);
      // Should not throw, but message should not be logged
      expect(() => logger.debug('Debug message'), returnsNormally);
      expect(() => logger.info('Info message'), returnsNormally);
    });

    test('should log with structured fields', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.debug);
      expect(
        () => logger.info(
          'Message',
          fields: {'userId': '123', 'action': 'test'},
        ),
        returnsNormally,
      );
    });

    test('should log with error and stackTrace', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.error);
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      expect(
        () => logger.error(
          'Error occurred',
          error: error,
          stackTrace: stackTrace,
        ),
        returnsNormally,
      );
    });

    test('should use error reporter when provided', () {
      final errorReporter = MockErrorReporter();
      final logger = FlyLoggerImpl(
        'TestLogger',
        minLevel: LogLevel.error,
        errorReporter: errorReporter,
      );
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      logger.error('Error message', error: error, stackTrace: stackTrace);

      expect(errorReporter.errors.length, equals(1));
      expect(errorReporter.errors.first, equals(error));
      expect(errorReporter.stackTraces.first, equals(stackTrace));
    });

    test('should not use error reporter for non-error levels', () {
      final errorReporter = MockErrorReporter();
      final logger = FlyLoggerImpl(
        'TestLogger',
        minLevel: LogLevel.debug,
        errorReporter: errorReporter,
      );

      logger.info('Info message');
      logger.warn('Warn message');

      expect(errorReporter.errors.length, equals(0));
    });

    test('should handle lazy message evaluation', () {
      final logger = FlyLoggerImpl('TestLogger', minLevel: LogLevel.debug);
      var evaluated = false;
      final messageBuilder = () {
        evaluated = true;
        return 'Lazy message';
      };

      logger.debug(messageBuilder);
      expect(evaluated, isTrue);
    });

    test('should merge context fields with log fields', () {
      final logger = FlyLoggerImpl(
        'TestLogger',
        contextFields: {'context': 'value'},
        minLevel: LogLevel.debug,
      );
      expect(
        () => logger.debug(
          'Message',
          fields: {'log': 'value'},
        ),
        returnsNormally,
      );
    });
  });

  group('MockFlyLogger', () {
    test('should record log messages', () {
      final logger = MockFlyLogger('TestLogger');
      logger.info('Test message');
      expect(logger.logMessages.length, equals(1));
      expect(logger.logMessages.first, equals('Test message'));
      expect(logger.logLevels.first, equals(LogLevel.info));
    });

    test('should record log levels', () {
      final logger = MockFlyLogger('TestLogger');
      logger.debug('Debug');
      logger.info('Info');
      logger.warn('Warn');
      expect(logger.logLevels, equals([LogLevel.debug, LogLevel.info, LogLevel.warn]));
    });

    test('should record log fields', () {
      final logger = MockFlyLogger('TestLogger');
      logger.info('Message', fields: {'key': 'value'});
      expect(logger.logFields.length, equals(1));
      expect(logger.logFields.first['key'], equals('value'));
    });

    test('should record errors', () {
      final logger = MockFlyLogger('TestLogger');
      final error = Exception('Test error');
      logger.error('Error message', error: error);
      expect(logger.errors.length, equals(1));
      expect(logger.errors.first, equals(error));
    });

    test('should record stack traces', () {
      final logger = MockFlyLogger('TestLogger');
      final stackTrace = StackTrace.current;
      logger.error('Error', stackTrace: stackTrace);
      expect(logger.stackTraces.length, equals(1));
      expect(logger.stackTraces.first, equals(stackTrace));
    });

    test('should create child logger', () {
      final logger = MockFlyLogger('Parent');
      final child = logger.child({'child': 'value'});
      expect(child, isA<MockFlyLogger>());
      expect(child.name, equals('Parent.child'));
    });

    test('clear should reset all recorded data', () {
      final logger = MockFlyLogger('TestLogger');
      logger.info('Message 1');
      logger.error('Error', error: Exception('Error'));

      expect(logger.logMessages.length, equals(2));

      logger.clear();

      expect(logger.logMessages.length, equals(0));
      expect(logger.logLevels.length, equals(0));
      expect(logger.errors.length, equals(0));
    });
  });
}

