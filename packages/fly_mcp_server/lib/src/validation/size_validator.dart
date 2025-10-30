import 'dart:convert';

import 'package:fly_mcp_server/src/config/size_limits_config.dart';
import 'package:fly_mcp_server/src/errors/server_errors.dart';

/// Validates sizes of input/output data
class SizeValidator {
  /// Creates a size validator with the given limits
  SizeValidator(this.limits);

  final SizeLimitsConfig limits;

  /// Validates the size of a JSON-serializable value
  /// 
  /// Calculates the size by JSON encoding the value.
  /// Throws [InvalidParamsError] if the size exceeds the limit.
  /// 
  /// [value] - The value to validate
  /// [limit] - The maximum allowed size in bytes
  /// [name] - The name of the value (for error messages)
  void validateValueSize(Object? value, int limit, String name) {
    try {
      final json = jsonEncode(value);
      final size = utf8.encode(json).length;
      
      if (size > limit) {
        throw InvalidParamsError(
          message: '$name exceeds maximum size: $size bytes > $limit bytes',
          invalidFields: [name],
        );
      }
    } catch (e) {
      if (e is InvalidParamsError) {
        rethrow;
      }
      // If encoding fails, we can't validate size, but that's an error anyway
      throw InvalidParamsError(
        message: 'Failed to validate $name size: $e',
        invalidFields: [name],
      );
    }
  }

  /// Validates parameter size
  /// 
  /// Throws [InvalidParamsError] if parameters exceed maxParameterSize.
  void validateParameters(Map<String, Object?> params) {
    validateValueSize(
      params,
      limits.maxParameterSize,
      'parameters',
    );
  }

  /// Validates result size
  /// 
  /// Throws [InvalidParamsError] if result exceeds maxResultSize.
  void validateResult(Object? result) {
    validateValueSize(
      result,
      limits.maxResultSize,
      'result',
    );
  }

  /// Validates resource content size
  /// 
  /// Throws [InvalidParamsError] if content exceeds maxResourceSize.
  void validateResourceContent(String content) {
    final size = utf8.encode(content).length;
    if (size > limits.maxResourceSize) {
      throw InvalidParamsError(
        message: 'Resource content exceeds maximum size: $size bytes > ${limits.maxResourceSize} bytes',
        invalidFields: ['content'],
      );
    }
  }

  /// Validates message size
  /// 
  /// Throws [InvalidParamsError] if message exceeds maxMessageSize.
  void validateMessage(Object? message) {
    validateValueSize(
      message,
      limits.maxMessageSize,
      'message',
    );
  }

  /// Gets the size of a JSON-serializable value in bytes
  int getValueSize(Object? value) {
    try {
      final json = jsonEncode(value);
      return utf8.encode(json).length;
    } catch (e) {
      return -1; // Indicates error
    }
  }
}

