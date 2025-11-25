import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_project_use_case.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_service_use_case.dart';
import 'package:fly_cli/src/shared/errors/domain/error_codes.dart';

/// Handler for generation commands that delegates to use cases.
///
/// Provides a unified interface for executing generation operations
/// through use cases, following Clean Architecture principles.
class GenerationCommandHandler {
  /// Creates a new instance of [GenerationCommandHandler].
  GenerationCommandHandler({
    required GenerateFeatureUseCase generateFeatureUseCase,
    required GenerateServiceUseCase generateServiceUseCase,
    required GenerateProjectUseCase generateProjectUseCase,
  }) : _generateFeatureUseCase = generateFeatureUseCase,
       _generateServiceUseCase = generateServiceUseCase,
       _generateProjectUseCase = generateProjectUseCase;

  final GenerateFeatureUseCase _generateFeatureUseCase;
  final GenerateServiceUseCase _generateServiceUseCase;
  final GenerateProjectUseCase _generateProjectUseCase;

  /// Execute generation for a feature.
  Future<CommandResult> executeFeature(FeatureGenerationRequest request) async {
    final result = await _generateFeatureUseCase.execute(request);
    return _convertToCommandResult(result, GenerationMode.feature);
  }

  /// Execute generation for a service.
  Future<CommandResult> executeService(ServiceGenerationRequest request) async {
    final result = await _generateServiceUseCase.execute(request);
    return _convertToCommandResult(result, GenerationMode.service);
  }

  /// Execute generation for a project.
  Future<CommandResult> executeProject(ProjectGenerationRequest request) async {
    final result = await _generateProjectUseCase.execute(request);
    return _convertToCommandResult(result, GenerationMode.project);
  }

  /// Convert GenerationResultDto to CommandResult.
  CommandResult _convertToCommandResult(
    GenerationResultDto result,
    GenerationMode mode,
  ) {
    if (!result.success) {
      return CommandResult.error(
        message: result.error ?? 'Generation failed',
        suggestion: 'Check your input and try again',
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
      nextSteps: _getNextSteps(mode),
    );
  }

  /// Get next steps for a command type.
  List<NextStep> _getNextSteps(GenerationMode mode) {
    switch (mode) {
      case GenerationMode.feature:
        return [
          const NextStep(
            command: 'flutter run',
            description: 'Run the application to see the new screen',
          ),
        ];
      case GenerationMode.service:
        return [
          const NextStep(
            command: 'flutter pub get',
            description: 'Install dependencies',
          ),
        ];
      case GenerationMode.project:
        return [
          const NextStep(
            command: 'cd <project_name>',
            description: 'Navigate to the new project',
          ),
          const NextStep(
            command: 'flutter pub get',
            description: 'Install dependencies',
          ),
        ];
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
