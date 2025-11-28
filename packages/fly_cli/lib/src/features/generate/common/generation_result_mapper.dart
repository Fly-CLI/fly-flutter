import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/domain/generation_error_type.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';

/// Helper for converting generation results to command results.
///
/// Provides consistent conversion logic from [GenerationResultDto] to
/// [CommandResult], including error handling, suggestions, and next steps.
class GenerationResultMapper {
  /// Convert a [GenerationResultDto] to a [CommandResult].
  ///
  /// [result] - The generation result to convert
  /// [mode] - The generation mode that was executed
  /// [strategy] - The executor strategy used, for getting next steps
  ///
  /// Returns a [CommandResult] with appropriate success/error state,
  /// messages, suggestions, and next steps.
  static CommandResult toCommandResult(
    GenerationResultDto result,
    GenerationMode mode,
    GenerationExecutor strategy,
  ) {
    if (!result.success) {
      // Provide more specific suggestions based on error type
      final suggestion = _getErrorSuggestion(result.errorType, result.error);
      return CommandResult.error(
        message: result.error ?? 'Generation failed',
        suggestion: suggestion,
        errorCode: ErrorCode.templateGenerationFailed,
      );
    }

    return CommandResult.success(
      command: 'generate ${mode.key}',
      message: '${mode.key.capitalize()} generated successfully',
      data: {
        ...result.data,
        'files_generated': result.generatedFiles.length,
      },
      nextSteps: strategy.getNextSteps(result),
    );
  }

  /// Get a contextual suggestion based on error type.
  static String _getErrorSuggestion(
    GenerationErrorType? errorType,
    String? errorMessage,
  ) {
    switch (errorType) {
      case GenerationErrorType.brickNotFound:
        return 'Verify the brick name and ensure it is installed. Run "fly list" to see available bricks.';
      case GenerationErrorType.variableValidation:
        return 'Review the error details above and correct the invalid variables. Check naming conventions and required fields.';
      case GenerationErrorType.infrastructure:
        return 'Check file system permissions and ensure the output directory is accessible. Verify Mason is properly installed.';
      case GenerationErrorType.generationFailure:
        return 'The generation process encountered an error. Check the error message above for details.';
      case GenerationErrorType.unknown:
      case null:
        return 'Check your input and try again. If the problem persists, check the error message for details.';
    }
  }
}

/// Extension method to capitalize a string.
extension StringExtension on String {
  /// Capitalizes the first letter of the string.
  ///
  /// If the string is empty, it returns the original string.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

