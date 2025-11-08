# Foundation

Reusable foundation components for Flutter applications following MVVM architecture pattern.

## Overview

The foundation components have been separated into individual packages for better modularity and reusability. This directory now contains only a barrel file (`foundation.dart`) that re-exports all foundation packages for convenience.

## Package Structure

Foundation components are organized into the following packages:

- **[fly_logger](../../../../packages/fly_logger)** - Structured logging infrastructure with error reporting
- **[fly_localization](../../../../packages/fly_localization)** - Localization interface abstraction
- **[fly_core](../../../../packages/fly_core)** - Core foundation package (includes dependency injection)
- **[fly_connectivity](../../../../packages/fly_connectivity)** - Network connectivity checking
- **[fly_errors](../../../../packages/fly_errors)** - Error handling and formatting
- **[fly_events](../../../../packages/fly_events)** - Event system with plugin architecture
- **[fly_navigation](../../../../packages/fly_navigation)** - Navigation service abstraction
- **[fly_operations](../../../../packages/fly_operations)** - Async operation handling with retry logic
- **[fly_mvvm](../../../../packages/fly_mvvm)** - MVVM base classes for ViewModels and Screens

## Usage

### Option 1: Use the Barrel File (Recommended)

Import everything from the barrel file:

```dart
import 'package:foundation_project/foundation/foundation.dart';
```

This re-exports all foundation packages, providing convenient access to all components.

### Option 2: Use Individual Packages

Import packages individually for better tree-shaking:

```dart
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_errors/fly_errors.dart';
import 'package:fly_operations/fly_operations.dart';
```

### Option 3: Use the Meta-Package

Alternatively, use the `fly_foundation` meta-package:

```dart
import 'package:fly_foundation/fly_foundation.dart';
```

## Architecture Principles

### 1. Reusability
All foundation components are designed to be reusable across different projects without modification. Application-specific code (like feature enums, routes, etc.) belongs in the application layer.

### 2. Dependency Injection
Foundation components accept dependencies via constructor injection, allowing for easy testing and customization.

### 3. Optional Dependencies
Foundation components work without external dependencies, using sensible defaults or fallback behavior.

### 4. Type Safety
Foundation uses strong typing throughout, avoiding `any` types and providing compile-time safety.

## Components

### Error Handling (`fly_errors`)

Provides centralized error handling and user-friendly error message formatting.

**Key Components:**
- `AppException` - Base exception class
- `ErrorMessageFormatter` - Formats technical errors into user-friendly messages
- `ErrorHandler` - Centralized error handling
- `NetworkError` - Network-specific error types

**Usage:**
```dart
import 'package:fly_errors/fly_errors.dart';

// Get formatter from provider (Riverpod)
final formatter = ref.read(errorMessageFormatterProvider);

// Format error for display
final userMessage = formatter.format(
  error,
  localizations: localizationProvider, // Optional
);

// Handle error
ErrorHandler.handleError(
  error,
  stackTrace,
  context: 'MyOperation',
);
```

### Logging (`fly_logger`)

Structured logging infrastructure with multiple backends.

**Key Components:**
- `FlyLogger` - Logging interface
- `ErrorReporter` - Error reporting interface
- `LogLevel` - Log level enumeration

**Usage:**
```dart
import 'package:fly_logger/fly_logger.dart';

final logger = FlyLogger('MyService');
logger.info('Operation started', fields: {'userId': '123'});
logger.error('Operation failed', error: exception, stackTrace: stackTrace);
```

### MVVM (`fly_mvvm`)

Base classes for MVVM architecture pattern.

**Key Components:**
- `FlyScreen` - Base screen class with lifecycle management
- `FlyViewModel` - Base ViewModel class with state management
- `FlyViewModelState` - Base state class
- Coordinators for async operations and feedback

**Usage:**
```dart
import 'package:fly_mvvm/fly_mvvm.dart';

class MyScreen extends FlyScreen<MyViewModel, MyState> {
  @override
  NotifierProvider<MyViewModel, MyState> getViewModelProvider() => myViewModelProvider;
  
  @override
  Widget buildContent(BuildContext context, MyViewModel viewModel, MyState state, WidgetRef ref) {
    return Text(state.data);
  }
}
```

### Navigation (`fly_navigation`)

Router-agnostic navigation service with generic route type support.

**Key Components:**
- `NavigationService<R>` - Abstract interface
- `DefaultNavigationService` - String-based implementation

**Usage:**
```dart
import 'package:fly_navigation/fly_navigation.dart';

final service = ref.read(navigationServiceProvider);
await service.navigateTo('/home');
```

### Operations (`fly_operations`)

Async operation handling with retry logic, network awareness, and offline queuing.

