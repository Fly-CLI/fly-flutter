import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/domain/generation_error_mapper.dart';

/// Use case for generating projects.
///
/// Encapsulates the business logic for project generation,
/// following Clean Architecture principles.
/// Uses workflow orchestrator for complex multi-step generation.
class GenerateProjectUseCase {
  /// Constructor for [GenerateProjectUseCase].
  ///
  /// [workflowOrchestrator] is used to orchestrate the generation process.
  /// [profile] provides all mode-specific configuration for project generation.
  GenerateProjectUseCase({
    required IWorkflowOrchestrator workflowOrchestrator,
    required GenerationModeProfile profile,
  }) : _workflowOrchestrator = workflowOrchestrator,
       _profile = profile;

  final IWorkflowOrchestrator _workflowOrchestrator;
  final GenerationModeProfile _profile;

  /// Execute project generation.
  ///
  /// [request] contains the generation parameters.
  ///
  /// Returns a [GenerationResultDto] with the generation result.
  Future<GenerationResultDto> execute(ProjectGenerationRequest request) async {
    try {
      // For project generation, use workflow orchestrator
      // which handles the complex multi-step process.
      // The orchestrator gets all mode-specific dependencies from the profile.
      final result = await _workflowOrchestrator.executeWorkflow(
        profile: _profile,
        variables: request.toJson(),
        outputDirectory: request.outputDirectory,
        dryRun: request.dryRun,
      );

      return GenerationResultDto.fromResult(result);
    } catch (e) {
      return GenerationResultDto(
        success: false,
        error: 'Project generation failed: $e',
        errorType: GenerationErrorMapper.fromException(e),
        data: {'error_type': e.runtimeType.toString()},
      );
    }
  }
}
