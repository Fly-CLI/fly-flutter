import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_networking/fly_networking.dart';

void main() {
  group('ApiResponse', () {
    test('should create success response', () {
      const response = ApiResponse.success('test data');
      expect(response.isSuccess, true);
      expect(response.isFailure, false);
      expect(response.data, 'test data');
      expect(response.error, null);
    });

    test('should create failure response', () {
      const error = ApiError.network(message: 'Network error');
      const response = ApiResponse.failure(error);
      expect(response.isSuccess, false);
      expect(response.isFailure, true);
      expect(response.data, null);
      expect(response.error, error);
    });

    test('should map success response', () {
      const response = ApiResponse.success(42);
      final mapped = response.mapData<int>((data) => data * 2);
      expect(mapped.isSuccess, true);
      expect(mapped.data, 84);
    });

    test('should map failure response', () {
      const error = ApiError.network(message: 'Network error');
      const response = ApiResponse.success(42);
      final mapped = response.mapData<int>((data) => data * 2);
      expect(mapped.isSuccess, true);
      expect(mapped.data, 84);
    });

    test('should handle when method', () {
      const response = ApiResponse.success('test');
      final value = response.when(
        success: (data, statusCode, headers, message) => 'success: $data',
        failure: (error, statusCode, headers) => 'failure: $error',
      );
      expect(value, 'success: test');
    });

    test('should get or else', () {
      const error = ApiError.network(message: 'Network error');
      const response = ApiResponse.failure(error);
      final value = response.getOrElse('default');
      expect(value, 'default');
    });

    test('should get or else compute', () {
      const error = ApiError.network(message: 'Network error');
      const response = ApiResponse.failure(error);
      final value = response.getOrElseCompute(() => 'computed');
      expect(value, 'computed');
    });
  });

  group('ApiError', () {
    test('should create network error', () {
      const error = ApiError.network(message: 'Network error');
      expect(error.isNetwork, true);
      expect(error.isHttp, false);
      expect(error.isTimeout, false);
      expect(error.isCancelled, false);
      expect(error.isUnknown, false);
      expect(error.isParse, false);
      expect(error.isValidation, false);
      expect(error.message, 'Network error');
    });

    test('should create HTTP error', () {
      const error = ApiError.http(
        statusCode: 404,
        message: 'Not found',
      );
      expect(error.isNetwork, false);
      expect(error.isHttp, true);
      expect(error.statusCode, 404);
      expect(error.message, 'Not found');
    });

    test('should create timeout error', () {
      const error = ApiError.timeout(message: 'Request timeout');
      expect(error.isTimeout, true);
      expect(error.message, 'Request timeout');
    });

    test('should create cancelled error', () {
      const error = ApiError.cancelled(message: 'Request cancelled');
      expect(error.isCancelled, true);
      expect(error.message, 'Request cancelled');
    });

    test('should create unknown error', () {
      final error = ApiErrorFactory.fromUnknownException(Exception('Unknown error'));
      expect(error.isUnknown, true);
      expect(error.message, 'Exception: Unknown error');
    });

    test('should create parse error', () {
      const error = ApiError.parse(message: 'Parse error');
      expect(error.isParse, true);
      expect(error.message, 'Parse error');
    });

    test('should create validation error', () {
      const error = ApiError.validation(message: 'Validation error');
      expect(error.isValidation, true);
      expect(error.message, 'Validation error');
    });

    test('should check if error is retryable', () {
      const networkError = ApiError.network(message: 'Network error');
      expect(networkError.isRetryable, true);

      const timeoutError = ApiError.timeout(message: 'Timeout');
      expect(timeoutError.isRetryable, true);

      const httpError = ApiError.http(statusCode: 500, message: 'Server error');
      expect(httpError.isRetryable, true);

      const clientError = ApiError.http(statusCode: 400, message: 'Bad request');
      expect(clientError.isRetryable, false);

      const cancelledError = ApiError.cancelled(message: 'Cancelled');
      expect(cancelledError.isRetryable, false);
    });

    test('should get user-friendly message', () {
      const networkError = ApiError.network(message: 'Network error');
      expect(networkError.userMessage, 'Please check your internet connection and try again.');

      const timeoutError = ApiError.timeout(message: 'Timeout');
      expect(timeoutError.userMessage, 'The request timed out. Please try again.');

      const httpError = ApiError.http(statusCode: 404, message: 'Not found');
      expect(httpError.userMessage, 'The requested resource was not found.');

      const validationError = ApiError.validation(message: 'Validation error');
      expect(validationError.userMessage, 'Please check your input and try again.');
    });
  });

  group('ApiErrorFactory', () {
    test('should create error from DioException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout',
      );

      final apiError = ApiErrorFactory.fromDioException(dioException);
      expect(apiError.isTimeout, true);
      expect(apiError.message, 'Request timed out');
    });

    test('should create error from network exception', () {
      final apiError = ApiErrorFactory.fromNetworkException(Exception('Network error'));
      expect(apiError.isNetwork, true);
      expect(apiError.message, 'Network error occurred');
    });

    test('should create error from timeout exception', () {
      final apiError = ApiErrorFactory.fromTimeoutException(Exception('Timeout'));
      expect(apiError.isTimeout, true);
      expect(apiError.message, 'Request timed out');
    });

    test('should create error from parse exception', () {
      final apiError = ApiErrorFactory.fromParseException(Exception('Parse error'));
      expect(apiError.isParse, true);
      expect(apiError.message, 'Failed to parse response');
    });

    test('should create error from validation exception', () {
      final apiError = ApiErrorFactory.fromValidationException('Validation error');
      expect(apiError.isValidation, true);
      expect(apiError.message, 'Validation error');
    });

    test('should create error from unknown exception', () {
      final apiError = ApiErrorFactory.fromUnknownException(Exception('Unknown error'));
      expect(apiError.isUnknown, true);
      expect(apiError.message, 'Exception: Unknown error');
    });
  });
}