**Key Components:**
- `AsyncOperationHandler` - Handles async operations with error handling
- `AsyncOperationConfig` - Configuration for timeouts and retry behavior
- `AppResult<T>` - Result pattern for operation outcomes
- `RetryConfig` - Retry configuration with exponential backoff

**Usage:**
```dart
import 'package:fly_operations/fly_operations.dart';

final handler = AsyncOperationHandler(
  logger: logger,
  localizations: localizationProvider, // Optional
);

final result = await handler.execute(
  () => repository.fetchData(),
  timeout: AsyncOperationConfig.standardTimeout,
);

if (result.isSuccess) {
  // Handle success
} else {
  // Handle error
}
```

### Connectivity (`fly_connectivity`)

Network connectivity checking and monitoring.

**Key Components:**
- `ConnectivityService` - Connectivity checking service
- `ConnectivityChecker` - Abstract interface for connectivity checking
- `ConnectivityType` - Connectivity type enumeration

**Usage:**
```dart
import 'package:fly_connectivity/fly_connectivity.dart';

final service = ConnectivityService(logger: logger);
final hasConnection = await service.hasInternetConnection();
```

### Localization (`fly_localization`)

Abstract interface for localization strings used by foundation components.

**Key Components:**
- `FoundationLocalizationProvider` - Abstract interface
- `DefaultFoundationLocalizationProvider` - Default implementation with English fallbacks

**Usage:**
```dart
import 'package:fly_localization/fly_localization.dart';

class AppLocalizationProvider implements FoundationLocalizationProvider {
  final AppLocalizations _localizations;
  
  AppLocalizationProvider(this._localizations);
  
  @override
  String get networkErrorConnectionRecovery =>
      _localizations.networkErrorConnectionRecovery;
  
  // ... implement all other getters
}
```

### Events (`fly_events`)

Event system with plugin architecture for analytics, logging, and performance.

**Key Components:**
- `AppEvent` - Base event class
- `EventEmitter` - Event emission interface
- `EventEmitterMixin` - Mixin for easy event emission

**Usage:**
```dart
import 'package:fly_events/fly_events.dart';

class MyService with EventEmitterMixin {
  void doSomething() {
    emit(AppEvent.action('button_clicked', data: {'button': 'submit'}));
  }
}
```

### Dependency Injection (`fly_core`)

Dependency injection container abstraction (part of fly_core).

**Key Components:**
- `DependencyContainer` - Abstract interface
- `GlobalContainer` - Riverpod-based global container
- `RiverpodDependencyContainer` - Riverpod implementation

**Usage:**
```dart
import 'package:fly_core/fly_core.dart';

void main() {
  GlobalContainer.initialize();
  final logger = GlobalContainer.instance.read(loggerProvider);
}
```

## Package Dependencies

The packages follow a dependency hierarchy:

```
fly_logger (no foundation deps)
fly_localization (no foundation deps)
fly_core (no foundation deps, optional flutter_riverpod)

fly_connectivity → fly_logger
fly_errors → fly_logger, fly_localization
fly_events → fly_logger, fly_core
fly_navigation → (flutter only)

fly_operations → fly_logger, fly_connectivity, fly_errors, fly_localization, fly_events
fly_mvvm → fly_logger, fly_operations, fly_events, fly_errors
```

## Testing

Foundation components are designed to be easily testable:

```dart
// Mock dependencies
final mockLogger = MockLogger();
final mockLocalizations = MockLocalizationProvider();

// Test foundation components
final handler = AsyncOperationHandler(
  logger: mockLogger,
  localizations: mockLocalizations,
);

// Test without dependencies (uses fallbacks)
final handler = AsyncOperationHandler(logger: mockLogger);
```

## Migration from Local Foundation Directory

If you're migrating from the old local foundation directory structure:

1. **Update imports**: Change from `package:foundation_project/foundation/...` to either:
   - `package:foundation_project/foundation/foundation.dart` (barrel file)
   - Individual package imports like `package:fly_logger/fly_logger.dart`

2. **Package dependencies**: Add the foundation packages to your `pubspec.yaml` (already done in foundation_project)

3. **No code changes needed**: The API remains the same, only import paths change

## Related Documentation

- [fly_foundation Meta-Package](../../../../packages/fly_foundation/README.md) - Convenience package that re-exports all foundation packages
- Individual package READMEs in `/packages/fly_*/README.md` for detailed documentation

## Contributing

When adding new foundation components:

1. **Create a new package** in `/packages/fly_*/` following the existing package structure
2. **Keep it generic** - No application-specific code
3. **Use dependency injection** - Accept dependencies via constructor
4. **Provide fallbacks** - Work without external dependencies when possible
5. **Update this README** - Add the new package to the components list
6. **Update fly_foundation** - Add the package to the meta-package if appropriate
