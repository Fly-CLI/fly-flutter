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
  GenerationCommandHandler({
    required GenerateFeatureUseCase generateFeatureUseCase,
    required GenerateServiceUseCase generateServiceUseCase,
    required GenerateProjectUseCase generateProjectUseCase,
  })  : _generateFeatureUseCase = generateFeatureUseCase,
        _generateServiceUseCase = generateServiceUseCase,
        _generateProjectUseCase = generateProjectUseCase;

  final GenerateFeatureUseCase _generateFeatureUseCase;
  final GenerateServiceUseCase _generateServiceUseCase;
  final GenerateProjectUseCase _generateProjectUseCase;

  /// Execute generation for a feature.
  Future<CommandResult> executeFeature({
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    final request = GenerationRequestDto(
      mode: GenerationMode.feature,
      variables: variables,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );

    final result = await _generateFeatureUseCase.execute(request);
    return _convertToCommandResult(result, 'feature');
  }

  /// Execute generation for a service.
  Future<CommandResult> executeService({
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    final request = GenerationRequestDto(
      mode: GenerationMode.service,
      variables: variables,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );

    final result = await _generateServiceUseCase.execute(request);
    return _convertToCommandResult(result, 'service');
  }

  /// Execute generation for a project.
  Future<CommandResult> executeProject({
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    final request = GenerationRequestDto(
      mode: GenerationMode.project,
      variables: variables,
      outputDirectory: outputDirectory,
      dryRun: dryRun,
    );

    final result = await _generateProjectUseCase.execute(request);
    return _convertToCommandResult(result, 'project');
  }

  /// Convert GenerationResultDto to CommandResult.
  CommandResult _convertToCommandResult(
    GenerationResultDto result,
    String commandType,
  ) {
    if (!result.success) {
      return CommandResult.error(
        message: result.error ?? 'Generation failed',
        suggestion: 'Check your input and try again',
        errorCode: ErrorCode.templateGenerationFailed,
      );
    }

    return CommandResult.success(
      command: 'generate $commandType',
      message: '${commandType.capitalize()} generated successfully',
      data: {
        ...result.data,
        'files_generated': result.generatedFiles.length,
      },
      nextSteps: _getNextSteps(commandType),
    );
  }

  /// Get next steps for a command type.
  List<NextStep> _getNextSteps(String commandType) {
    switch (commandType) {
      case 'feature':
        return [
          const NextStep(
            command: 'flutter run',
            description: 'Run the application to see the new screen',
          ),
        ];
      case 'service':
        return [
          const NextStep(
            command: 'flutter pub get',
            description: 'Install dependencies',
          ),
        ];
      case 'project':
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
      default:
        return [];
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

