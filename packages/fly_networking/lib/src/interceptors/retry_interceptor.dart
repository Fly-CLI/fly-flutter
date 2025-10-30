import 'package:dio/dio.dart';
import 'package:fly_core/src/retry/retry.dart';

/// Retry interceptor for API requests
/// 
/// Automatically retries failed requests with exponential backoff
/// for network errors and certain HTTP status codes.
class RetryInterceptor extends Interceptor {
  /// Creates a retry interceptor
  RetryInterceptor({
    required Dio dio,
    int? maxRetries,
    Duration? initialDelay,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryableExceptions = const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ],
    this.retryIdempotentOnly = true,
  })  : _dio = dio,
        retryPolicy = RetryPolicy(
          maxAttempts: (maxRetries ?? 3) + 1, // +1 for initial attempt
          initialDelay: initialDelay ?? const Duration(seconds: 1),
          backoffMultiplier: 2.0,
          maxDelay: const Duration(seconds: 30),
          enableTimeout: false,
        ),
        retryStrategy = const ExponentialBackoffStrategy();
  
  /// The owning Dio used to re-dispatch the request (preserves interceptors/options)
  final Dio _dio;

  /// Retry policy for network operations
  final RetryPolicy retryPolicy;
  
  /// Retry strategy for calculating delays
  final RetryStrategy retryStrategy;
  
  /// HTTP status codes that should be retried
  final List<int> retryableStatusCodes;
  
  /// Exception types that should be retried
  final List<DioExceptionType> retryableExceptions;

  /// Whether to retry only idempotent HTTP methods by default
  final bool retryIdempotentOnly;
  
  /// Maximum number of retries (for compatibility)
  int get maxRetries => retryPolicy.maxAttempts - 1;
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }
    
    final currentRetryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;

    if (currentRetryCount >= maxRetries) {
      handler.next(err);
      return;
    }
    
    final computedDelay = _getPlannedDelay(err, currentRetryCount);

    await Future<void>.delayed(computedDelay);

    // Increment retryCount before re-dispatching
    final updatedOptions = err.requestOptions.copyWith(
      extra: {
        ...err.requestOptions.extra,
        'retryCount': currentRetryCount + 1,
      },
    );

    try {
      final response = await _dio.fetch<dynamic>(updatedOptions);
      handler.resolve(response);
    } on DioException catch (nextErr) {
      handler.next(nextErr);
    } on Exception {
      handler.next(err);
    }
  }
  
  bool _shouldRetry(DioException err) {
    // Check if the exception type is retryable
    if (retryableExceptions.contains(err.type)) {
      return _isMethodRetryable(err.requestOptions);
    }
    
    // Check if the HTTP status code is retryable
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode != null && retryableStatusCodes.contains(statusCode)) {
        return _isMethodRetryable(err.requestOptions);
      }
    }
    
    return false;
  }
  
  /// Determine if the HTTP method is safe to retry
  bool _isMethodRetryable(RequestOptions options) {
    if (!retryIdempotentOnly) {
      return true;
    }
    final method = (options.method).toUpperCase();
    const idempotent = {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'};
    if (idempotent.contains(method)) {
      return true;
    }
    // Allow POST when an idempotency key is present
    if (method == 'POST') {
      final hasIdempotencyKey = options.headers.keys
          .map((k) => k.toLowerCase())
          .contains('idempotency-key');
      final explicitOptIn = (options.extra['retryPost'] as bool?) == true;
      return hasIdempotencyKey || explicitOptIn;
    }
    return false;
  }

  /// Compute planned delay including Retry-After header (if present) or backoff strategy
  Duration _getPlannedDelay(DioException err, int retryCount) {
    // Honor Retry-After for 429/503 responses when provided
    final response = err.response;
    if (response != null && response.statusCode != null &&
        (response.statusCode == 429 || response.statusCode == 503)) {
      final retryAfter = response.headers.value('retry-after');
      final parsed = _parseRetryAfter(retryAfter);
      if (parsed != null) {
        return parsed;
      }
    }

    // Fallback to exponential backoff strategy from fly_core
    return retryStrategy.calculateDelay(retryCount, retryPolicy);
  }

  /// Parse Retry-After header supporting both seconds and HTTP date format
  Duration? _parseRetryAfter(String? header) {
    if (header == null) return null;
    final trimmed = header.trim();
    // seconds format
    final seconds = int.tryParse(trimmed);
    if (seconds != null && seconds >= 0) {
      return Duration(seconds: seconds);
    }
    // HTTP-date format
    try {
      final date = DateTime.parse(trimmed);
      final now = DateTime.now().toUtc();
      final target = date.toUtc();
      final diff = target.difference(now);
      if (diff.isNegative) return Duration.zero;
      return diff;
    } catch (_) {
      return null;
    }
  }
}
