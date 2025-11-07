# Foundation

Reusable foundation components for Flutter applications following MVVM architecture pattern.

## Overview

The foundation directory contains core, reusable components that provide:
- **Error Handling** - Centralized error management and user-friendly message formatting
- **Logging** - Structured logging infrastructure
- **MVVM** - Base classes for ViewModels and Screens
- **Navigation** - Router-agnostic navigation service
- **Operations** - Async operation handling with retry logic and network awareness
- **Connectivity** - Network connectivity checking
- **Localization** - Abstract localization interface

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

### Error Handling (`error/`)

Provides centralized error handling and user-friendly error message formatting.

**Key Components:**
- `AppException` - Base exception class
- `ErrorMessageFormatter` - Formats technical errors into user-friendly messages
- `ErrorHandler` - Centralized error handling
- `NetworkError` - Network-specific error types
- `CustomErrorHandler` - Flutter error handling override

**Usage:**
```dart
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

### Logging (`logger/`)

Structured logging infrastructure with multiple backends.

**Key Components:**
- `Logger` - Abstract logging interface
- `FlyLogger` - Concrete implementation with console, structured logging, and Crashlytics

**Usage:**
```dart
final logger = FlyLogger('MyService');
logger.info('Operation started', fields: {'userId': '123'});
logger.error('Operation failed', error: exception, stackTrace: stackTrace);
```

### MVVM (`mvvm/`)

Base classes for MVVM architecture pattern.

**Key Components:**
- `FlyScreen` - Base screen class with lifecycle management
- `FlyViewModel` - Base ViewModel class with state management
- `FlyViewModelState` - Base state class
- Coordinators for async operations and feedback

**Usage:**
```dart
class MyScreen extends FlyScreen<MyViewModel, MyState> {
  @override
  NotifierProvider<MyViewModel, MyState> getViewModelProvider() => myViewModelProvider;
  
  @override
  Widget buildContent(BuildContext context, MyViewModel viewModel, MyState state, WidgetRef ref) {
    return Text(state.data);
  }
}
```

### Navigation (`navigation/`)

Router-agnostic navigation service with generic route type support.

**Key Components:**
- `NavigationService<R>` - Abstract interface
- `DefaultNavigationService` - String-based implementation
- `FlyRouter` - Feature enum-based implementation (uses application's FeatureScreenType)

**Usage:**
```dart
// String-based
final service = ref.read(navigationServiceProvider);
await service.navigateTo('/home');

// Feature enum-based (FeatureScreenType defined in application layer)
await FlyRouter.instance.navigateTo(FeatureScreenType.home);
```

**Important:** Feature enums (like `FeatureScreenType`) should be defined in the application layer, not in foundation. See `navigation/README.md` for details.

### Operations (`operations/`)

Async operation handling with retry logic, network awareness, and offline queuing.

**Key Components:**
- `AsyncOperationHandler` - Handles async operations with error handling
- `AsyncOperationConfig` - Configuration for timeouts and retry behavior
- `AppResult<T>` - Result pattern for operation outcomes
- `RetryConfig` - Retry configuration with exponential backoff

**Usage:**
```dart
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

### Connectivity (`connectivity/`)

Network connectivity checking and monitoring.

**Key Components:**
- `ConnectivityService` - Wraps device condition service for connectivity checking

**Usage:**
```dart
final service = ConnectivityService(logger: logger);
final hasConnection = await service.hasInternetConnection();
```

### Localization (`localization/`)

Abstract interface for localization strings used by foundation components.

**Key Components:**
- `FoundationLocalizationProvider` - Abstract interface

