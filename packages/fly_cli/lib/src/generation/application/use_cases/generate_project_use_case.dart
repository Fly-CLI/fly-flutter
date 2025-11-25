import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Use case for generating projects.
///
/// Encapsulates the business logic for project generation,
/// following Clean Architecture principles.
/// Uses workflow orchestrator for complex multi-step generation.
class GenerateProjectUseCase {
  GenerateProjectUseCase({
    required IWorkflowOrchestrator workflowOrchestrator,
  }) : _workflowOrchestrator = workflowOrchestrator;

  final IWorkflowOrchestrator _workflowOrchestrator;

  /// Execute project generation.
  ///
  /// [request] contains the generation parameters.
  ///
  /// Returns a [GenerationResultDto] with the generation result.
  Future<GenerationResultDto> execute(ProjectGenerationRequest request) async {
    try {
      // For project generation, use workflow orchestrator
      // which handles the complex multi-step process
      final result = await _workflowOrchestrator.executeWorkflow(
        mode: GenerationMode.project,
        variables: request.variables,
        outputDirectory: request.outputDirectory,
        dryRun: request.dryRun,
      );

      return GenerationResultDto.fromResult(result);
    } catch (e) {
      return GenerationResultDto(
        success: false,
        error: 'Project generation failed: $e',
        data: {'error_type': e.runtimeType.toString()},
      );
    }
  }
}
