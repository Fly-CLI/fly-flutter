import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/operations/result.dart';

void main() {
  group('AppResult', () {
    group('Success', () {
      test('should create success result with data', () {
        final result = AppResult.success('test data');
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.isLoading, isFalse);
        expect(result.data, equals('test data'));
        expect(result.error, isNull);
      });

      test('should work with different data types', () {
        final stringResult = AppResult.success('string');
        final intResult = AppResult.success(42);
        final listResult = AppResult.success([1, 2, 3]);

        expect(stringResult.data, equals('string'));
        expect(intResult.data, equals(42));
        expect(listResult.data, equals([1, 2, 3]));
      });
    });

    group('Failure', () {
      test('should create failure result with message', () {
        final result = AppResult.failure('error message');
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.isLoading, isFalse);
        expect(result.data, isNull);
        expect(result.error, equals('error message'));
      });

      test('should create failure result with message and error', () {
        final exception = Exception('original error');
        final result = AppResult.failure('error message', exception);
        expect(result.error, equals('error message'));
      });
    });

    group('Loading', () {
      test('should create loading result', () {
        final result = AppResult.loading();
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isFalse);
        expect(result.isLoading, isTrue);
        expect(result.data, isNull);
        expect(result.error, isNull);
      });
    });

    group('when', () {
      test('should call success handler for Success', () {
        final result = AppResult.success('data');
        final value = result.when(
          success: (data) => 'success: $data',
          failure: (message, error) => 'failure: $message',
          loading: () => 'loading',
        );
        expect(value, equals('success: data'));
      });

      test('should call failure handler for Failure', () {
        final result = AppResult.failure('error');
        final value = result.when(
          success: (data) => 'success: $data',
          failure: (message, error) => 'failure: $message',
          loading: () => 'loading',
        );
        expect(value, equals('failure: error'));
      });

      test('should call loading handler for Loading', () {
        final result = AppResult.loading();
        final value = result.when(
          success: (data) => 'success: $data',
          failure: (message, error) => 'failure: $message',
          loading: () => 'loading',
        );
        expect(value, equals('loading'));
      });
    });

    group('map', () {
      test('should map Success to new type', () {
        final result = AppResult.success(5);
        final mapped = result.map((data) => data * 2);
        expect(mapped.isSuccess, isTrue);
        expect(mapped.data, equals(10));
      });

      test('should preserve Failure when mapping', () {
        final result = AppResult.failure('error');
        final mapped = result.map((data) => data);
        expect(mapped.isFailure, isTrue);
        expect(mapped.error, equals('error'));
      });

      test('should preserve Loading when mapping', () {
        final result = AppResult.loading();
        final mapped = result.map((data) => data);
        expect(mapped.isLoading, isTrue);
      });
    });

    group('mapError', () {
      test('should map error message for Failure', () {
        final result = AppResult.failure('original error');
        final mapped = result.mapError((message, error) => 'mapped: $message');
        expect(mapped.isFailure, isTrue);
        expect(mapped.error, equals('mapped: original error'));
      });

      test('should preserve Success when mapping error', () {
        final result = AppResult.success('data');
        final mapped = result.mapError((message, error) => 'mapped: $message');
        expect(mapped.isSuccess, isTrue);
        expect(mapped.data, equals('data'));
      });

      test('should preserve Loading when mapping error', () {
        final result = AppResult.loading();
        final mapped = result.mapError((message, error) => 'mapped: $message');
        expect(mapped.isLoading, isTrue);
      });
    });

    group('toString', () {
      test('Success should have readable toString', () {
        final result = AppResult.success('data');
        expect(result.toString(), contains('Success'));
        expect(result.toString(), contains('data'));
      });

      test('Failure should have readable toString', () {
        final result = AppResult.failure('error');
        expect(result.toString(), contains('Failure'));
        expect(result.toString(), contains('error'));
      });

      test('Loading should have readable toString', () {
        final result = AppResult.loading();
        expect(result.toString(), contains('Loading'));
      });
    });
  });
}

