import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/fly_core.dart';

void main() {
  group('ViewState', () {
    test('should create idle state', () {
      const state = ViewState<Object?>.idle();
      expect(state.isIdle, true);
      expect(state.isLoading, false);
      expect(state.isError, false);
      expect(state.isSuccess, false);
    });

    test('should create loading state', () {
      const state = ViewState<Object?>.loading();
      expect(state.isIdle, false);
      expect(state.isLoading, true);
      expect(state.isError, false);
      expect(state.isSuccess, false);
    });

    test('should create error state', () {
      final error = Exception('Test error');
      final state = ViewState<Object?>.error(error);
      expect(state.isIdle, false);
      expect(state.isLoading, false);
      expect(state.isError, true);
      expect(state.isSuccess, false);
      expect(state.error, error);
    });

          test('should create success state', () {
        const data = 'test data';
        const state = ViewState<String>.success(data);
        expect(state.isIdle, false);
        expect(state.isLoading, false);
        expect(state.isError, false);
        expect(state.isSuccess, true);
        expect(state.data, data);
      });

    test('should handle when method', () {
      const state = ViewState<String>.success('test');
      final result = state.when(
        idle: () => 'idle',
        loading: () => 'loading',
        error: (error, stackTrace) => 'error',
        success: (data) => 'success: $data',
      );
      expect(result, 'success: test');
    });

    test('should handle maybeWhen method', () {
      const state = ViewState<Object?>.loading();
      final result = state.maybeWhen(
        loading: () => 'loading',
        orElse: () => 'other',
      );
      expect(result, 'loading');
    });
  });

  group('Result', () {
    test('should create success result', () {
      const result = Result.success('test');
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 'test');
      expect(result.error, null);
    });

    test('should create failure result', () {
      final error = Exception('test error');
      final result = Result<String>.failure(error);
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.data, null);
      expect(result.error, error);
    });

    test('should map success result', () {
      const result = Result.success(42);
      final mapped = result.mapValue((data) => data * 2);
      expect(mapped.isSuccess, true);
      expect(mapped.data, 84);
    });

    test('should map failure result', () {
      final error = Exception('test error');
      final result = Result<int>.failure(error);
      final mapped = result.mapValue((data) => data * 2);
      expect(mapped.isFailure, true);
      expect(mapped.error, error);
    });

    test('should handle when method', () {
      const result = Result<String>.success('test');
      final value = result.when(
        success: (data) => 'success: $data',
        failure: (error, stackTrace) => 'failure: $error',
      );
      expect(value, 'success: test');
    });

    test('should get or else', () {
      final result = Result<String>.failure(Exception('error'));
      final value = result.getOrElse('default');
      expect(value, 'default');
    });

    test('should get or else compute', () {
      final result = Result<String>.failure(Exception('error'));
      final value = result.getOrElseCompute(() => 'computed');
      expect(value, 'computed');
    });
  });

  group('StringExtension', () {
    test('should convert to snake_case', () {
      expect('camelCase'.toSnakeCase, 'camel_case');
      expect('PascalCase'.toSnakeCase, 'pascal_case');
      expect('already_snake_case'.toSnakeCase, 'already_snake_case');
    });

    test('should convert to camelCase', () {
      expect('snake_case'.toCamelCase, 'snakeCase');
      expect('already_camel_case'.toCamelCase, 'alreadyCamelCase');
    });

    test('should convert to PascalCase', () {
      expect('snake_case'.toPascalCase, 'SnakeCase');
      expect('camelCase'.toPascalCase, 'CamelCase');
    });

    test('should capitalize first letter', () {
      expect('hello'.capitalize, 'Hello');
      expect('HELLO'.capitalize, 'HELLO');
      expect(''.capitalize, '');
    });

    test('should validate email', () {
      expect('test@example.com'.isValidEmail, true);
      expect('invalid-email'.isValidEmail, false);
      expect(''.isValidEmail, false);
    });

    test('should validate URL', () {
      expect('https://example.com'.isValidUrl, true);
      expect('http://example.com'.isValidUrl, true);
      expect('invalid-url'.isValidUrl, false);
    });

    test('should truncate string', () {
      expect('hello world'.truncate(5), 'he...');
      expect('hello'.truncate(10), 'hello');
      expect('hello world'.truncate(5, suffix: '***'), 'he***');
    });

    test('should remove whitespace', () {
      expect('hello world'.removeWhitespace, 'helloworld');
      expect('  hello  world  '.removeWhitespace, 'helloworld');
    });
  });

  group('ListExtension', () {
    test('should get first or null', () {
      expect(<int>[].firstOrNull, null);
      expect(<int>[1, 2, 3].firstOrNull, 1);
    });

    test('should get last or null', () {
      expect(<int>[].lastOrNull, null);
      expect(<int>[1, 2, 3].lastOrNull, 3);
    });

    test('should get element at or null', () {
      final list = <int>[1, 2, 3];
      expect(list.elementAtOrNull(0), 1);
      expect(list.elementAtOrNull(2), 3);
      expect(list.elementAtOrNull(3), null);
      expect(list.elementAtOrNull(-1), null);
    });

    test('should add if not contains', () {
      final list = <int>[1, 2, 3];
      list.addIfNotContains(4);
      expect(list, [1, 2, 3, 4]);
      list.addIfNotContains(2);
      expect(list, [1, 2, 3, 4]);
    });

    test('should remove if contains', () {
      final list = <int>[1, 2, 3];
      list.removeIfContains(2);
      expect(list, [1, 3]);
      list.removeIfContains(4);
      expect(list, [1, 3]);
    });

    test('should toggle element', () {
      final list = <int>[1, 2, 3];
      list.toggle(4);
      expect(list, [1, 2, 3, 4]);
      list.toggle(2);
      expect(list, [1, 3, 4]);
    });

    test('should chunk list', () {
      final list = <int>[1, 2, 3, 4, 5];
      final chunks = list.chunk(2);
      expect(chunks, [
        [1, 2],
        [3, 4],
        [5],
      ]);
    });

    test('should get unique elements', () {
      final list = <int>[1, 2, 2, 3, 3, 3];
      final unique = list.unique;
      expect(unique, [1, 2, 3]);
    });
  });

  group('DateTimeExtension', () {
    test('should check if date is today', () {
      final today = DateTime.now();
      expect(today.isToday, true);
      
      final yesterday = today.subtract(const Duration(days: 1));
      expect(yesterday.isToday, false);
    });

    test('should get start of day', () {
      final date = DateTime(2023, 1, 15, 14, 30, 45);
      final startOfDay = date.startOfDay;
      expect(startOfDay.hour, 0);
      expect(startOfDay.minute, 0);
      expect(startOfDay.second, 0);
      expect(startOfDay.millisecond, 0);
    });

    test('should get end of day', () {
      final date = DateTime(2023, 1, 15, 14, 30, 45);
      final endOfDay = date.endOfDay;
      expect(endOfDay.hour, 23);
      expect(endOfDay.minute, 59);
      expect(endOfDay.second, 59);
      expect(endOfDay.millisecond, 999);
    });

    test('should get relative time', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final relativeTime = oneHourAgo.relativeTime;
      expect(relativeTime, '1 hour ago');
    });
  });
}
