import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';

/// Registry for generation mode strategies.
///
/// Provides a centralized way to look up strategies by generation mode,
/// enabling mode-agnostic command handling. This registry serves as the
/// single source of truth for all generation mode implementations.
///
/// All generation modes must be registered here to be available for use.
/// New modes should be added by implementing [GenerationModeStrategy] and
/// registering the implementation in the dependency injection container.
class GenerationModeRegistry {
  /// Creates a new [GenerationModeRegistry].
  ///
  /// [strategies] is a map of generation modes to their corresponding strategies.
  /// Each strategy is stored with type erasure but maintains type safety
  /// through the [execute] method which performs runtime type checking.
  GenerationModeRegistry(
    Map<GenerationMode, GenerationModeStrategy<GenerationRequestDto>>
    strategies,
  ) : _strategies = Map.unmodifiable(strategies);

  // Type-erased storage to allow different generic types
  // The strategies are stored as base type but each concrete strategy
  // implements GenerationModeStrategy<T> where T is a specific request type
  final Map<GenerationMode, GenerationModeStrategy<GenerationRequestDto>>
  _strategies;

  /// Execute generation using the strategy for the request's mode.
  ///
  /// This is the preferred method for executing generation as it automatically
  /// routes requests to the correct strategy based on the request's mode.
  ///
  /// [request] contains the generation parameters. The request's mode determines
  /// which strategy will handle the execution.
  ///
  /// Returns a [GenerationResultDto] with the generation result.
  ///
  /// Throws [ArgumentError] if no strategy is registered for the request's mode.
  /// Throws [TypeError] if the request type doesn't match the strategy's expected type.
  Future<GenerationResultDto> execute(GenerationRequestDto request) async {
    final strategy = getStrategy(request.mode);

    // Type-safe execution: each strategy knows how to handle its specific request type
    // The runtime type of the request matches the strategy's generic type parameter
    return strategy.execute(request);
  }

  /// Get the strategy for a given generation mode.
  ///
  /// Returns `null` if no strategy is registered for the given mode.
  GenerationModeStrategy<GenerationRequestDto>? forMode(GenerationMode mode) =>
      _strategies[mode];

  /// Get the strategy for a given generation mode, throwing if not found.
  ///
  /// Throws [ArgumentError] if no strategy is registered for the given mode.
  GenerationModeStrategy<GenerationRequestDto> getStrategy(
    GenerationMode mode,
  ) {
    final strategy = _strategies[mode];
    if (strategy == null) {
      throw ArgumentError(
        'No strategy registered for generation mode: ${mode.key}. '
        'Available modes: ${_strategies.keys.map((m) => m.key).join(", ")}',
      );
    }
    return strategy;
  }

  /// Get all registered modes.
  ///
  /// Returns a set of all [GenerationMode] values that have strategies registered.
  Set<GenerationMode> get registeredModes => _strategies.keys.toSet();

  /// Check if a generation mode is registered.
  ///
  /// Returns `true` if a strategy is registered for the given mode, `false` otherwise.
  bool isRegistered(GenerationMode mode) => _strategies.containsKey(mode);
}
