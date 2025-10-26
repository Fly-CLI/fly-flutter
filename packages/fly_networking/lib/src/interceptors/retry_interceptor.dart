import 'dart:math';

import 'package:dio/dio.dart';

/// Retry interceptor for API requests
/// 
/// Automatically retries failed requests with exponential backoff
/// for network errors and certain HTTP status codes.
class RetryInterceptor extends Interceptor {
  /// Creates a retry interceptor
  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ],
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryableExceptions = const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ],
  });
  
  /// Maximum number of retries
  final int maxRetries;
  
  /// Delays between retries
  final List<Duration> retryDelays;
  
  /// HTTP status codes that should be retried
  final List<int> retryableStatusCodes;
  
  /// Exception types that should be retried
  final List<DioExceptionType> retryableExceptions;
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }
    
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }
    
    final delay = _getRetryDelay(retryCount);
    
    await Future<void>.delayed(delay);
    
    try {
      final response = await Dio().fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      final newError = e.copyWith(
        requestOptions: e.requestOptions.copyWith(
          extra: {
            ...e.requestOptions.extra,
            'retryCount': retryCount + 1,
          },
        ),
      );
      handler.next(newError);
    } on Exception {
      handler.next(err);
    }
  }
  
  bool _shouldRetry(DioException err) {
    // Check if the exception type is retryable
    if (retryableExceptions.contains(err.type)) {
      return true;
    }
    
    // Check if the HTTP status code is retryable
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode != null && retryableStatusCodes.contains(statusCode)) {
        return true;
      }
    }
    
    return false;
  }
  
  Duration _getRetryDelay(int retryCount) {
    if (retryCount < retryDelays.length) {
      return retryDelays[retryCount];
    }
    
    // Use exponential backoff for additional retries
    final baseDelay = retryDelays.last;
    final multiplier = pow(2, retryCount - retryDelays.length + 1);
    return Duration(
      milliseconds: (baseDelay.inMilliseconds * multiplier).round(),
    );
  }
}
