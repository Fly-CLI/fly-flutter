/*
import 'package:fly_state/src/interfaces/state_manager.dart';
import 'package:fly_state/src/implementations/riverpod/riverpod_state_manager.dart';

/// Enumeration of supported state management types.
enum StateManagementType {
  /// Riverpod state management
  riverpod,

  /// BLoC state management (not yet implemented)
  bloc,

  /// Provider state management (not yet implemented)
  provider,

  /// GetX state management (not yet implemented)
  getx,
}

/// Factory for creating state management instances.
///
/// This factory provides a centralized way to create state management
/// instances based on the selected state management type.
///
/// ## Usage
///
/// ```dart
/// // Create a Riverpod state manager
/// final stateManager = StateManagerFactory.create(StateManagementType.riverpod);
/// stateManager.initialize();
/// ```
class StateManagerFactory {
  /// Creates a state manager instance for the given type.
  ///
  /// [type] - The type of state management to use
  ///
  /// Returns a [StateManager] instance.
  ///
  /// Throws [ArgumentError] if the type is not supported or not yet implemented.
  static StateManager create(StateManagementType type) {
    switch (type) {
      case StateManagementType.riverpod:
        return RiverpodStateManager();
      case StateManagementType.bloc:
        throw UnimplementedError(
          'BLoC state manager is not yet implemented. '
          'Use StateManagementType.riverpod for now.',
        );
      case StateManagementType.provider:
        throw UnimplementedError(
          'Provider state manager is not yet implemented. '
          'Use StateManagementType.riverpod for now.',
        );
      case StateManagementType.getx:
        throw UnimplementedError(
          'GetX state manager is not yet implemented. '
          'Use StateManagementType.riverpod for now.',
        );
    }
  }

  /// Creates a state manager from a string identifier.
  ///
  /// [identifier] - String identifier (e.g., 'riverpod', 'bloc', 'provider', 'getx')
  ///
  /// Returns a [StateManager] instance.
  ///
  /// Throws [ArgumentError] if the identifier is not recognized.
  static StateManager createFromString(String identifier) {
    final type = StateManagementType.values.firstWhere(
      (type) => type.name == identifier.toLowerCase(),
      orElse: () => throw ArgumentError(
        'Unknown state management type: $identifier. '
        'Supported types: ${StateManagementType.values.map((e) => e.name).join(", ")}',
      ),
    );
    return create(type);
  }
}

*/
