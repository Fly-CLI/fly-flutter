import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/error/app_exception.dart';
import 'package:foundation_project/foundation/error/error_handler.dart';

void main() {
  group('Exception Classes', () {
    test('NetworkException should extend AppException', () {
      final exception = NetworkException('Network error');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Network error'));
    });

    test('ValidationException should extend AppException', () {
      final exception = ValidationException('Validation error');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Validation error'));
    });

    test('DatabaseException should extend AppException', () {
      final exception = DatabaseException('Database error');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Database error'));
    });

    test('AuthenticationException should extend AppException', () {
      final exception = AuthenticationException('Auth error');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Auth error'));
    });

    test('PermissionException should extend AppException', () {
      final exception = PermissionException('Permission denied');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Permission denied'));
    });

    test('TimeoutException should extend AppException', () {
      final exception = TimeoutException('Timeout error');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Timeout error'));
    });

    test('exceptions should support optional code and details', () {
      final exception = NetworkException(
        'Network error',
        code: 'NET_001',
        details: {'url': 'https://example.com'},
      );
      expect(exception.code, equals('NET_001'));
      expect(exception.details, equals({'url': 'https://example.com'}));
    });
  });
}

