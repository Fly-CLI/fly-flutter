import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// A type-safe result wrapper for operations that can fail
/// 
/// This class provides a functional approach to error handling,
/// avoiding exceptions for expected failures and making error
/// handling explicit and type-safe.
@freezed
sealed class Result<T> with _$Result<T> {
  /// Success result containing data
  const factory Result.success(T data) = Success<T>;
  
  /// Failure result containing error and optional stack trace
  const factory Result.failure(Object error, [StackTrace? stackTrace]) = Failure<T>;
}

/// Extension methods for Result
extension ResultHelpers<T> on Result<T> {
  /// Whether the result is a success
  bool get isSuccess => this is Success<T>;
  
  /// Whether the result is a failure
  bool get isFailure => this is Failure<T>;
  
  /// Get the data if success, null otherwise
  T? get data => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>() => null,
  };
  
  /// Get the error if failure, null otherwise
  Object? get error => switch (this) {
    Success<T>() => null,
    Failure<T>(error: final error) => error,
  };
  
  /// Get the stack trace if failure, null otherwise
  StackTrace? get stackTrace => switch (this) {
    Success<T>() => null,
    Failure<T>(stackTrace: final stackTrace) => stackTrace,
  };
  
  /// Map the result to a new type
  Result<R> mapValue<R>(R Function(T data) mapper) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(mapper(data)),
      Failure<T>(error: final error, stackTrace: final stackTrace) => 
        Result.failure(error, stackTrace),
    };
  }
  
  /// Map the result to a new Result
  Result<R> flatMap<R>(Result<R> Function(T data) mapper) {
    return switch (this) {
      Success<T>(data: final data) => mapper(data),
      Failure<T>(error: final error, stackTrace: final stackTrace) => 
        Result.failure(error, stackTrace),
    };
  }
  
  /// Handle the result with different functions for success and failure
  R whenResult<R>({
    required R Function(T data) success,
    required R Function(Object error, StackTrace? stackTrace) failure,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(error: final error, stackTrace: final stackTrace) => failure(error, stackTrace),
    };
  }
  
  /// Handle the result with optional functions
  R maybeWhenResult<R>({
    R Function(T data)? success,
    R Function(Object error, StackTrace? stackTrace)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success?.call(data) ?? orElse(),
      Failure<T>(error: final error, stackTrace: final stackTrace) => 
        failure?.call(error, stackTrace) ?? orElse(),
    };
  }
  
  /// Get the data or throw if failure
  T getOrThrow() {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>(error: final error) => 
        throw Exception('Result is failure: $error'),
    };
  }
  
  /// Get the data or return a default value
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>() => defaultValue,
    };
  }
  
  /// Get the data or compute a default value
  T getOrElseCompute(T Function() defaultValueComputer) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>() => defaultValueComputer(),
    };
  }
  
  /// Recover from failure by providing a new result
  Result<T> recover(Result<T> Function(Object error, StackTrace? stackTrace) recovery) {
    return switch (this) {
      Success<T>() => this,
      Failure<T>(error: final error, stackTrace: final stackTrace) => recovery(error, stackTrace),
    };
  }
  
  /// Recover from failure by providing a value
  Result<T> recoverWith(T Function(Object error, StackTrace? stackTrace) recovery) {
    return switch (this) {
      Success<T>() => this,
      Failure<T>(error: final error, stackTrace: final stackTrace) => 
        Result.success(recovery(error, stackTrace)),
    };
  }
}

/// Utility functions for creating Results
class ResultUtils {
  /// Create a success result
  static Result<T> success<T>(T data) => Result.success(data);
  
  /// Create a failure result
  static Result<T> failure<T>(Object error, [StackTrace? stackTrace]) => 
    Result.failure(error, stackTrace);
  
  /// Execute a function and wrap the result
  static Result<T> tryCatch<T>(T Function() computation) {
    try {
      return Result.success(computation());
    } catch (error, stackTrace) {
      return Result.failure(error, stackTrace);
    }
  }
  
  /// Execute an async function and wrap the result
  static Future<Result<T>> tryCatchAsync<T>(Future<T> Function() computation) async {
    try {
      final result = await computation();
      return Result.success(result);
    } catch (error, stackTrace) {
      return Result.failure(error, stackTrace);
    }
  }
  
  /// Combine multiple results into a single result
  static Result<List<T>> combine<T>(List<Result<T>> results) {
    final successes = <T>[];
    final failures = <Object>[];
    
    for (final result in results) {
      switch (result) {
        case Success<T>(data: final data):
          successes.add(data);
        case Failure<T>(error: final error):
          failures.add(error);
      }
    }
    
    if (failures.isEmpty) {
      return Result.success(successes);
    } else {
      return Result.failure(Exception('Multiple failures: $failures'));
    }
  }
  
  /// Get the first success from a list of results
  static Result<T> firstSuccess<T>(List<Result<T>> results) {
    for (final result in results) {
      if (result.isSuccess) {
        return result;
      }
    }
    
    // If no success, return the first failure
    return results.first;
  }
}
