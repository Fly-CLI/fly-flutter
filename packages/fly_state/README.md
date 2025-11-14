# Fly State

State management abstraction layer for Flutter applications.

## Overview

Fly State provides a unified interface for state management in Flutter applications, allowing you to switch between different state management solutions (Riverpod, BLoC, Provider, GetX) without changing your application code.

## Features

- **Framework-agnostic API**: Write code once, use any state management solution
- **Multiple implementations**: Support for Riverpod, BLoC, Provider, and GetX (Riverpod implemented, others coming soon)
- **Type-safe**: Full type safety with generics
- **Testable**: Easy to mock and test

## Usage

### Basic Usage

```dart
import 'package:fly_state/fly_state.dart';

// Create a state manager
final stateManager = StateManagerFactory.create(StateManagementType.riverpod);
stateManager.initialize();

// Create a provider
final counterProvider = stateManager.createProvider<int>(
  'counter',
  initialValue: 0,
);

// Read value
final value = stateManager.read(counterProvider);

// Update value
stateManager.update(counterProvider, 42);
```

### With Widgets

```dart
// In your widget
Consumer(
  builder: (context, ref, child) {
    // Access the Riverpod container directly for watching
    final value = ref.watch(counterProvider.provider);
    return Text('Count: $value');
  },
)
```

## Supported State Management Types

- ✅ **Riverpod**: Fully implemented
- 🚧 **BLoC**: Coming soon
- 🚧 **Provider**: Coming soon
- 🚧 **GetX**: Coming soon

## Architecture

The package follows a factory pattern with interface-based design:

- `StateManager`: Abstract interface for state management
- `StateProvider`: Abstract interface for state providers
- `StateManagerFactory`: Factory for creating state managers
- Implementations: Concrete implementations for each framework

## License

See LICENSE file for details.

