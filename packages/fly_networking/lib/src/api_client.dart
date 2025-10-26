import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fly_networking/src/interceptors/error_interceptor.dart';
import 'package:fly_networking/src/interceptors/logging_interceptor.dart';
import 'package:fly_networking/src/interceptors/retry_interceptor.dart';
import 'package:fly_networking/src/models/api_error.dart';
import 'package:fly_networking/src/models/api_response.dart';

part 'api_client.g.dart';

/// HTTP client for API communication with Fly CLI applications
/// 
/// Provides a standardized way to make HTTP requests with built-in
/// error handling, logging, retry logic, and Riverpod integration.
@riverpod
class ApiClient extends _$ApiClient {
  late final Dio _dio;
  
  @override
  ApiClient build() {
    _dio = Dio();
    _setupInterceptors();
    return this;
  }
  
  void _setupInterceptors() {
    _dio.interceptors.addAll([
      LoggingInterceptor(),
      RetryInterceptor(),
      ErrorInterceptor(),
    ]);
  }
  
  /// Configure the base URL for all requests
  String get baseUrl => _dio.options.baseUrl;
  
  /// Configure the base URL for all requests
  set baseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }
  
  /// Configure request timeout
  void configureTimeout(Duration timeout) {
    _dio.options.connectTimeout = timeout;
    _dio.options.receiveTimeout = timeout;
    _dio.options.sendTimeout = timeout;
  }
  
  /// Configure default headers
  void configureHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }
  
  /// Add authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// Remove authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  /// Make a GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromDioException(e));
    } on Exception catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromUnknownException(e));
    }
  }
  
  /// Make a POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromDioException(e));
    } on Exception catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromUnknownException(e));
    }
  }
  
  /// Make a PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromDioException(e));
    } on Exception catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromUnknownException(e));
    }
  }
  
  /// Make a PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromDioException(e));
    } on Exception catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromUnknownException(e));
    }
  }
  
  /// Make a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromDioException(e));
    } on Exception catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromUnknownException(e));
    }
  }
  
  /// Upload a file
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(file.path),
        ...?additionalFields,
      });
      
      final response = await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromDioException(e));
    } on Exception catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromUnknownException(e));
    }
  }
  
  /// Download a file
  Future<ApiResponse<String>> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      return ApiResponse.success(savePath);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromDioException(e));
    } on Exception catch (e) {
      return ApiResponse.failure(ApiErrorFactory.fromUnknownException(e));
    }
  }
  
  /// Cancel all pending requests
  void cancelAllRequests() {
    _dio.close(force: true);
  }
  
  /// Get the underlying Dio instance for advanced usage
  Dio get dio => _dio;
}

/// Provider for ApiClient with default configuration
@riverpod
ApiClient defaultApiClient(Ref ref) {
  final client = ref.watch(apiClientProvider);
  
  // Configure default settings
  client
    ..configureTimeout(const Duration(seconds: 30))
    ..configureHeaders({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
  
  return client;
}

/// Provider for ApiClient with custom configuration
@riverpod
ApiClient configuredApiClient(
  Ref ref, {
  required String baseUrl,
  Duration? timeout,
  Map<String, dynamic>? headers,
}) {
  final client = ref.watch(apiClientProvider);
  
  client
    ..baseUrl = baseUrl
    ..configureTimeout(timeout ?? const Duration(seconds: 30))
    ..configureHeaders(headers ?? {});
  
  return client;
}
