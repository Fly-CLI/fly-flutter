<!-- e28feb0a-4168-4ab9-aa44-b14bd1948acd e8520853-72a7-4682-b6ee-df1628d87cd4 -->
# Foundation Package Separation Plan

## Analysis Summary

The foundation directory contains 9 distinct modules that can be separated into independent packages:

1. **connectivity/** - Network connectivity checking
2. **di/** - Dependency injection abstractions
3. **error/** - Error handling and formatting
4. **events/** - Event system with plugin architecture
5. **localization/** - Localization interface
6. **logger/** - Structured logging
7. **mvvm/** - MVVM base classes
8. **navigation/** - Navigation service abstraction
9. **operations/** - Async operation handling

## Package Structure Recommendations

### 1. `fly_logger` (from logger/)

**Purpose**: Structured logging infrastructure with error reporting

**Dependencies**:

- `logging` (external)
- `flutter` (for kDebugMode)

**Exports**: FlyLogger interface, ErrorReporter interface, LogLevel enum

**Location**: `/packages/fly_logger`

### 2. `fly_connectivity` (from connectivity/)

**Purpose**: Network connectivity checking with pluggable implementations

**Dependencies**:

- `fly_logger` (for logging)

**Exports**: ConnectivityService, ConnectivityChecker interface, ConnectivityType

**Location**: `/packages/fly_connectivity`

### 3. `fly_localization` (from localization/)

**Purpose**: Abstract localization interface for foundation components

**Dependencies**: None (pure interface)

**Exports**: FoundationLocalizationProvider interface, DefaultFoundationLocalizationProvider

**Location**: `/packages/fly_localization`

### 4. `fly_errors` (from error/)

**Purpose**: Centralized error handling and user-friendly message formatting

**Dependencies**:

- `fly_logger` (for logging)
- `fly_localization` (for localized error messages)

**Exports**: AppException, ErrorHandler, ErrorMessageFormatter, NetworkError

**Location**: `/packages/fly_errors`

### 5. `fly_events` (from events/)

**Purpose**: Event system with plugin architecture for analytics, logging, and performance

**Dependencies**:

- `fly_logger` (for logging)
- `fly_di` (for dependency injection)
- `json_annotation` (external, for serialization)
- `fly_feedback` (external package, for feedback events)

**Exports**: AppEvent, EventEmitter, EventEmitterMixin, plugins

**Location**: `/packages/fly_events`

### 6. `fly_di` (from di/)

**Purpose**: Dependency injection container abstraction

**Dependencies**:

- `flutter_riverpod` (for Riverpod implementation, optional)

**Exports**: DependencyContainer interface, RiverpodDependencyContainer, GlobalContainer

**Location**: `/packages/fly_di`

### 7. `fly_navigation` (from navigation/)

**Purpose**: Router-agnostic navigation service with generic route type support

**Dependencies**:

- `flutter` (for Navigator)

**Exports**: NavigationService interface, DefaultNavigationService

**Location**: `/packages/fly_navigation`

### 8. `fly_operations` (from operations/)

**Purpose**: Async operation handling with retry logic, network awareness, and offline queuing

**Dependencies**:

- `fly_logger` (for logging)
- `fly_connectivity` (for network checking)
- `fly_errors` (for error handling)
- `fly_localization` (for localized messages)
- `fly_events` (for event emission)
- `uuid` (external)

**Exports**: AsyncOperationHandler, AppResult, RetryConfig, OfflineQueue interface, AsyncOperationConfig

**Location**: `/packages/fly_operations`

### 9. `fly_mvvm` (from mvvm/)

**Purpose**: MVVM base classes for ViewModels and Screens

**Dependencies**:

- `fly_logger` (for logging)
- `fly_operations` (for async operations)
- `fly_events` (for event emission)
- `fly_errors` (for error handling)
- `fly_feedback` (external package)
- `flutter_riverpod` (for state management)

**Exports**: FlyScreen, FlyViewModel, FlyViewModelState, coordinators

**Location**: `/packages/fly_mvvm`

## Dependency Graph

```
fly_logger (no foundation deps)
fly_localization (no foundation deps)
fly_di (no foundation deps, optional flutter_riverpod)

fly_connectivity → fly_logger
fly_errors → fly_logger, fly_localization
fly_events → fly_logger, fly_di
fly_navigation → (flutter only)

fly_operations → fly_logger, fly_connectivity, fly_errors, fly_localization, fly_events
fly_mvvm → fly_logger, fly_operations, fly_events, fly_errors
```

## Implementation Steps

1. **Create base packages** (no foundation dependencies):

   - `fly_logger`
   - `fly_localization`
   - `fly_di`

2. **Create dependent packages**:

   - `fly_connectivity` (depends on fly_logger)
   - `fly_errors` (depends on fly_logger, fly_localization)
   - `fly_events` (depends on fly_logger, fly_di)
   - `fly_navigation` (no foundation deps)

3. **Create higher-level packages**:

   - `fly_operations` (depends on multiple foundation packages)
   - `fly_mvvm` (depends on multiple foundation packages)

4. **Update foundation_project** to use new packages instead of local foundation directory

5. **Create barrel package** (optional): `fly_foundation` that re-exports all packages for convenience

## Package Naming Rationale

- **fly_logger**: Clear, descriptive name for logging functionality
- **fly_connectivity**: Describes network connectivity checking
- **fly_localization**: Localization interface abstraction
- **fly_errors**: Error handling and formatting
- **fly_events**: Event system with plugins
- **fly_di**: Dependency injection (standard abbreviation)
- **fly_navigation**: Navigation service abstraction
- **fly_operations**: Async operations handling
- **fly_mvvm**: MVVM architecture base classes

All names follow the `fly_*` convention consistent with existing packages (`fly_core`, `fly_networking`, `fly_feedback`).

## Migration Considerations

- Each package should have its own `pubspec.yaml` with appropriate dependencies
- Update imports in foundation_project from `foundation/...` to `package:fly_*/fly_*.dart`
- Maintain backward compatibility where possible
- Each package should be independently versioned
- Consider creating a `fly_foundation` meta-package that depends on all others for convenience

### To-dos

- [x] Analyze inter-module dependencies and external dependencies for each module
- [x] Create fly_logger, fly_localization, and fly_di packages (no foundation dependencies)
- [x] Create fly_connectivity, fly_errors, fly_events, and fly_navigation packages
- [x] Create fly_operations and fly_mvvm packages (depend on multiple foundation packages)
- [x] Update foundation_project to use new packages instead of local foundation directory
- [x] Create optional fly_foundation meta-package that re-exports all packages