**Usage:**
See [Localization Provider Pattern](#localization-provider-pattern) below.

## Localization Provider Pattern

Foundation components use an abstract `FoundationLocalizationProvider` interface to avoid hardcoded dependencies on application-specific localization systems.

### Why This Pattern?

- **Reusability** - Foundation can work with any localization system
- **Testability** - Easy to mock for testing
- **Flexibility** - Applications can use Flutter gen-l10n, i18n, or custom systems

### Implementation

1. **Create Implementation:**
```dart
class AppLocalizationProvider implements FoundationLocalizationProvider {
  final AppLocalizations _localizations;
  
  AppLocalizationProvider(this._localizations);
  
  @override
  String get networkErrorConnectionRecovery =>
      _localizations.networkErrorConnectionRecovery;
  
  // ... implement all other getters
}
```

2. **Register Provider:**
```dart
final foundationLocalizationProvider = Provider<FoundationLocalizationProvider?>((ref) {
  try {
    final appLocalizations = localizations; // Your app's localization
    return AppLocalizationProvider(appLocalizations);
  } catch (e) {
    return null; // Foundation will use fallback messages
  }
});
```

3. **Use in Foundation Components:**
```dart
final handler = AsyncOperationHandler(
  logger: logger,
  localizations: ref.read(foundationLocalizationProvider),
);
```

### Fallback Behavior

If `FoundationLocalizationProvider` is not provided (null), foundation components use sensible English fallback messages. This ensures foundation works even without localization setup.

## External Dependencies

Foundation components may require external dependencies. See [DEPENDENCIES.md](./DEPENDENCIES.md) for a complete list.

**Key Dependencies:**
- `DeviceConditionService` - For connectivity checking (optional, has default)
- `FoundationLocalizationProvider` - For localized messages (optional, uses fallbacks)
- `OfflineQueueManager` - For offline operation queuing (optional)

All dependencies are **optional** - foundation works without them using fallback behavior.

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

## Usage Examples

### Basic ViewModel with Async Operations

```dart
class MyViewModel extends FlyViewModel<MyState> {
  @override
  MyState build() => MyState.initial();
  
  Future<void> loadData() async {
    final result = await runAsyncOperation(
      () => repository.fetchData(),
      errorMessage: 'Failed to load data',
    );
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(data: result.data);
    }
  }
}
```

### Error Handling

```dart
// Get formatter from provider (Riverpod)
final formatter = ref.read(errorMessageFormatterProvider);

try {
  await someOperation();
} catch (e, stackTrace) {
  final userMessage = formatter.format(
    e,
    localizations: localizationProvider,
  );
  showError(userMessage);
}
```

### Navigation

```dart
// In a screen
class MyScreen extends FlyScreen<MyViewModel, MyState> {
  void navigateToDetails(WidgetRef ref) {
    // String-based
    ref.read(navigationServiceProvider).navigateTo('/details');
    
    // Or feature enum-based
    FlyRouter.instance.navigateTo(FeatureScreenType.details);
  }
}
```

## Project Structure

```
foundation/
├── connectivity/          # Network connectivity checking
├── error/                # Error handling and formatting
├── localization/          # Localization interface
├── logger/               # Logging infrastructure
├── mvvm/                 # MVVM base classes
│   ├── screen/           # FlyScreen base class
│   └── view_model/       # FlyViewModel and coordinators
├── navigation/           # Navigation service
├── operations/           # Async operation handling
├── DEPENDENCIES.md       # External dependencies documentation
└── README.md            # This file
```

## Migration Guide

If migrating from an older version:

1. **FeatureScreenType Enum** - Now in application layer (`shared/navigation/feature_screen_type.dart`)
2. **Localization** - Use `FoundationLocalizationProvider` interface instead of direct imports
3. **AsyncOperationHandler** - Now accepts optional `localizations` parameter

See individual component documentation for detailed migration guides.

## Best Practices

1. **Always use foundation components** for common operations (error handling, logging, async operations)
2. **Provide localization provider** for better user experience
3. **Keep application-specific code** out of foundation
4. **Use dependency injection** for testability
5. **Follow MVVM pattern** using foundation's base classes

## Related Documentation

- [Navigation Service](./navigation/README.md) - Navigation service details
- [Async Operations](./operations/ASYNC_OPERATIONS.md) - Async operation handling guide
- [Dependencies](./DEPENDENCIES.md) - External dependencies documentation
- [Foundation Review Report](./FOUNDATION_REVIEW_REPORT.md) - Architecture review

## Contributing

When adding new foundation components:

1. **Keep it generic** - No application-specific code
2. **Use dependency injection** - Accept dependencies via constructor
3. **Provide fallbacks** - Work without external dependencies when possible
4. **Document dependencies** - Update DEPENDENCIES.md
5. **Add tests** - Ensure components are testable in isolation

