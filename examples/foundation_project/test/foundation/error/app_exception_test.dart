import 'package:flutter_test/flutter_test.dart';
import 'package:fly_errors/fly_errors.dart';

void main() {
  group('AppException', () {
    test('should create exception with message', () {
      final exception = AppException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.code, isNull);
      expect(exception.details, isNull);
    });

    test('should create exception with message and code', () {
      final exception = AppException('Test error', code: 'ERROR_001');
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('ERROR_001'));
      expect(exception.details, isNull);
    });

    test('should create exception with message, code, and details', () {
      final details = {'field': 'value'};
      final exception = AppException(
        'Test error',
        code: 'ERROR_001',
        details: details,
      );
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('ERROR_001'));
      expect(exception.details, equals(details));
    });

    test('toString should return message', () {
      final exception = AppException('Test error message');
      expect(exception.toString(), equals('Test error message'));
    });

    test('should implement Exception interface', () {
      final exception = AppException('Test error');
      expect(exception, isA<Exception>());
    });
  });
}

