import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Registry for generation mode strategies.
///
/// Provides a centralized way to look up strategies by generation mode,
/// enabling mode-agnostic command handling.
class GenerationModeRegistry {
  /// Creates a new [GenerationModeRegistry].
  ///
  /// [strategies] is a map of generation modes to their corresponding strategies.
  /// Each strategy is stored with type erasure but maintains type safety
  /// through the executeRequest method.
  GenerationModeRegistry(Map<GenerationMode, GenerationModeStrategy<GenerationRequestDto>> strategies)
      : _strategies = Map.unmodifiable(strategies);

  // Type-erased storage to allow different generic types
  final Map<GenerationMode, GenerationModeStrategy<GenerationRequestDto>> _strategies;

  /// Get the strategy for a given generation mode.
  ///
  /// Returns `null` if no strategy is registered for the given mode.
  GenerationModeStrategy<GenerationRequestDto>? forMode(GenerationMode mode) =>
      _strategies[mode];

  /// Get the strategy for a given generation mode, throwing if not found.
  ///
  /// Throws [ArgumentError] if no strategy is registered for the given mode.
  GenerationModeStrategy<GenerationRequestDto> getStrategy(GenerationMode mode) {
    final strategy = _strategies[mode];
    if (strategy == null) {
      throw ArgumentError(
        'No strategy registered for generation mode: ${mode.key}',
      );
    }
    return strategy;
  }

  /// Get all registered modes.
  Set<GenerationMode> get registeredModes => _strategies.keys.toSet();
}

