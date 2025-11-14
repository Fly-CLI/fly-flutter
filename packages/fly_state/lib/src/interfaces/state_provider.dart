/// Abstract interface for state providers.
///
/// A state provider represents a piece of state that can be read, watched,
/// and updated. Different state management implementations will provide
/// different concrete implementations of this interface.
///
/// ## Purpose
///
/// This interface abstracts away the specific implementation details of
/// state providers from different frameworks, allowing code to work with
/// any state management solution.
///
/// ## Usage
///
/// ```dart
/// // Create a provider through StateManager
/// final counterProvider = stateManager.createProvider<int>(
///   'counter',
///   initialValue: 0,
/// );
///
/// // Use the provider
/// final value = stateManager.read(counterProvider);
/// ```
abstract class StateProvider<T> {
  /// The unique identifier for this provider.
  String get name;

  /// The current value of the provider.
  T get value;
}

