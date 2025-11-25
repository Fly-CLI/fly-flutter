import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Use case for generating features.
///
/// Encapsulates the business logic for feature generation,
/// following Clean Architecture principles.
class GenerateFeatureUseCase {
  GenerateFeatureUseCase({
    required IBrickRepository brickRepository,
    required IVariableProcessor variableProcessor,
    required IGenerationEngine generationEngine,
  }) : _brickRepository = brickRepository,
       _variableProcessor = variableProcessor,
       _generationEngine = generationEngine;

  final IBrickRepository _brickRepository;
  final IVariableProcessor _variableProcessor;
  final IGenerationEngine _generationEngine;

  /// Execute feature generation.
  ///
  /// [request] contains the generation parameters.
  ///
  /// Returns a [GenerationResultDto] with the generation result.
  Future<GenerationResultDto> execute(FeatureGenerationRequest request) async {
    try {
      // 1. Get brick
      const brickName = 'feature';
      final brick = await _brickRepository.getBrick(brickName);
      if (brick == null) {
        return const GenerationResultDto(
          success: false,
          error: 'Brick "$brickName" not found',
          data: {'brick_name': brickName},
        );
      }

      // 2. Process variables
      final processed = await _variableProcessor.process(
        rawVars: request.toVariablesMap(),
        mode: GenerationMode.feature,
        brick: brick,
      );

      if (!processed.validationResult.isValid) {
        return GenerationResultDto(
          success: false,
          error:
              'Variable validation failed: ${processed.validationResult.errors.join(', ')}',
          data: {
            'validation_errors': processed.validationResult.errors,
            'brick_name': brickName,
          },
        );
      }

      // 3. Generate
      final result = await _generationEngine.generate(
        brick: brick,
        variables: processed.values,
        outputDirectory: request.outputDirectory,
        dryRun: request.dryRun,
      );

      return GenerationResultDto.fromResult(result);
    } catch (e) {
      return GenerationResultDto(
        success: false,
        error: 'Generation failed: $e',
        data: {'error_type': e.runtimeType.toString()},
      );
    }
  }
}
