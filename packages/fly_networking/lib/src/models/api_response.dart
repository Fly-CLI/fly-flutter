import 'package:fly_networking/src/models/api_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';

/// Standardized API response wrapper
/// 
/// Provides a consistent way to handle API responses with success/error states
/// and additional metadata like status codes and headers.
@freezed
sealed class ApiResponse<T> with _$ApiResponse<T> {
  /// Successful API response
  const factory ApiResponse.success(
    T data, {
    int? statusCode,
    Map<String, dynamic>? headers,
    String? message,
  }) = ApiSuccess<T>;
  
  /// Failed API response
  const factory ApiResponse.failure(
    ApiError error, {
    int? statusCode,
    Map<String, dynamic>? headers,
  }) = ApiFailure<T>;
}

/// Extension methods for ApiResponse
extension ApiResponseHelpers<T> on ApiResponse<T> {
  /// Whether the response is successful
  bool get isSuccess => this is ApiSuccess<T>;
  
  /// Whether the response is a failure
  bool get isFailure => this is ApiFailure<T>;
  
  /// Get the data if successful, null otherwise
  T? get data => switch (this) {
    ApiSuccess<T>(data: final data) => data,
    ApiFailure<T>() => null,
  };
  
  /// Get the error if failed, null otherwise
  ApiError? get error => switch (this) {
    ApiSuccess<T>() => null,
    ApiFailure<T>(error: final error) => error,
  };
  
  /// Get the status code
  int? get statusCode => switch (this) {
    ApiSuccess<T>(statusCode: final statusCode) => statusCode,
    ApiFailure<T>(statusCode: final statusCode) => statusCode,
  };
  
  /// Get the headers
  Map<String, dynamic>? get headers => switch (this) {
    ApiSuccess<T>(headers: final headers) => headers,
    ApiFailure<T>(headers: final headers) => headers,
  };
  
  /// Map the response to a new type
  ApiResponse<R> mapData<R>(R Function(T data) mapper) => switch (this) {
        ApiSuccess<T>(
          data: final data,
          statusCode: final statusCode,
          headers: final headers,
          message: final message,
        ) =>
          ApiResponse.success(
            mapper(data),
            statusCode: statusCode,
            headers: headers,
            message: message,
          ),
        ApiFailure<T>(
          error: final error,
          statusCode: final statusCode,
          headers: final headers,
        ) =>
          ApiResponse.failure(
            error,
            statusCode: statusCode,
            headers: headers,
          ),
      };

  /// Handle the response with different functions for success and failure
  R whenResponse<R>({
    required R Function(
      T data,
      int? statusCode,
      Map<String, dynamic>? headers,
      String? message,
    ) success,
    required R Function(
      ApiError error,
      int? statusCode,
      Map<String, dynamic>? headers,
    ) failure,
  }) =>
      switch (this) {
        ApiSuccess<T>(
          data: final data,
          statusCode: final statusCode,
          headers: final headers,
          message: final message,
        ) =>
          success(data, statusCode, headers, message),
        ApiFailure<T>(
          error: final error,
          statusCode: final statusCode,
          headers: final headers,
        ) =>
          failure(error, statusCode, headers),
      };

  /// Handle the response with optional functions
  R maybeWhenResponse<R>({
    required R Function() orElse,
    R Function(
      T data,
      int? statusCode,
      Map<String, dynamic>? headers,
      String? message,
    )? success,
    R Function(
      ApiError error,
      int? statusCode,
      Map<String, dynamic>? headers,
    )? failure,
  }) =>
      switch (this) {
        ApiSuccess<T>(
          data: final data,
          statusCode: final statusCode,
          headers: final headers,
          message: final message,
        ) =>
          success?.call(data, statusCode, headers, message) ?? orElse(),
        ApiFailure<T>(
          error: final error,
          statusCode: final statusCode,
          headers: final headers,
        ) =>
          failure?.call(error, statusCode, headers) ?? orElse(),
      };

  /// Get the data or throw if failure
  T getOrThrow() => switch (this) {
        ApiSuccess<T>(data: final data) => data,
        ApiFailure<T>(error: final error) =>
          throw Exception('API response is failure: $error'),
      };

  /// Get the data or return a default value
  T getOrElse(T defaultValue) => switch (this) {
        ApiSuccess<T>(data: final data) => data,
        ApiFailure<T>() => defaultValue,
      };

  /// Get the data or compute a default value
  T getOrElseCompute(T Function() defaultValueComputer) => switch (this) {
        ApiSuccess<T>(data: final data) => data,
        ApiFailure<T>() => defaultValueComputer(),
      };
}
