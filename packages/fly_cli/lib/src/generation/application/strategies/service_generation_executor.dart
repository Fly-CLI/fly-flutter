import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_service_use_case.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Strategy for service generation mode.
class ServiceGenerationExecutor
    implements GenerationExecutor<ServiceGenerationRequest> {
  /// Creates a new [ServiceGenerationExecutor].
  ServiceGenerationExecutor({
    required GenerateServiceUseCase useCase,
  }) : _useCase = useCase;

  final GenerateServiceUseCase _useCase;

  @override
  GenerationMode get mode => GenerationMode.service;

  @override
  Future<GenerationResultDto> execute(ServiceGenerationRequest request) {
    return _useCase.execute(request);
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    return [
      const NextStep(
        command: 'flutter pub get',
        description: 'Install dependencies',
      ),
    ];
  }
}
