import 'package:dio/dio.dart';

import 'package:fly_networking/src/models/api_error.dart';

/// Error interceptor for API requests
/// 
/// Transforms DioException instances into standardized ApiError instances
/// and provides consistent error handling across the application.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({
    this.transformErrors = true,
    this.includeStackTrace = false,
  });
  
  final bool transformErrors;
  final bool includeStackTrace;
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!transformErrors) {
      handler.next(err);
      return;
    }
    
    final apiError = ApiErrorFactory.fromDioException(err);
    
    // Create a new DioException with the transformed error
    final transformedError = err.copyWith(
      error: apiError,
      message: apiError.message,
    );
    
    handler.next(transformedError);
  }
}
