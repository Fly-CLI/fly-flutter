import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/domain/generation_error_mapper.dart';

/// Use case for generating features.
///
/// Encapsulates the business logic for feature generation,
/// following Clean Architecture principles.
class GenerateFeatureUseCase {
  /// Constructor for [GenerateFeatureUseCase].
  ///
  /// [workflowOrchestrator] is used to orchestrate the generation process.
  /// [profile] provides all mode-specific configuration for feature generation.
  GenerateFeatureUseCase({
    required IWorkflowOrchestrator workflowOrchestrator,
    required GenerationModeProfile profile,
  }) : _workflowOrchestrator = workflowOrchestrator,
       _profile = profile;

  final IWorkflowOrchestrator _workflowOrchestrator;
  final GenerationModeProfile _profile;

  /// Execute feature generation.
  ///
  /// [request] contains the generation parameters.
  ///
  /// Returns a [GenerationResultDto] with the generation result.
  Future<GenerationResultDto> execute(FeatureGenerationRequest request) async {
    try {
      // Delegate orchestration to the workflow orchestrator, which handles
      // brick discovery, variable processing, validation, and generation.
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
        error: 'Feature generation failed: $e',
        errorType: GenerationErrorMapper.fromException(e),
        data: {'error_type': e.runtimeType.toString()},
      );
    }
  }
}
