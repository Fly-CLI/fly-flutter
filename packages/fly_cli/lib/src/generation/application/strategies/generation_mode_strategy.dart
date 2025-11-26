import 'package:fly_brick_composer/fly_brick_composer.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Strategy interface for generation modes.
///
/// Encapsulates mode-specific generation logic, including execution
/// and next-step suggestions. This allows the command handler to be
/// mode-agnostic and reduces coupling when adding new generation modes.
///
/// [T] is the specific request type for this strategy (e.g., FeatureGenerationRequest).
abstract class GenerationModeStrategy<T extends GenerationRequestDto> {
  /// The generation mode this strategy handles.
  GenerationMode get mode;

  /// Execute generation for this mode.
  ///
  /// [request] contains the generation parameters.
  ///
  /// Returns a [GenerationResultDto] with the generation result.
  Future<GenerationResultDto> execute(T request);

  /// Get next steps for successful generation.
  ///
  /// [result] is the successful generation result (may be used to customize
  /// next steps based on what was generated).
  ///
  /// Returns a list of suggested next steps for the user.
  List<NextStep> getNextSteps(GenerationResultDto result);
}

