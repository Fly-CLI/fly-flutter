import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';

/// Standardized API error representation
/// 
/// Provides a consistent way to represent API errors with different types
/// and additional context information.
@freezed
sealed class ApiError with _$ApiError {
  /// Network error (no internet connection, timeout, etc.)
  const factory ApiError.network({
    required String message,
    String? originalError,
  }) = NetworkError;
  
  /// HTTP error (4xx, 5xx status codes)
  const factory ApiError.http({
    required int statusCode,
    required String message,
    String? body,
    Map<String, dynamic>? headers,
  }) = HttpError;
  
  /// Timeout error
  const factory ApiError.timeout({
    required String message,
    Duration? timeout,
  }) = TimeoutError;
  
  /// Cancellation error
  const factory ApiError.cancelled({
    required String message,
  }) = CancelledError;
  
  /// Unknown error
  const factory ApiError.unknown({
    required Object error,
    String? message,
  }) = UnknownError;
  
  /// Parse error (JSON parsing, etc.)
  const factory ApiError.parse({
    required String message,
    String? originalError,
  }) = ParseError;
  
  /// Validation error
  const factory ApiError.validation({
    required String message,
    Map<String, List<String>>? fieldErrors,
  }) = ValidationError;
}

/// Extension methods for ApiError
extension ApiErrorExtension on ApiError {
  /// Whether this is a network error
  bool get isNetwork => this is NetworkError;
  
  /// Whether this is an HTTP error
  bool get isHttp => this is HttpError;
  
  /// Whether this is a timeout error
  bool get isTimeout => this is TimeoutError;
  
  /// Whether this is a cancellation error
  bool get isCancelled => this is CancelledError;
  
  /// Whether this is an unknown error
  bool get isUnknown => this is UnknownError;
  
  /// Whether this is a parse error
  bool get isParse => this is ParseError;
  
  /// Whether this is a validation error
  bool get isValidation => this is ValidationError;
  
  /// Get the error message
  String get message => switch (this) {
    NetworkError(message: final message) => message,
    HttpError(message: final message) => message,
    TimeoutError(message: final message) => message,
    CancelledError(message: final message) => message,
    UnknownError(message: final message) => message ?? 'Unknown error occurred',
    ParseError(message: final message) => message,
    ValidationError(message: final message) => message,
  };
  
  /// Get the status code if this is an HTTP error
  int? get statusCode => switch (this) {
    HttpError(statusCode: final statusCode) => statusCode,
    _ => null,
  };
  
  /// Whether this error is retryable
  bool get isRetryable => switch (this) {
    NetworkError() => true,
    TimeoutError() => true,
    HttpError(statusCode: final statusCode) => 
      statusCode >= 500 || statusCode == 429,
    _ => false,
  };
  
  /// Get a user-friendly error message
  String get userMessage => switch (this) {
    NetworkError() => 'Please check your internet connection and try again.',
    TimeoutError() => 'The request timed out. Please try again.',
    CancelledError() => 'The request was cancelled.',
    HttpError(statusCode: final statusCode) => switch (statusCode) {
      400 => 'Invalid request. Please check your input.',
      401 => 'You are not authorized. Please log in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested resource was not found.',
      409 => 'There was a conflict with the current state.',
      422 => 'The request was well-formed but contains invalid data.',
      429 => 'Too many requests. Please try again later.',
      500 => 'Server error. Please try again later.',
      502 => 'Bad gateway. Please try again later.',
      503 => 'Service unavailable. Please try again later.',
      504 => 'Gateway timeout. Please try again later.',
      _ => 'An error occurred. Please try again.',
    },
    ParseError() => 'Failed to process the response. Please try again.',
    ValidationError() => 'Please check your input and try again.',
    UnknownError() => 'An unexpected error occurred. Please try again.',
  };
}

/// Factory methods for creating ApiError instances
class ApiErrorFactory {
  /// Create an ApiError from a DioException
  static ApiError fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout(
          message: 'Request timed out',
          timeout: e.requestOptions.connectTimeout,
        );
      
      case DioExceptionType.badResponse:
        final response = e.response;
        return ApiError.http(
          statusCode: response?.statusCode ?? 0,
          message: response?.statusMessage ?? 'HTTP error occurred',
          body: response?.data?.toString(),
          headers: response?.headers.map,
        );
      
      case DioExceptionType.cancel:
        return const ApiError.cancelled(
          message: 'Request was cancelled',
        );
      
      case DioExceptionType.connectionError:
        return ApiError.network(
          message: 'Network connection error',
          originalError: e.message,
        );
      
      case DioExceptionType.badCertificate:
        return ApiError.network(
          message: 'SSL certificate error',
          originalError: e.message,
        );
      
      case DioExceptionType.unknown:
        return ApiError.unknown(
          error: e,
          message: e.message,
        );
    }
  }
  
  /// Create an ApiError from a network exception
  static ApiError fromNetworkException(Object error) => ApiError.network(
    message: 'Network error occurred',
    originalError: error.toString(),
  );
  
  /// Create an ApiError from a timeout exception
  static ApiError fromTimeoutException(Object error, [Duration? timeout]) =>
    ApiError.timeout(
      message: 'Request timed out',
      timeout: timeout,
    );
  
  /// Create an ApiError from a parse exception
  static ApiError fromParseException(Object error) => ApiError.parse(
    message: 'Failed to parse response',
    originalError: error.toString(),
  );
  
  /// Create an ApiError from a validation exception
  static ApiError fromValidationException(
    String message, [
    Map<String, List<String>>? fieldErrors,
  ]) => ApiError.validation(
    message: message,
    fieldErrors: fieldErrors,
  );
  
  /// Create an ApiError from an unknown exception
  static ApiError fromUnknownException(Object error) => ApiError.unknown(
    error: error,
    message: error.toString(),
  );
}
