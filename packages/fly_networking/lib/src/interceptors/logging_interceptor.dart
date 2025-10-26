import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logging interceptor for API requests and responses
/// 
/// Provides detailed logging of HTTP requests, responses, and errors
/// for debugging and monitoring purposes.
class LoggingInterceptor extends Interceptor {
  /// Creates a logging interceptor
  LoggingInterceptor({
    this.logRequest = true,
    this.logResponse = true,
    this.logError = true,
    this.logRequestHeaders = false,
    this.logResponseHeaders = false,
    this.logRequestBody = false,
    this.logResponseBody = false,
  });
  
  /// Whether to log requests
  final bool logRequest;
  
  /// Whether to log responses
  final bool logResponse;
  
  /// Whether to log errors
  final bool logError;
  
  /// Whether to log request headers
  final bool logRequestHeaders;
  
  /// Whether to log response headers
  final bool logResponseHeaders;
  
  /// Whether to log request body
  final bool logRequestBody;
  
  /// Whether to log response body
  final bool logResponseBody;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!logRequest) {
      handler.next(options);
      return;
    }
    
    final buffer = StringBuffer();
    buffer
      ..writeln('🚀 ${options.method} ${options.uri}')
      ..writeln('📦 Body: ${options.data}');
    
    if (kDebugMode) {
      debugPrint(buffer.toString());
    }
    
    handler.next(options);
  }
  
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!logResponse) {
      handler.next(response);
      return;
    }
    
    final buffer = StringBuffer();
    buffer
      ..writeln(
        '✅ ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
      )
      ..writeln('📦 Response: ${response.data}');
    
    if (kDebugMode) {
      debugPrint(buffer.toString());
    }
    
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!logError) {
      handler.next(err);
      return;
    }
    
    final buffer = StringBuffer();
    buffer
      ..writeln(
        '❌ ${err.type} ${err.requestOptions.method} '
        '${err.requestOptions.uri}',
      )
      ..writeln('📋 Message: ${err.message}');
    
    if (err.response != null) {
      buffer
        ..writeln('📊 Status: ${err.response!.statusCode}')
        ..writeln('📦 Error Response: ${err.response!.data}');
    }
    
    if (err.stackTrace != null) {
      buffer.writeln('📋 Stack Trace: ${err.stackTrace}');
    }
    
    if (kDebugMode) {
      debugPrint(buffer.toString());
    }
    
    handler.next(err);
  }
}
