/*
import 'package:fly_state/src/interfaces/state_provider.dart';

/// Abstract interface for state management systems.
///
/// This interface provides a unified API for different state management
/// solutions (Riverpod, BLoC, Provider, GetX), allowing applications to
/// switch between them without changing application code.
///
/// ## Purpose
///
/// By using this interface, foundation components can manage state without
/// being tightly coupled to a specific state management framework. This makes
/// the foundation more flexible and allows users to choose their preferred
/// state management solution.
///
/// ## Usage
///
/// ```dart
/// // Initialize state manager
/// final stateManager = StateManagerFactory.create(StateManagementType.riverpod);
/// stateManager.initialize();
///
/// // Create a provider
/// final counterProvider = stateManager.createProvider<int>(
///   'counter',
///   initialValue: 0,
/// );
///
/// // Read value
/// final value = stateManager.read(counterProvider);
///
/// // Watch value (in widgets)
/// final value = stateManager.watch(counterProvider);
/// ```
abstract class StateManager {
  /// Initializes the state management system.
  ///
  /// Should be called once during app startup, typically in `main()`.
  /// Throws [StateError] if called more than once.
  void initialize();

  /// Creates a new state provider with the given name and initial value.
  ///
  /// [name] - Unique identifier for the provider
  /// [initialValue] - Initial value for the provider
  ///
  /// Returns a [StateProvider] instance that can be used to read and watch state.
  StateProvider<T> createProvider<T>(String name, {required T initialValue});

  /// Reads the current value from a provider without listening to changes.
  ///
  /// [provider] - The provider to read from
  ///
  /// Returns the current value.
  ///
  /// Throws [ArgumentError] if the provider is not found.
  T read<T>(StateProvider<T> provider);

  /// Watches a provider and rebuilds when the value changes.
  ///
  /// This should be used in widget build methods to reactively update
  /// the UI when state changes.
  ///
  /// [provider] - The provider to watch
  ///
  /// Returns the current value and triggers rebuilds on changes.
  ///
  /// Throws [ArgumentError] if the provider is not found.
  T watch<T>(StateProvider<T> provider);

  /// Updates the value of a provider.
  ///
  /// [provider] - The provider to update
  /// [value] - The new value
  ///
  /// Throws [ArgumentError] if the provider is not found.
  void update<T>(StateProvider<T> provider, T value);

  /// Disposes a provider and cleans up its resources.
  ///
  /// [provider] - The provider to dispose
  ///
  /// Throws [ArgumentError] if the provider is not found.
  void dispose<T>(StateProvider<T> provider);

  /// Checks if the state manager has been initialized.
  ///
  /// Returns `true` if [initialize] has been called.
  /// Returns `false` otherwise.
  bool get isInitialized;

  /// Disposes the state manager and cleans up all resources.
  ///
  /// Should be called when the state manager is no longer needed,
  /// typically during app shutdown or test teardown.
  void dispose();
}

*/
