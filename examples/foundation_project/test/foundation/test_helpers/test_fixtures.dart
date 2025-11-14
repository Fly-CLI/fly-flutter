import 'package:fly_errors/fly_errors.dart';
import 'package:fly_flow_guard/fly_flow_guard.dart';

/// Test fixtures and helper data for foundation tests
class TestFixtures {
  /// Creates a sample AppException for testing
  static AppException createAppException({
    String message = 'Test error',
    String? code,
    Object? details,
  }) {
    return AppException(message, code: code, details: details);
  }

  /// Creates a sample NetworkError for testing
  static NetworkError createNetworkError({
    String message = 'Network error',
  }) {
    return ConnectionError(customMessage: message);
  }

  /// Creates a sample Success result for testing
  static Success<T> createSuccessResult<T>(T data) {
    return Success(data);
  }

  /// Creates a sample Failure result for testing
  static Failure<T> createFailureResult<T>({
    String message = 'Operation failed',
    Object? error,
  }) {
    return Failure(message, error);
  }

  /// Creates a sample Loading result for testing
  static Loading<T> createLoadingResult<T>() {
    return const Loading();
  }

  /// Creates a sample RetryConfig for testing
  static RetryConfig createRetryConfig({
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
  }) {
    return RetryConfig(
      maxAttempts: maxRetries,
      baseDelay: initialDelay,
      backoffMultiplier: backoffMultiplier,
      maxDelay: maxDelay,
    );
  }

  /// Sample exception for testing
  static Exception get sampleException => Exception('Test exception');

  /// Sample stack trace for testing
  static StackTrace get sampleStackTrace => StackTrace.current;

  /// Sample error message
  static String get sampleErrorMessage => 'Test error message';

  /// Sample success data
  static String get sampleSuccessData => 'Success data';

  /// Sample error code
  static String get sampleErrorCode => 'TEST_ERROR';
}

