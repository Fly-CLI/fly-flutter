import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/domain/generation_error_type.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';

/// Handler for generation commands that delegates to mode strategies.
///
/// Provides a unified, mode-agnostic interface for executing generation
/// operations through registered strategies, following Clean Architecture
/// principles and reducing coupling when adding new generation modes.
///
/// All mode-specific behavior is obtained directly from the profiles map,
/// which is the single source of truth for generation mode configuration.
class GenerationCommandHandler {
  /// Creates a new instance of [GenerationCommandHandler].
  ///
  /// [profiles] provides access to all generation mode profiles, which contain
  /// all mode-specific logic and dependencies (including strategies).
  GenerationCommandHandler({
    required Map<GenerationMode, GenerationModeProfile> profiles,
  }) : _profiles = profiles;

  final Map<GenerationMode, GenerationModeProfile> _profiles;

  /// Get the profile for a specific generation mode.
  ///
  /// Returns null if no profile is registered for the given mode.
  GenerationModeProfile? getProfile(GenerationMode mode) {
    return _profiles[mode];
  }

  /// Execute generation using the appropriate strategy for the request's mode.
  ///
  /// This is the preferred method for executing generation. It automatically
  /// selects the correct strategy based on the request's generation mode.
  ///
  /// All mode-specific behavior comes directly from the profile's strategy.
  Future<CommandResult> execute(GenerationRequestDto request) async {
    final profile = _profiles[request.mode];
    if (profile == null) {
      return CommandResult.error(
        message: 'No profile found for generation mode: ${request.mode.key}',
        suggestion: 'Verify that the generation mode is properly registered',
        errorCode: ErrorCode.invalidArgumentValue,
      );
    }

    // Execute using the strategy from the profile (single source of truth)
    final result = await profile.strategy.execute(request);
    return _convertToCommandResult(result, request.mode, profile.strategy);
  }

  /// Convert GenerationResultDto to CommandResult.
  CommandResult _convertToCommandResult(
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
