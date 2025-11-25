import 'package:fly_cli/src/features/commands/domain/fly_command.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command_strategy.dart';

/// Unified registry for Fly command strategies and metadata
///
/// This registry serves as the single source of truth for command strategy
/// access, replacing both FlyCommandStrategyRegistry and providing strategy
/// access for CommandMetadataRegistry.
///
/// Uses the factory map defined in FlyCommandExtension as the source of truth.
class FlyCommandRegistry {
  FlyCommandRegistry._();

  static FlyCommandRegistry? _instance;

  /// Get the singleton instance of FlyCommandRegistry
  static FlyCommandRegistry get instance {
    _instance ??= FlyCommandRegistry._();
    return _instance!;
  }

  /// Cached strategy instances
  final Map<FlyCommand, FlyCommandDescriptor> _strategies = {};

  /// Gets the strategy for the given command type
  ///
  /// Creates and caches the strategy instance on first access using the
  /// exhaustive switch-based factory from FlyCommandExtension.
  FlyCommandDescriptor getStrategy(FlyCommand commandType) {
    return _strategies.putIfAbsent(
      commandType,
      () => commandType.strategyFactory(),
    );
  }

  /// Gets all strategy instances
  ///
  /// Creates strategies for all registered commands if not already cached.
  Map<FlyCommand, FlyCommandDescriptor> getAllStrategies() {
    final result = <FlyCommand, FlyCommandDescriptor>{};
    for (final commandType in FlyCommand.values) {
      result[commandType] = getStrategy(commandType);
    }
    return result;
  }

  /// Check if a command type has a registered strategy
  ///
  /// Always returns true since all enum values have factories (exhaustiveness guaranteed).
  bool hasStrategy(FlyCommand commandType) {
    return true;
  }

  /// Clear all cached strategies (useful for testing)
  void clear() {
    _strategies.clear();
  }

  /// Get the number of registered strategies
  ///
  /// Returns the total number of enum values (exhaustiveness guaranteed).
  int get strategyCount => FlyCommand.values.length;
}
