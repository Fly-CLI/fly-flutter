import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Use case for generating features.
///
/// Encapsulates the business logic for feature generation,
/// following Clean Architecture principles.
class GenerateFeatureUseCase {
  /// Constructor for [GenerateFeatureUseCase].
  ///
  /// [workflowOrchestrator] is used to orchestrate the generation process.
  GenerateFeatureUseCase({
    required IWorkflowOrchestrator workflowOrchestrator,
  }) : _workflowOrchestrator = workflowOrchestrator;

  final IWorkflowOrchestrator _workflowOrchestrator;

  /// Execute feature generation.
  ///
  /// [request] contains the generation parameters.
  ///
  /// Returns a [GenerationResultDto] with the generation result.
  Future<GenerationResultDto> execute(FeatureGenerationRequest request) async {
    try {
      // Delegate orchestration to the workflow orchestrator, which handles
      // brick discovery, variable processing, validation, and generation.
      final result = await _workflowOrchestrator.executeWorkflow(
        mode: GenerationMode.feature,
        variables: request.toJson(),
        outputDirectory: request.outputDirectory,
        dryRun: request.dryRun,
      );

      return GenerationResultDto.fromResult(result);
    } catch (e) {
      return GenerationResultDto(
        success: false,
        error: 'Feature generation failed: $e',
        data: {'error_type': e.runtimeType.toString()},
      );
    }
  }
}
