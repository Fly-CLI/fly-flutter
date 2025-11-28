import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_request_factory.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart'
    show BrickId, GenerationMode;
import 'package:fly_cli/src/generation/generation_variable_builder.dart';

/// Profile defining all mode-specific components for a generation mode.
///
/// **This is the single source of truth for all mode-specific logic and dependencies.**
///
/// This profile encapsulates everything needed for a generation mode:
/// - Mode identification and configuration (mode, brickId)
/// - Mode-specific dependencies (variableProcessor, variableBuilder)
/// - Mode-specific behavior (executor, requestFactory)
///
/// When adding a new generation mode, create a new profile instance with the correct
/// brick, processor, builder, factory, and executor. All other components obtain their
/// mode-specific logic and dependencies directly from profiles - there are no alternative
/// configuration structures or wrappers.
///
/// This is a pure value type with no business logic, making it safe to use
/// at the application layer as it only references existing abstractions.
class GenerationModeProfile {
  /// Creates a new [GenerationModeProfile].
  ///
  /// [mode] - The generation mode this profile represents
  /// [brickId] - The brick/template identifier (e.g., 'project', 'feature', 'service')
  /// [variableProcessor] - The variable processor for this mode
  /// [executor] - The generation mode executor for this mode
  /// [variableBuilder] - The variable builder for this mode
  /// [requestFactory] - The request factory for this mode
  const GenerationModeProfile({
    required this.mode,
    required this.brickId,
    required this.variableProcessor,
    required this.executor,
    required this.variableBuilder,
    required this.requestFactory,
  });

  /// The generation mode this profile represents.
  final GenerationMode mode;

  /// The brick/template identifier used for this mode.
  ///
  /// This is the key used to look up the brick in the brick repository
  /// (e.g., 'project', 'feature', 'service').
  final BrickId brickId;

  /// The variable processor for this mode.
  ///
  /// Handles variable derivation, transformation, and validation
  /// specific to this generation mode.
  final IVariableProcessor variableProcessor;

  /// The generation mode executor for this mode.
  ///
  /// Encapsulates mode-specific generation execution logic and
  /// next-step suggestions.
  final GenerationExecutor<GenerationRequestDto> executor;

  /// The variable builder for this mode.
  ///
  /// Handles collecting and normalizing variables from CLI flags,
  /// interactive prompts, or manifest data.
  final GenerationVariableBuilder variableBuilder;

  /// The request factory for this mode.
  ///
  /// Handles constructing request DTOs from variable maps with
  /// mode-specific defaults and type conversions.
  final GenerationRequestFactory requestFactory;
}
