import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_registry.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/domain/generation_error_type.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';

/// Handler for generation commands that delegates to mode strategies.
///
/// Provides a unified, mode-agnostic interface for executing generation
/// operations through registered strategies, following Clean Architecture
/// principles and reducing coupling when adding new generation modes.
class GenerationCommandHandler {
  /// Creates a new instance of [GenerationCommandHandler].
  GenerationCommandHandler({
    required GenerationModeRegistry registry,
  }) : _registry = registry;

  final GenerationModeRegistry _registry;

  /// Execute generation using the appropriate strategy for the request's mode.
  ///
  /// This is the preferred method for executing generation. It automatically
  /// selects the correct strategy based on the request's generation mode.
  ///
  /// Delegates to the registry's execute method, which serves as the single
  /// source of truth for routing generation requests to their strategies.
  Future<CommandResult> execute(GenerationRequestDto request) async {
    final result = await _registry.execute(request);
    final strategy = _registry.getStrategy(request.mode);
    return _convertToCommandResult(result, request.mode, strategy);
  }

  /// Convert GenerationResultDto to CommandResult.
  CommandResult _convertToCommandResult(
    GenerationResultDto result,
    GenerationMode mode,
    GenerationModeStrategy strategy,
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
  String _getErrorSuggestion(
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
