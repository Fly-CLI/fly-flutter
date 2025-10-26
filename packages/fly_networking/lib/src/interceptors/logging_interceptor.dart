import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logging interceptor for API requests and responses
/// 
/// Provides detailed logging of HTTP requests, responses, and errors
/// for debugging and monitoring purposes.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({
    this.logRequest = true,
    this.logResponse = true,
    this.logError = true,
    this.logRequestHeaders = false,
    this.logResponseHeaders = false,
    this.logRequestBody = false,
    this.logResponseBody = false,
  });
  
  final bool logRequest;
  final bool logResponse;
  final bool logError;
  final bool logRequestHeaders;
  final bool logResponseHeaders;
  final bool logRequestBody;
  final bool logResponseBody;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!logRequest) {
      handler.next(options);
      return;
    }
    
    final buffer = StringBuffer();
    buffer.writeln('🚀 ${options.method} ${options.uri}');
    
    if (logRequestHeaders && options.headers.isNotEmpty) {
      buffer.writeln('📋 Headers:');
      options.headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    if (logRequestBody && options.data != null) {
      buffer.writeln('📦 Body:');
      buffer.writeln('  ${options.data}');
    }
    
    if (kDebugMode) {
      debugPrint(buffer.toString());
    }
    
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!logResponse) {
      handler.next(response);
      return;
    }
    
    final buffer = StringBuffer();
    buffer.writeln('✅ ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}');
    
    if (logResponseHeaders && response.headers.map.isNotEmpty) {
      buffer.writeln('📋 Headers:');
      response.headers.map.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    if (logResponseBody && response.data != null) {
      buffer.writeln('📦 Response:');
      buffer.writeln('  ${response.data}');
    }
    
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
    buffer.writeln('❌ ${err.type} ${err.requestOptions.method} ${err.requestOptions.uri}');
    
    if (err.response != null) {
      buffer.writeln('📊 Status: ${err.response!.statusCode}');
      buffer.writeln('📋 Message: ${err.response!.statusMessage}');
      
      if (logResponseBody && err.response!.data != null) {
        buffer.writeln('📦 Error Response:');
        buffer.writeln('  ${err.response!.data}');
      }
    } else {
      buffer.writeln('📋 Message: ${err.message}');
    }
    
    if (err.stackTrace != null) {
      buffer.writeln('📋 Stack Trace:');
      buffer.writeln('  ${err.stackTrace}');
    }
    
    if (kDebugMode) {
      debugPrint(buffer.toString());
    }
    
    handler.next(err);
  }
}
