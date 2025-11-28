import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Strategy for feature generation mode.
class FeatureGenerationExecutor
    implements GenerationExecutor<FeatureGenerationRequest> {
  /// Creates a new [FeatureGenerationExecutor].
  FeatureGenerationExecutor({
    required GenerateFeatureUseCase useCase,
  }) : _useCase = useCase;

  final GenerateFeatureUseCase _useCase;

  @override
  GenerationMode get mode => GenerationMode.feature;

  @override
  Future<GenerationResultDto> execute(FeatureGenerationRequest request) {
    return _useCase.execute(request);
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    return [
      const NextStep(
        command: 'flutter run',
        description: 'Run the application to see the new screen',
      ),
    ];
  }
}
