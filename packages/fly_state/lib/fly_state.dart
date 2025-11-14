/// Fly State - State management abstraction layer
///
/// This package provides a unified interface for state management in Flutter
/// applications, allowing you to switch between different state management
/// solutions (Riverpod, BLoC, Provider, GetX) without changing your application code.
library fly_state;

// Interfaces
export 'src/interfaces/state_manager.dart';
export 'src/interfaces/state_provider.dart';

// Factory
export 'src/factory/state_manager_factory.dart';

// Implementations (export only the ones that are implemented)
export 'src/implementations/riverpod/riverpod_state_manager.dart';

