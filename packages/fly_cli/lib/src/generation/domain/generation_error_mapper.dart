import 'package:fly_cli/src/generation/domain/generation_error_type.dart';

/// Maps exceptions and error conditions to [GenerationErrorType].
///
/// Provides consistent error categorization across the generation pipeline.
class GenerationErrorMapper {
  /// Maps an exception to an appropriate [GenerationErrorType].
  ///
  /// Returns [GenerationErrorType.unknown] if the exception type is not recognized.
  static GenerationErrorType fromException(Object exception) {
    final exceptionType = exception.runtimeType.toString();

    // Check for common exception patterns
    if (exceptionType.contains('BrickNotFound') ||
        exceptionType.contains('TemplateNotFound')) {
      return GenerationErrorType.brickNotFound;
    }

    if (exceptionType.contains('Validation') ||
        exceptionType.contains('VariableValidation')) {
      return GenerationErrorType.variableValidation;
    }

    if (exceptionType.contains('Mason') ||
        exceptionType.contains('FileSystem') ||
        exceptionType.contains('IOException')) {
      return GenerationErrorType.infrastructure;
    }

    // Check error message patterns as fallback
    final message = exception.toString().toLowerCase();
    if (message.contains('brick') && message.contains('not found')) {
      return GenerationErrorType.brickNotFound;
    }
    if (message.contains('validation') || message.contains('invalid')) {
      return GenerationErrorType.variableValidation;
    }
    if (message.contains('file') ||
        message.contains('directory') ||
        message.contains('permission')) {
      return GenerationErrorType.infrastructure;
    }

    return GenerationErrorType.unknown;
  }

  /// Maps an error message to an appropriate [GenerationErrorType].
  ///
  /// Uses heuristics based on error message content.
  static GenerationErrorType fromMessage(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();

    if (lowerMessage.contains('brick') && lowerMessage.contains('not found')) {
      return GenerationErrorType.brickNotFound;
    }

    if (lowerMessage.contains('validation') ||
        lowerMessage.contains('invalid') ||
        lowerMessage.contains('variable')) {
      return GenerationErrorType.variableValidation;
    }

    if (lowerMessage.contains('file') ||
        lowerMessage.contains('directory') ||
        lowerMessage.contains('permission') ||
        lowerMessage.contains('mason')) {
      return GenerationErrorType.infrastructure;
    }

    if (lowerMessage.contains('generation') &&
        lowerMessage.contains('failed')) {
      return GenerationErrorType.generationFailure;
    }

    return GenerationErrorType.unknown;
  }

  /// Maps error data map to an appropriate [GenerationErrorType].
  ///
  /// Checks for specific keys in the data map that indicate error type.
  static GenerationErrorType fromData(Map<String, dynamic> data) {
    if (data.containsKey('brick_id') || data.containsKey('brick_not_found')) {
      return GenerationErrorType.brickNotFound;
    }

    if (data.containsKey('validation_errors') ||
        data.containsKey('validation_failed')) {
      return GenerationErrorType.variableValidation;
    }

    if (data.containsKey('error_type')) {
      final errorTypeStr = data['error_type'].toString();
      try {
        return GenerationErrorType.values.firstWhere(
          (e) => e.name == errorTypeStr,
        );
      } catch (_) {
        // Fall through to message-based detection
      }
    }

    // Try to infer from error message if present
    if (data.containsKey('error') && data['error'] is String) {
      return fromMessage(data['error'] as String);
    }

    return GenerationErrorType.unknown;
  }
}
