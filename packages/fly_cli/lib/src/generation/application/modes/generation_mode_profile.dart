import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart'
    show BrickId, GenerationMode;

/// Profile defining all mode-specific components for a generation mode.
///
/// This serves as the single source of truth for wiring generation modes,
/// encapsulating all mode-specific dependencies in one place. When adding
/// a new generation mode, only a new profile entry needs to be registered.
///
/// This is a pure value type with no business logic, making it safe to use
/// at the application layer as it only references existing abstractions.
class GenerationModeProfile {
  /// Creates a new [GenerationModeProfile].
  ///
  /// [mode] - The generation mode this profile represents
  /// [brickId] - The brick/template identifier (e.g., 'project', 'feature', 'service')
  /// [variableProcessor] - The variable processor for this mode
  /// [strategy] - The generation mode strategy for this mode
  const GenerationModeProfile({
    required this.mode,
    required this.brickId,
    required this.variableProcessor,
    required this.strategy,
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

  /// The generation mode strategy for this mode.
  ///
  /// Encapsulates mode-specific generation execution logic and
  /// next-step suggestions.
  final GenerationModeStrategy<GenerationRequestDto> strategy;
}