import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fly_errors/fly_errors.dart';

import '../test_helpers/mocks.dart';

void main() {
  group('ErrorMessageFormatter', () {
    late MockFlyLogger mockLogger;
    late ErrorMessageFormatter formatter;

    setUp(() {
      mockLogger = MockFlyLogger();
      formatter = ErrorMessageFormatter(logger: mockLogger);
    });

    group('format', () {
      test('should format ValidationException using registry', () {
        final error = ValidationException('Invalid input');
        final formatted = formatter.format(error);
        expect(formatted, equals('Invalid input'));
        expect(mockLogger.logMessages.length, greaterThan(0));
      });

      test('should format NetworkException using registry', () {
        final error = NetworkException('Network error');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
        expect(formatted, isNot(equals('Network error')));
      });

      test('should format DatabaseException using registry', () {
        final error = DatabaseException('Database error');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should format AuthenticationException using registry', () {
        final error = AuthenticationException('Auth error');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should format PermissionException using registry', () {
        final error = PermissionException('Permission denied');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should format TimeoutException using registry', () {
        final error = TimeoutException('Timeout error');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should format SocketException', () {
        final error = SocketException('Connection failed');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should format TimeoutException (dart:async)', () {
        final error = TimeoutException('Operation timed out');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should format FileSystemException', () {
        final error = FileSystemException('File error', 'path/to/file');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should format FormatException', () {
        final error = const FormatException('Invalid format');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
      });

      test('should use custom localizations when provided', () {
        final customLocalizations = MockFoundationLocalizationProvider();
        final error = NetworkException('Network error');
        final formatted =
            formatter.format(error, localizations: customLocalizations);
        expect(formatted,
            equals(customLocalizations.networkErrorConnectionRecovery));
      });

      test('should not log error when logError is false', () {
        final error = ValidationException('Test error');
        mockLogger.clear();
        formatter.format(error, logError: false);
        expect(mockLogger.logMessages.isEmpty, isTrue);
      });

      test('should handle unregistered AppException with meaningful message',
          () {
        final error = AppException('User-friendly error message');
        final formatted = formatter.format(error);
        expect(formatted, equals('User-friendly error message'));
      });

      test('should handle unregistered AppException with technical message',
          () {
        final error = AppException('Exception: TechnicalError');
        final formatted = formatter.format(error);
        expect(formatted, isNotEmpty);
        expect(formatted, isNot(equals('Exception: TechnicalError')));
      });
    });

    group('isNetworkError', () {
      test('should return true for SocketException', () {
        final error = SocketException('Connection failed');
        expect(formatter.isNetworkError(error), isTrue);
      });

      test('should return true for NetworkException', () {
        final error = NetworkException('Network error');
        expect(formatter.isNetworkError(error), isTrue);
      });

      test('should return true for error string containing network', () {
        final error = 'Network connection failed';
        expect(formatter.isNetworkError(error), isTrue);
      });

      test('should return false for non-network errors', () {
        final error = ValidationException('Validation error');
        expect(formatter.isNetworkError(error), isFalse);
      });
    });

    group('isDatabaseError', () {
      test('should return true for DatabaseException', () {
        final error = DatabaseException('Database error');
        expect(formatter.isDatabaseError(error), isTrue);
      });

      test('should return true for error string containing database', () {
        final error = 'Database connection failed';
        expect(formatter.isDatabaseError(error), isTrue);
      });

      test('should return false for non-database errors', () {
        final error = NetworkException('Network error');
        expect(formatter.isDatabaseError(error), isFalse);
      });
    });

    group('isTimeoutError', () {
      test('should return true for TimeoutException', () {
        final error = TimeoutException('Operation timed out');
        expect(formatter.isTimeoutError(error), isTrue);
      });

      test('should return true for error string containing timeout', () {
        const error = 'Operation timed out';
        expect(formatter.isTimeoutError(error), isTrue);
      });

      test('should return false for non-timeout errors', () {
        final error = NetworkException('Network error');
        expect(formatter.isTimeoutError(error), isFalse);
      });
    });
  });
}
