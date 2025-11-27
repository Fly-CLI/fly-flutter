import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
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
/// registering the implementation via a [GenerationModeProfile] in the
/// dependency injection container.
///
/// **Profiles are mandatory**: This registry must be constructed from mode
/// profiles to ensure a single source of truth for all mode-specific wiring.
class GenerationModeRegistry {
  /// Creates a new [GenerationModeRegistry] from mode profiles.
  ///
  /// This constructor uses the centralized mode profiles as the single source
  /// of truth. The registry extracts strategies from the profiles while
  /// maintaining access to the full profile data (brick IDs, processors, etc.).
  ///
  /// [profiles] is a map of generation modes to their corresponding profiles.
  /// Each profile contains all mode-specific components (strategy, processor, brick id).
  ///
  /// Throws [ArgumentError] if [profiles] is empty.
  GenerationModeRegistry(
    Map<GenerationMode, GenerationModeProfile> profiles,
  ) : _profiles = Map.unmodifiable(profiles) {
    if (profiles.isEmpty) {
      throw ArgumentError('Cannot create registry with empty profiles map');
    }

    // Extract strategies from profiles
    final strategies =
        <GenerationMode, GenerationModeStrategy<GenerationRequestDto>>{};
    for (final entry in profiles.entries) {
      strategies[entry.key] = entry.value.strategy;
    }
    _strategies = Map.unmodifiable(strategies);
  }

  // Type-erased storage to allow different generic types
  // The strategies are stored as base type but each concrete strategy
  // implements GenerationModeStrategy<T> where T is a specific request type
  late final Map<GenerationMode, GenerationModeStrategy<GenerationRequestDto>>
  _strategies;

  /// Profiles map - the single source of truth for all mode-specific wiring.
  final Map<GenerationMode, GenerationModeProfile> _profiles;

  /// Get the profile for a given generation mode.
  ///
  /// Returns the profile for the mode, or `null` if the mode is not registered.
  GenerationModeProfile? getProfile(GenerationMode mode) => _profiles[mode];

  /// Get the brick ID for a given generation mode.
  ///
  /// Returns the brick ID from the mode profile, or `null` if the mode is not registered.
  BrickId? getBrickId(GenerationMode mode) => _profiles[mode]?.brickId;

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
