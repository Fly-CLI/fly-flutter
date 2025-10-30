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
    
    // Record start time for latency measurement
    options.extra['startTime'] = DateTime.now();

    final buffer = StringBuffer();
    buffer
      ..writeln('🚀 ${options.method} ${options.uri}')
      ..writeln('📋 Headers: ${_redactHeaders(options.headers)}');
    if (logRequestBody) {
      buffer.writeln('📦 Body: ${options.data}');
    }
    
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
    final latency = _computeLatency(response.requestOptions);
    buffer
      ..writeln(
        '✅ ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
      )
      ..writeln('⏱️ Latency: ${latency.inMilliseconds}ms');
    if (logResponseHeaders) {
      buffer.writeln('📋 Headers: ${_redactHeaders(response.headers.map.map((k, v) => MapEntry(k, v.join(", "))))}');
    }
    if (logResponseBody) {
      buffer.writeln('📦 Response: ${response.data}');
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
    final latency = _computeLatency(err.requestOptions);
    buffer
      ..writeln(
        '❌ ${err.type} ${err.requestOptions.method} '
        '${err.requestOptions.uri}',
      )
      ..writeln('⏱️ Latency: ${latency.inMilliseconds}ms')
      ..writeln('📋 Message: ${err.message}')
      ..writeln('📋 Request Headers: ${_redactHeaders(err.requestOptions.headers)}');
    
    if (err.response != null) {
      buffer
        ..writeln('📊 Status: ${err.response!.statusCode}')
        ..writeln('📦 Error Response: ${err.response!.data}');
    }
    
    buffer.writeln('📋 Stack Trace: ${err.stackTrace}');
      
    if (kDebugMode) {
      debugPrint(buffer.toString());
    }
    
    handler.next(err);
  }

  Map<String, Object?> _redactHeaders(Map<String, Object?> headers) {
    const sensitive = {'authorization', 'cookie', 'set-cookie'};
    final redacted = <String, Object?>{};
    headers.forEach((key, value) {
      if (sensitive.contains(key.toLowerCase())) {
        redacted[key] = 'REDACTED';
      } else {
        redacted[key] = value;
      }
    });
    return redacted;
  }

  Duration _computeLatency(RequestOptions options) {
    final start = options.extra['startTime'];
    if (start is DateTime) {
      return DateTime.now().difference(start);
    }
    return Duration.zero;
  }
}
