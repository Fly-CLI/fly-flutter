import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_project_use_case.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Strategy for project generation mode.
class ProjectGenerationExecutor
    implements GenerationExecutor<ProjectGenerationRequest> {
  /// Creates a new [ProjectGenerationExecutor].
  ProjectGenerationExecutor({
    required GenerateProjectUseCase useCase,
  }) : _useCase = useCase;

  final GenerateProjectUseCase _useCase;

  @override
  GenerationMode get mode => GenerationMode.project;

  @override
  Future<GenerationResultDto> execute(ProjectGenerationRequest request) {
    return _useCase.execute(request);
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    // Extract project name from result data if available
    final projectName =
        result.data['project_name'] as String? ?? '<project_name>';
    return [
      NextStep(
        command: 'cd $projectName',
        description: 'Navigate to the new project',
      ),
      const NextStep(
        command: 'flutter pub get',
        description: 'Install dependencies',
      ),
    ];
  }
}
