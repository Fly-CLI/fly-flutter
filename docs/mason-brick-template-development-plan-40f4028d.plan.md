# Unified Mason Brick Template Development Plan for Fly CLI Ecosystem

## Executive Summary

This plan outlines the development of a **unified Mason brick template** (`fly_unified`) that generates both complete Flutter projects and individual components (screens, services, providers) using a single, consistent template system. The unified approach eliminates template duplication, ensures consistency across all generated code, simplifies maintenance, and provides a single source of truth for Fly CLI architecture patterns, ecosystem integration standards, and AI-powered development workflows.

**Key Objectives:**

- Single unified template (`fly_unified`) for both project and component generation
- Mode-based generation controlled by `generation_mode` variable (project, screen, service, provider)
- Generate Flutter projects that integrate seamlessly with Fly CLI commands
- Generate individual components with consistent patterns matching project structure
- Support Fly ecosystem packages (fly_core, fly_mvvm, fly_state, fly_networking, etc.)
- Enable AI-powered development through MCP integration
- Follow Fly CLI code generation standards and conventions
- Provide manifest-based project generation capabilities

**Timeline:** 8 weeks across 4 phases

**Target Deliverable:** Production-ready unified Mason brick template (`fly_unified`) with comprehensive documentation

**Implementation Reference:** This plan has been updated to match the architecture and patterns found in `/Users/apple/Desktop/dev/flutter/me/projects/Fly/examples/foundation_project`, which serves as the reference implementation for the core architecture and components.

**Key Architecture Decisions (from Foundation Project):**
- Uses `GlobalContainer` (ProviderContainer singleton) instead of ProviderScope
- Uses `BaseScreen` and `BaseViewModel` extending FlyScreen/FlyViewModel from `fly_mvvm`
- Feature-based architecture with data/domain/presentation layers
- Navigation via `FeatureScreen` enum and `RouteHandlerRegistry` (MaterialApp, not go_router directly)
- Repository pattern with `BaseRepository` and Template Method Pattern
- Services return `AppResult<T>` from `fly_flow_guard`
- Storage pattern with interfaces and managers
- Database using Drift (SQLite)
- Code generation: riverpod_generator, drift_dev, auto_mappr, json_serializable
- Localization via Flutter gen-l10n with `.arb` files
- Event system via `fly_events` package

---

## 1. Documentation Analysis

### 1.1 Architecture Patterns Analysis

**Sources:** 
- `/Users/apple/Desktop/dev/flutter/me/projects/Fly/packages/fly_cli/README.md`
- `/Users/apple/Desktop/dev/flutter/me/projects/Fly/examples/foundation_project` (Implementation Reference)

**Key Findings from Foundation Project:**

#### Component Relationships

- **Architecture Foundation**: `fly_core` (BaseScreen, BaseViewModel) → `fly_mvvm` (MVVM patterns) → `fly_state` (state management)
- **Networking Layer**: `fly_networking` integrates with `fly_state` and `fly_errors`
- **Navigation**: `fly_navigation` provides NavigationManager, uses MaterialApp with onGenerateRoute (not go_router directly)
- **Forms**: Form generation integrates with validation, state, and error handling
- **Cross-cutting**: `fly_logger`, `fly_localization`, `fly_connectivity` integrate across all layers
- **Event System**: `fly_events` provides AppEventEmitter for event-driven architecture
- **Flow Guard**: `fly_flow_guard` provides AppResult pattern and async operation handling

#### Foundation Project Architecture Patterns

1. **Dependency Injection**: Uses `GlobalContainer` (ProviderContainer singleton) with `UncontrolledProviderScope`
   - Initialized in `main()` before `runApp()`
   - Provides centralized access to all providers
   - Supports testing via `overrideForTesting()`

2. **Base Classes**:
   - `BaseScreen<V, S>` extends `FlyScreen<V, S>` from `fly_mvvm`
   - `BaseViewModel<S>` extends `FlyViewModel<S>` from `fly_mvvm`
   - Both provide common functionality and configuration

3. **Feature Organization**: Feature-based architecture with layered structure
   ```
   features/{feature}/
   ├── data/
   │   └── models/          # Entity models (database layer)
   ├── domain/
   │   └── models/          # Domain models (business logic)
   ├── mappers/             # Data mapping (auto_mappr)
   └── presentation/
       ├── models/          # UI models
       ├── screens/         # Screen widgets
       ├── view_models/     # ViewModels
       └── widgets/         # Feature-specific widgets
   ```

4. **Core Organization**:
   ```
   core/
   ├── analytics/           # Analytics providers and services
   ├── database/           # Drift database (app_database.dart, DAOs, tables)
   ├── di/                 # Dependency injection (GlobalContainer)
   ├── event_system/       # Event definitions and handlers
   ├── foundation/         # Base classes (BaseScreen, BaseViewModel)
   ├── models/             # Core domain models
   ├── navigation/         # Navigation service providers
   ├── offline/            # Offline queue management
   ├── pagination/         # Pagination utilities
   ├── providers/          # Core providers (service, repository, storage)
   ├── repositories/       # Repository pattern with BaseRepository
   ├── services/           # Business logic services
   ├── storage/            # Storage services and managers
   └── view_models/        # Shared view models
   ```

5. **Navigation Pattern**:
   - Uses `FeatureScreen` enum for type-safe navigation
   - `RouteHandlerRegistry` maps features to route handlers
   - `AppRouteConfig` handles route generation and parameter extraction
   - `AppNavigator` singleton implements `NavigationService<FeatureScreen>`
   - Uses `NavigationManager` from `fly_navigation` package
   - MaterialApp with `onGenerateRoute` (not go_router directly)

6. **Repository Pattern**:
   - `BaseRepository<T>` with Template Method Pattern
   - Hooks: `beforeCreate`, `beforeUpdate`, `beforeDelete`
   - Returns `AppResult<T>` from `fly_flow_guard`
   - Sync metadata support (sync_status, last_synced_at, version)

7. **Service Pattern**:
   - Services return `AppResult<T>` for consistent error handling
   - Services use `FlyLogger` for logging
   - Integration with repositories and storage managers

8. **Storage Pattern**:
   - `IStorageService` and `ISecureStorageService` interfaces
   - Implementations: `SharedPreferencesStorageService`, `SecureStorageService`
   - Storage managers: `AppDataManager`, `AppConfigDataManager`, `SyncDataManager`
   - Providers for dependency injection

9. **Database Pattern**:
   - Uses Drift (formerly Moor) for SQLite database
   - `AppDatabase` extends `_$AppDatabase` (generated)
   - DAOs (Data Access Objects) for each entity
   - Tables defined with Drift annotations
   - Code generation with `drift_dev`

10. **Code Generation**:
    - `build_runner` for all code generation
    - `riverpod_generator` for Riverpod providers
    - `drift_dev` for database code generation
    - `auto_mappr` for data mapping
    - `json_serializable` for JSON serialization

11. **Localization**:
    - Uses Flutter gen-l10n with `.arb` files
    - `l10n.yaml` configuration
    - `AppLocalizations` generated class

12. **Event System**:
    - Uses `fly_events` package
    - `AppEventEmitter` from GlobalContainer
    - Event definitions in `core/event_system/`
    - Navigation events: `NavigationStartedEvent`, `NavigationCompletedEvent`

#### Integration Points

1. **Screen Generation**: Automatically creates ViewModel → State → Networking → Navigation → Error Handling → Logging
2. **Service Generation**: API Service → Riverpod Providers → State Management → Error Handling → Retry Logic
3. **Form Generation**: Form Widget → Validation → State → Error Handling → Networking
4. **Repository Generation**: BaseRepository → DAO → Database → Sync Metadata
5. **Provider Generation**: Riverpod providers with proper dependency injection

### 1.2 CLI Command Structure

**Source:** `/Users/apple/Desktop/dev/flutter/me/projects/Fly/packages/fly_cli/lib/src/features/README.md`

**Command Architecture:**

- **Base Class**: `FlyCommand` with lifecycle hooks, validation pipeline, middleware system
- **Execution Flow**: Validation → Middleware → Pre-hook → Execute → Post-hook → Error Handling
- **Dependency Injection**: ServiceContainer with singleton/factory registration
- **Validation Pipeline**: Priority-based validators (Required Args → Project Name → Flutter Project → Permissions → Template → Environment → Network)

**Key Commands:**

- `fly create` - Project generation from templates/manifests
- `fly generate screen` - Screen generation with ViewModel, tests, navigation
- `fly generate service` - Service generation with API integration
- `fly mcp serve` - MCP server for AI integration
- `fly context export` - Export project context for AI understanding

**Current Template Discovery:**

- Brick type determined by directory structure (`templates/projects/` → project, `templates/components/screen/` → screen)
- Needs update to support unified template with mode-based routing

### 1.3 Unified Template System Requirements

**Current State:** Multiple templates in separate directories

**Target State:** Single unified template with mode-based generation

**Template Structure:**

```
templates/
└── fly_unified/
    ├── __brick__/
    │   ├── {{#is_project}}[project files]{{/is_project}}
    │   ├── {{#is_screen}}[screen files]{{/is_screen}}
    │   ├── {{#is_service}}[service files]{{/is_service}}
    │   └── {{#is_provider}}[provider files]{{/is_provider}}
    ├── brick.yaml          # Unified brick definition
    └── template.yaml       # Fly CLI template metadata
```

**Key Design Decision:**

- Single `generation_mode` variable controls what gets generated
- Conditional file inclusion using Mustache conditionals
- Mode-specific variable validation
- Template manager maps `generation_mode` to `BrickType` for compatibility

### 1.4 Code Generation Standards

**Patterns Identified:**

1. **Riverpod Code Generation:**

    - Uses `@riverpod` annotations (v3 syntax)
    - Requires `build_runner` and `riverpod_generator`
    - Generated files: `*.g.dart` (provider files)

2. **Project Structure** (Based on Foundation Project):
   ```
   lib/
   ├── main.dart
   ├── core/
   │   └── foundation/          # Base classes (BaseScreen, BaseViewModel)
   │   │   └── screen/
   │   │       ├── base_screen.dart
   │   │       └── base_view_model.dart
   ├── features/
   │   └── {feature}/
   │       ├── data/
   │       │   └── models/      # Entity models (database layer)
   │       ├── domain/
   │       │   └── models/      # Domain models (business logic)
   │       ├── mappers/         # Data mapping (auto_mappr)
   │       └── presentation/
   │           ├── models/      # UI models
   │           ├── screens/     # Screen widgets
   │           ├── view_models/ # ViewModels
   │           └── widgets/     # Feature-specific widgets
   ├── shared/
   │   ├── localization/        # Localization utilities
   │   ├── navigation/         # Navigation configuration (AppRouter, AppNavigator)
   │   ├── themes/             # Theme configuration
   │   ├── ui/                 # UI components
   │   └── widgets/            # Reusable widgets
   └── l10n/                   # Localization files (.arb)
   ```

3. **Mustache Template Syntax:**

    - Variables: `{{variable_name}}`
    - Conditionals: `{{#condition}}...{{/condition}}`
    - Negation: `{{^condition}}...{{/condition}}`
    - Filters: `{{variable.pascalCase()}}`, `{{variable.snakeCase()}}`

### 1.5 MCP Integration Patterns

**Source:** `/Users/apple/Desktop/dev/flutter/me/projects/Fly/packages/fly_cli/lib/src/integrations/README.md`

**MCP Integration Requirements:**

- MCP server exposes Fly CLI commands as tools
- Project context export for AI understanding
- Schema export for AI assistants
- Resource providers for project data

**Integration Points:**

- `.ai/` directory for AI context files
- `.cursor/` directory for Cursor IDE integration
- MCP server startup and configuration
- Context generation scripts

### 1.6 Manifest-Based Generation

**Source:** `/Users/apple/Desktop/dev/flutter/me/projects/Fly/docs/ai/fly_project_manifest_spec.yaml`

**Manifest Format:**

- Project metadata (name, template, organization, platforms)
- Screen definitions (name, type, features)
- Service definitions (name, api_base, features)
- Package dependencies
- Configuration (SDK versions, code generation settings)
- Environment-specific settings
- AI integration settings

**Unified Template Impact:**

- Manifest parser must set `generation_mode=project` for project creation
- Individual component generation uses appropriate mode

---

## 2. Unified Mason Brick Template Specification

### 2.1 Template Structure

**Directory Layout:**

```
fly_unified/
├── __brick__/
│   ├── {{#is_project}}
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── core/
│   │   │   │   ├── analytics/
│   │   │   │   ├── database/
│   │   │   │   │   ├── app_database.dart
│   │   │   │   │   ├── daos/
│   │   │   │   │   ├── tables/
│   │   │   │   │   └── models/
│   │   │   │   ├── di/
│   │   │   │   │   └── global_container.dart
│   │   │   │   ├── event_system/
│   │   │   │   ├── foundation/
│   │   │   │   │   └── screen/
│   │   │   │   │       ├── base_screen.dart
│   │   │   │   │       └── base_view_model.dart
│   │   │   │   ├── models/
│   │   │   │   ├── navigation/
│   │   │   │   ├── offline/
│   │   │   │   ├── pagination/
│   │   │   │   ├── providers/
│   │   │   │   │   ├── providers.dart
│   │   │   │   │   ├── service_providers.dart
│   │   │   │   │   ├── repository_providers.dart
│   │   │   │   │   └── logger_provider.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   ├── base/
│   │   │   │   │   │   └── base_repository.dart
│   │   │   │   │   └── interfaces/
│   │   │   │   ├── services/
│   │   │   │   ├── storage/
│   │   │   │   │   ├── implementations/
│   │   │   │   │   ├── interfaces/
│   │   │   │   │   ├── managers/
│   │   │   │   │   └── storage_providers.dart
│   │   │   │   └── view_models/
│   │   │   ├── features/
│   │   │   │   {{#features}}
│   │   │   │   └── {{feature}}/
│   │   │   │       ├── data/
│   │   │   │       │   └── models/
│   │   │   │       ├── domain/
│   │   │   │       │   └── models/
│   │   │   │       ├── mappers/
│   │   │   │       └── presentation/
│   │   │   │           ├── models/
│   │   │   │           ├── screens/
│   │   │   │           ├── view_models/
│   │   │   │           └── widgets/
│   │   │   │       {{/features}}
│   │   │   ├── shared/
│   │   │   │   ├── localization/
│   │   │   │   ├── navigation/
│   │   │   │   │   ├── app_router.dart
│   │   │   │   │   ├── app_navigator.dart
│   │   │   │   │   └── feature_screen_type.dart
│   │   │   │   ├── themes/
│   │   │   │   ├── ui/
│   │   │   │   └── widgets/
│   │   │   └── l10n/
│   │   │       └── app_en.arb
│   │   ├── test/
│   │   │   └── widget_test.dart
│   │   ├── pubspec.yaml
│   │   ├── analysis_options.yaml
│   │   ├── l10n.yaml
│   │   ├── README.md
│   │   ├── .gitignore
│   │   └── .ai/
│   │       └── project_context.md.template
│   │   {{/is_project}}
│   │
│   ├── {{#is_screen}}
│   │   └── lib/
│   │       └── features/
│   │           └── {{feature}}/
│   │               └── presentation/
│   │                   ├── screens/
│   │                   │   └── {{component_name}}_screen.dart
│   │                   {{#with_viewmodel}}
│   │                   ├── view_models/
│   │                   │   └── {{component_name}}_view_model.dart
│   │                   {{/with_viewmodel}}
│   │                   {{#with_tests}}
│   │                   └── test/
│   │                       └── {{component_name}}_screen_test.dart
│   │                   {{/with_tests}}
│   │   {{/is_screen}}
│   │
│   ├── {{#is_service}}
│   │   └── lib/
│   │       └── core/
│   │           └── services/
│   │               └── {{component_name}}_service.dart
│   │       {{#with_provider}}
│   │       └── core/
│   │           └── providers/
│   │               └── service_providers.dart (add provider)
│   │       {{/with_provider}}
│   │       {{#with_tests}}
│   │       └── test/
│   │           └── core/
│   │               └── services/
│   │                   └── {{component_name}}_service_test.dart
│   │       {{/with_tests}}
│   │   {{/is_service}}
│   │
│   └── {{#is_provider}}
│       └── lib/
│           └── core/
│               └── providers/
│                   └── {{component_name}}_provider.dart
│       {{/is_provider}}
│
├── brick.yaml
└── template.yaml
```

### 2.2 Variable Definitions

#### Core Variable: Generation Mode

**generation_mode** (enum) - **REQUIRED**

- Description: Controls what type of code to generate
- Values: `project`, `screen`, `service`, `provider`
- Default: `project`
- Prompt: "What would you like to generate?"
- Validation: Must be one of the allowed values

#### Project Mode Variables (when generation_mode=project)

**project_name** (string) - **REQUIRED when project**

- Description: Name of the Flutter project
- Validation: Must be valid Dart package name (lowercase, underscores)
- Example: `my_app`, `stock_ai`
- Prompt: "What is your project name?"

**organization** (string) - **REQUIRED when project**

- Description: Organization identifier (reverse domain notation)
- Default: `com.example`
- Validation: Must match reverse domain pattern
- Example: `com.company`, `io.github.username`
- Prompt: "What is your organization?"

**platforms** (list) - **REQUIRED when project**

- Description: Target platforms
- Default: `[ios, android]`
- Choices: `ios`, `android`, `web`, `macos`, `windows`, `linux`
- Validation: At least one platform required
- Prompt: "Which platforms do you want to support?"

**description** (string) - **Optional when project**

- Description: Project description
- Default: `A new Flutter project`
- Prompt: "What is your project description?"

**template** (enum) - **Optional when project**

- Description: Project template style
- Choices: `minimal`, `riverpod`
- Default: `riverpod`
- Prompt: "Which template style?"

**features** (list) - **Optional when project**

- Description: Initial features to generate
- Default: `[home]`
- Example: `[home, auth, profile, settings]`
- Prompt: "Which initial features would you like?"

**min_flutter_sdk** (string) - **Optional when project**

- Description: Minimum Flutter SDK version
- Default: `3.10.0`

**min_dart_sdk** (string) - **Optional when project**

- Description: Minimum Dart SDK version
- Default: `3.0.0`

**with_mcp** (boolean) - **Optional when project**

- Description: Include MCP integration setup
- Default: `true`

**with_tests** (boolean) - **Optional when project**

- Description: Generate test files
- Default: `true`

**with_docs** (boolean) - **Optional when project**

- Description: Generate documentation
- Default: `false`

**fly_packages** (list) - **Optional when project**

- Description: Fly ecosystem packages to include
- Default: `[fly_core, fly_state, fly_networking, fly_navigation, fly_errors, fly_logger]`
- Choices: All Fly ecosystem packages

**code_generation** (boolean) - **Optional when project**

- Description: Enable build_runner code generation
- Default: `true`

**ai_integration** (boolean) - **Optional when project**

- Description: Setup AI integration (MCP, context export)
- Default: `true`

#### Component Mode Variables (when generation_mode != project)

**component_name** (string) - **REQUIRED when component**

- Description: Name of the component (snake_case)
- Validation: Must be valid Dart identifier
- Example: `user_profile`, `auth_service`, `home_provider`
- Prompt: "What is the component name?"

**feature** (string) - **REQUIRED when component**

- Description: Feature module name
- Default: `home`
- Validation: Must be valid Dart identifier
- Prompt: "Which feature does this component belong to?"

#### Screen-Specific Variables (when generation_mode=screen)

**screen_type** (enum) - **Optional when screen**

- Description: Type of screen to generate
- Choices: `list`, `detail`, `form`, `auth`, `settings`
- Default: `list`
- Prompt: "What type of screen is this?"

**with_viewmodel** (boolean) - **Optional when screen**

- Description: Include Riverpod viewmodel/provider
- Default: `true`
- Prompt: "Include ViewModel/Provider?"

**with_validation** (boolean) - **Optional when screen**

- Description: Include form validation (for form screens)
- Default: `false`
- Prompt: "Include form validation?"

**with_navigation** (boolean) - **Optional when screen**

- Description: Include navigation logic
- Default: `true`
- Prompt: "Include navigation?"

#### Service-Specific Variables (when generation_mode=service)

**api_base_url** (string) - **Optional when service**

- Description: Base URL for API service
- Default: `https://api.example.com`
- Prompt: "What is the API base URL?"

**with_retry_logic** (boolean) - **Optional when service**

- Description: Include retry logic with connectivity
- Default: `true`

**with_caching** (boolean) - **Optional when service**

- Description: Include caching support
- Default: `false`

#### Provider-Specific Variables (when generation_mode=provider)

**provider_type** (enum) - **Optional when provider**

- Description: Type of provider
- Choices: `notifier`, `future`, `stream`, `state`
- Default: `notifier`
- Prompt: "What type of provider?"

**with_state_class** (boolean) - **Optional when provider**

- Description: Generate state class with freezed
- Default: `false`

### 2.3 Conditional Logic Helpers

**Mustache Conditionals:**

- `{{#is_project}}...{{/is_project}}` - Project mode files
- `{{#is_screen}}...{{/is_screen}}` - Screen mode files
- `{{#is_service}}...{{/is_service}}` - Service mode files
- `{{#is_provider}}...{{/is_provider}}` - Provider mode files
- `{{#with_viewmodel}}...{{/with_viewmodel}}` - Include ViewModel
- `{{#with_tests}}...{{/with_tests}}` - Include tests
- `{{#features}}...{{/features}}` - Loop through features

**Variable Transformations:**

- `{{component_name.pascalCase()}}` - PascalCase for class names
- `{{component_name.snakeCase()}}` - snake_case for file names
- `{{component_name.camelCase()}}` - camelCase for variable names
- `{{project_name.snakeCase()}}` - Project name in snake_case

### 2.4 Template Files

#### Project Mode Files

**pubspec.yaml**

- Dynamic package dependencies based on selected Fly packages
- Code generation dependencies (build_runner, riverpod_generator)
- Platform-specific configurations
- Conditional dependencies based on `fly_packages` variable

**main.dart**

- `GlobalContainer.initialize()` before `runApp()`
- `UncontrolledProviderScope` with `GlobalContainer.instance`
- Storage services initialization (regularStorage, secureStorage)
- App data manager initialization
- MaterialApp with NavigationManager from `fly_navigation`
- Theme configuration
- Localization setup
- Conditional MCP integration

**app_router.dart** (shared/navigation/app_router.dart)

- `FeatureScreen` enum for type-safe navigation
- `RouteHandlerRegistry` mapping features to route handlers
- `AppRouteConfig` with `onGenerateRoute` (MaterialApp, not go_router)
- Route parameter extraction and normalization
- Unknown route handling
- Navigation argument preparation

**app_theme.dart** (shared/themes/)

- Material 3 theme configuration
- Light/dark theme support
- Custom color schemes

**app_config.dart** (core/storage/managers/app_config_data_manager.dart)

- Environment configuration via storage managers
- API endpoints configuration
- Feature flags via storage

**global_container.dart** (core/di/global_container.dart)

- ProviderContainer singleton
- `initialize()` method for app startup
- `overrideForTesting()` for test support
- `reset()` for test cleanup

**base_screen.dart** (core/foundation/screen/base_screen.dart)

- Extends `FlyScreen<V, S>` from `fly_mvvm`
- Provides common screen functionality
- Integration with ViewModel providers

**base_view_model.dart** (core/foundation/screen/base_view_model.dart)

- Extends `FlyViewModel<S>` from `fly_mvvm`
- Provides common ViewModel functionality
- Automatic logger initialization
- Connectivity checker integration

**app_navigator.dart** (shared/navigation/app_navigator.dart)

- Singleton implementation of `NavigationService<FeatureScreen>`
- Uses `NavigationManager` from `fly_navigation`
- Event emission for navigation tracking
- Type-safe navigation methods
- Route argument preparation

**feature_screen_type.dart** (shared/navigation/feature_screen_type.dart)

- Enum defining all application features
- Route paths and protection status
- Helper methods for feature filtering

#### Screen Mode Files

**{{component_name}}_screen.dart**

- Extends `BaseScreen<V, S>` (which extends `FlyScreen<V, S>`)
- ViewModel integration via `getViewModelProvider()` method
- State management with Riverpod providers
- Error handling integration via `runAsyncOperation()` in ViewModel
- Navigation integration using `AppNavigator`
- Conditional rendering based on screen type
- Form validation (if enabled)
- Pull-to-refresh support via `onRefresh()` method
- Localization support via `AppLocalizations`

**{{component_name}}_view_model.dart** (if with_viewmodel=true)

- Extends `BaseViewModel<S>` (which extends `FlyViewModel<S>`)
- State class implementing `FlyViewModelState<S>`
- Uses `runAsyncOperation()` for async operations
- Integration with services via providers
- Error handling via `runAsyncOperation()` error callbacks
- Loading state management
- Screen type-specific logic
- Provider definition: `final {{component_name}}ViewModelProvider = NotifierProvider<...>`

**{{component_name}}_screen_test.dart** (if with_tests=true)

- Widget tests
- Provider mocking
- Navigation testing
- Error state testing

#### Service Mode Files

**{{component_name}}_service.dart**

- Service class with dependency injection via providers
- Returns `AppResult<T>` from `fly_flow_guard` for consistent error handling
- Uses `FlyLogger` for logging
- Integration with repositories (if needed)
- Integration with storage managers (if needed)
- Retry logic with connectivity (if enabled)
- Caching support via `CacheService` (if enabled)
- API endpoint definitions
- Provider definition: `final {{component_name}}ServiceProvider = Provider<...>`

**{{component_name}}_service_test.dart** (if with_tests=true)

- Service tests
- API mocking
- Error handling tests
- Retry logic tests

#### Provider Mode Files

**{{component_name}}_provider.dart**

- Riverpod provider with @riverpod annotation
- Provider type-specific implementation
- State class (if with_state_class=true)
- Integration with fly_state

### 2.5 Dependencies

#### Required Packages (All Modes)

**Core Flutter:**

- `flutter` (SDK)
- `flutter_localizations` (SDK)

**State Management:**

- `riverpod: ^3.0.3`
- `riverpod_annotation: ^3.0.0`

**Navigation:**

- `go_router: ^12.1.0` (optional, foundation project uses MaterialApp with onGenerateRoute)
- Navigation handled via `fly_navigation` package with `NavigationManager`

**Code Generation:**

- `build_runner: ^2.4.8`
- `riverpod_generator: ^3.0.3`
- `drift_dev: ^2.29.0` (for database code generation)
- `auto_mappr: ^2.0.0` (for data mapping)
- `json_serializable: ^6.8.0` (for JSON serialization)

#### Fly Ecosystem Packages (Project Mode)

**Architecture:**

- `fly_core` - Base classes and architecture patterns
- `fly_mvvm` - MVVM architecture patterns
- `fly_state` - State management abstractions

**Networking:**

- `fly_networking` - HTTP client with Dio
- `fly_connectivity` - Network monitoring

**Navigation:**

- `fly_navigation` - Routing utilities
- `fly_flow_guard` - Flow control and guards

**Error Handling:**

- `fly_errors` - Centralized error handling
- `fly_feedback` - User feedback collection

**Cross-cutting:**

- `fly_logger` - Structured logging
- `fly_localization` - i18n support
- `fly_events` - Event-driven architecture

**Flow Control:**

- `fly_flow_guard` - AppResult pattern and async operation handling

**AI Integration:**

- `fly_mcp` - MCP integration

**Database:**

- `drift: ^2.29.0` - SQLite database (Drift)
- `sqlite3_flutter_libs: ^0.5.0` - SQLite native libraries
- `path_provider: ^2.1.2` - Path utilities

**Storage:**

- `shared_preferences: ^2.2.2` - Regular storage
- `flutter_secure_storage: ^9.0.0` - Secure storage

**Mapping:**

- `auto_mappr_annotation: ^2.0.0` - Data mapping annotations

**Utilities:**

- `uuid: ^4.2.1` - UUID generation
- `intl: ^0.20.2` - Internationalization
- `logging: ^1.3.0` - Logging utilities
- `connectivity_plus: ^7.0.0` - Connectivity checking
- `battery_plus: ^7.0.0` - Battery level checking (for DeviceConditionService)
- `http: ^1.1.0` - HTTP client

#### Dev Dependencies

- `flutter_test` (SDK)
- `flutter_lints: ^5.0.0`
- `mocktail: ^1.0.3` (for testing)
- Custom linting package (optional, like `foundation_project_lints`)

### 2.6 Code Generation Integration

#### Build Runner Configuration

**build.yaml:**

```yaml
targets:
  $default:
    builders:
      riverpod_generator:
        enabled: true
        options:
          # Riverpod generator options
      drift_dev:
        enabled: true
        options:
          # Drift generator options
      auto_mappr:
        enabled: true
        options:
          # Auto mappr generator options
      json_serializable:
        enabled: true
        options:
          # JSON serializable options
```

#### Annotation Usage

**ViewModel Pattern:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_mvvm/fly_mvvm.dart';
import 'package:foundation_project/core/foundation/screen/base_view_model.dart';

class {{ComponentName}}ViewModelState implements FlyViewModelState<{{ComponentName}}ViewModelState> {
  @override
  final bool isLoading;
  @override
  final String? error;
  @override
  bool get hasError => error != null;
  
  // Add other state properties here
  
  {{ComponentName}}ViewModelState({
    required this.isLoading,
    this.error,
  });
  
  @override
  {{ComponentName}}ViewModelState copyWith({
    bool? isLoading,
    String? error,
    bool updateError = false,
  }) {
    return {{ComponentName}}ViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: updateError ? error : this.error,
    );
  }
  
  // Implement other FlyViewModelState methods
}

class {{ComponentName}}ViewModel extends BaseViewModel<{{ComponentName}}ViewModelState> {
  @override
  {{ComponentName}}ViewModelState build() {
    return {{ComponentName}}ViewModelState.initial();
  }
  
  // Use runAsyncOperation for async operations
  Future<void> loadData() async {
    await runAsyncOperation(
      () async {
        // Your async operation
      },
      errorMessage: 'Failed to load data',
    );
  }
}

final {{component_name}}ViewModelProvider = NotifierProvider<{{ComponentName}}ViewModel, {{ComponentName}}ViewModelState>(
  () => {{ComponentName}}ViewModel(),
);
```

**Generation Script:**

- `dart run build_runner build --delete-conflicting-outputs`
- Integrated into project setup scripts

### 2.7 MCP Integration Templates

#### MCP Server Configuration

**.mcp/config.yaml:**

- MCP server settings
- Tool definitions
- Resource providers

#### Context Export Templates

**.ai/project_context.md:**

- Project structure documentation
- Architecture patterns
- Integration points
- AI assistant instructions

**.cursor/project_context.md:**

- Cursor-specific context
- Code examples
- Development patterns

---

## 3. Implementation Plan

### Phase 1: Foundation (Weeks 1-2)

#### Week 1: Unified Template Structure and Core Variables

**Tasks:**

1. Remove existing templates from `packages/fly_cli/templates/`
2. Create `fly_unified` template directory structure
3. Define `brick.yaml` with `generation_mode` and all variable definitions
4. Create `template.yaml` with Fly CLI metadata
5. Implement conditional logic helpers (is_project, is_screen, etc.)
6. Create core template files structure with conditionals
7. Implement variable validation logic based on generation_mode

**Deliverables:**

- Unified template structure (`fly_unified/`)
- Complete `brick.yaml` with all variables
- `template.yaml` with metadata
- Conditional file structure
- Variable validation system
- Unit tests for variable validation

#### Week 2: Project Mode Implementation

**Tasks:**

1. Implement project mode template files:

    - `pubspec.yaml` with dynamic dependencies
    - `main.dart` with ProviderScope and router
    - `app_router.dart` with go_router
    - `app_theme.dart` with Material 3
    - `app_config.dart` with environment config
    - `analysis_options.yaml`
    - `.gitignore`
    - `README.md`

2. Implement feature-based directory generation
3. Add MCP integration templates
4. Add AI context export templates
5. Implement post-generation hooks (build_runner, format)

**Deliverables:**

- Complete project mode templates
- Feature generation logic
- MCP integration setup
- Post-generation automation
- Integration tests for project generation

### Phase 2: Component Modes (Weeks 3-4)

#### Week 3: Screen and Service Component Modes

**Tasks:**

1. Implement screen mode templates:

    - Screen widget with BaseScreen
    - Provider template (conditional)
    - Test template (conditional)
    - Screen type-specific logic (list, detail, form, auth, settings)

2. Implement service mode templates:

    - Service class with fly_networking
    - Test template (conditional)
    - Retry logic integration
    - Caching support (conditional)

3. Add conditional ViewModel integration
4. Add conditional navigation integration
5. Add conditional form validation

**Deliverables:**

- Screen mode templates
- Service mode templates
- Conditional logic for all options
- Integration tests for component generation
- Generated code compiles successfully

#### Week 4: Provider Mode and Template Manager Updates

**Tasks:**

1. Implement provider mode templates:

    - Provider with @riverpod annotation
    - Provider type variations (notifier, future, stream, state)
    - State class generation (conditional)

2. Update template manager to support unified template:

    - Read `generation_mode` from variables
    - Map `generation_mode` to `BrickType` for compatibility
    - Update `_determineBrickType()` to handle unified template
    - Add mode-based variable validation

3. Update CLI commands to use unified template:

    - `fly create` → `generation_mode=project`
    - `fly generate screen` → `generation_mode=screen`
    - `fly generate service` → `generation_mode=service`
    - Add `fly generate provider` → `generation_mode=provider`

4. Update manifest parser to set appropriate generation_mode

**Deliverables:**

- Provider mode templates
- Updated template manager
- Updated CLI commands
- Manifest parser updates
- Comprehensive integration tests

### Phase 3: Integration and Advanced Features (Weeks 5-6)

#### Week 5: Fly Ecosystem Integration

**Tasks:**

1. Integrate fly_core patterns (BaseScreen, BaseViewModel)
2. Integrate fly_state patterns
3. Integrate fly_networking patterns
4. Integrate fly_navigation (go_router setup)
5. Integrate fly_errors error handling patterns
6. Integrate fly_logger logging patterns
7. Create integration tests with generated projects
8. Verify all Fly packages work correctly

**Deliverables:**

- Fly ecosystem package integration
- Integration tests passing
- Generated code compiles successfully
- Documentation for integration patterns

#### Week 6: Manifest-Based Generation and MCP Integration

**Tasks:**

1. Implement manifest parser (YAML)
2. Create manifest-to-variables converter
3. Implement multi-feature generation from manifest
4. Add environment-specific configuration
5. Implement custom template overrides
6. Enhance MCP integration templates
7. Add context export functionality
8. Add schema export templates

**Deliverables:**

- Manifest parsing system
- Multi-feature generation
- Environment configuration
- Enhanced MCP integration
- Context export functionality
- Comprehensive tests

### Phase 4: Testing & Documentation (Weeks 7-8)

#### Week 7: Testing and Quality Assurance

**Tasks:**

1. Write unit tests for all template generation logic
2. Write integration tests with Fly CLI
3. Test all generation modes (project, screen, service, provider)
4. Test generated projects compile and run
5. Performance testing (generation speed < 5 seconds)
6. Compatibility testing (Flutter 3.0+, Dart 3.0+)
7. Test all variable combinations
8. Test error handling and edge cases
9. Test mode-based validation
10. Test conditional file generation

**Deliverables:**

- 80%+ test coverage
- Integration test suite
- Performance benchmarks
- Compatibility matrix
- Bug fixes and improvements

#### Week 8: Documentation and Examples

**Tasks:**

1. Write comprehensive README.md
2. Create API reference documentation
3. Write usage examples:

    - Example 1: Generate minimal project
    - Example 2: Generate riverpod project with features
    - Example 3: Generate screen component
    - Example 4: Generate service component
    - Example 5: Generate provider component

4. Create migration guide (from old templates)
5. Write best practices guide
6. Create troubleshooting guide
7. Add inline code documentation
8. Create video tutorials (optional)

**Deliverables:**

- Complete documentation package
- Example projects and components
- Migration guide
- Best practices guide
- Troubleshooting guide

---

## 4. Standards Compliance Matrix

### 4.1 Flutter/Dart Code Generation Standards

**Compliance Checklist:**

✅ **build_runner Integration**

- Uses `build_runner` for code generation
- Proper `build.yaml` configuration
- Generated files in `.g.dart` format
- Delete conflicting outputs handling

✅ **Riverpod Code Generation**

- Uses `@riverpod` annotations (v3 syntax)
- Proper provider patterns
- Generated provider files
- State management best practices

✅ **Code Style**

- Follows Dart style guide
- Uses `flutter_lints` package (v5.0.0)
- Custom linting rules via analyzer plugins (optional)
- Proper import organization
- Consistent naming conventions
- Excludes generated files from analysis (`*.g.dart`, `*.freezed.dart`)
- Linter rules: always_declare_return_types, avoid_print, prefer_const_constructors, etc.

### 4.2 Fly Ecosystem Integration

**Compliance Checklist:**

✅ **Architecture Patterns**

- Uses `BaseScreen` from `fly_core`
- Uses `BaseViewModel` from `fly_mvvm`
- Follows MVVM architecture
- Proper separation of concerns

✅ **State Management**

- Integrates with `fly_state`
- Uses Riverpod providers correctly
- State synchronization patterns
- Error state handling

✅ **Networking**

- Uses `fly_networking` for API calls
- Dio client integration
- Error handling integration
- Retry logic with connectivity

✅ **Navigation**

- Uses `NavigationManager` from `fly_navigation` package
- MaterialApp with `onGenerateRoute` (not go_router directly)
- `FeatureScreen` enum for type-safe navigation
- `RouteHandlerRegistry` for route-to-handler mapping
- `AppNavigator` singleton implementing `NavigationService<FeatureScreen>`
- Route parameter extraction and normalization
- Navigation event emission via `fly_events`
- Deep linking support

✅ **Error Handling**

- Uses `fly_errors` patterns
- Centralized error handling
- User-friendly error messages
- Error recovery patterns

✅ **Logging**

- Uses `fly_logger` for structured logging
- Logging across all layers
- Log levels and filtering
- Performance logging

### 4.3 Fly CLI Command Structure

**Compliance Checklist:**

✅ **Command Compatibility**

- Generated projects work with `fly generate screen`
- Generated projects work with `fly generate service`
- Compatible with `fly create` command
- Supports manifest-based generation
- New `fly generate provider` command

✅ **Naming Conventions**

- Follows Fly CLI naming patterns
- Feature-based organization
- Consistent file naming
- Proper directory structure

✅ **Template Metadata**

- Proper `template.yaml` format
- Correct variable definitions
- SDK version constraints
- Feature and package declarations

### 4.4 MCP Integration Patterns

**Compliance Checklist:**

✅ **MCP Server Setup**

- MCP server configuration
- Tool definitions
- Resource providers
- Proper error handling

✅ **Context Export**

- Project context generation
- Architecture documentation
- Integration points documentation
- AI assistant instructions

✅ **Schema Export**

- Command schema generation
- JSON Schema format
- Example generation
- Documentation integration

### 4.5 Unified Template Specific

**Compliance Checklist:**

✅ **Mode-Based Generation**

- Single template handles all modes
- Proper mode detection and routing
- Mode-specific variable validation
- Conditional file generation works correctly

✅ **Consistency**

- Same patterns across all modes
- Consistent code style
- Unified architecture patterns
- Single source of truth

---

## 5. Quality Assurance Plan

### 5.1 Test Coverage Requirements

**Target:** Minimum 80% code coverage

**Test Categories:**

1. **Unit Tests**

    - Template variable validation
    - Mode-based validation logic
    - Template file generation
    - Conditional logic testing
    - Variable transformation (camelCase, PascalCase, etc.)

2. **Integration Tests**

    - Full project generation (all modes)
    - Component generation (screen, service, provider)
    - Code compilation verification
    - Fly CLI command integration
    - Manifest-based generation

3. **End-to-End Tests**

    - Complete project lifecycle
    - Component addition to existing project
    - Manifest-based generation
    - MCP integration setup
    - AI context export

### 5.2 Validation Criteria

**Generated Code Must:**

- ✅ Compile without errors
- ✅ Pass Dart analyzer checks
- ✅ Follow Dart style guide
- ✅ Integrate with Fly ecosystem packages
- ✅ Work with Fly CLI commands
- ✅ Support code generation (build_runner)
- ✅ Include proper error handling
- ✅ Include logging integration

**Generated Projects Must:**

- ✅ Run on target platforms
- ✅ Pass widget tests
- ✅ Integrate with Fly CLI
- ✅ Support MCP integration
- ✅ Export context correctly

**Generated Components Must:**

- ✅ Follow same patterns as project mode
- ✅ Integrate correctly with existing projects
- ✅ Compile without errors
- ✅ Pass tests (if generated)

### 5.3 Integration Testing

**Test Scenarios:**

1. **Project Generation**

    - Generate minimal project
    - Generate riverpod project
    - Generate with all features
    - Generate with custom packages

2. **Component Generation**

    - Generate screen with ViewModel
    - Generate screen without ViewModel
    - Generate service with API integration
    - Generate provider with state class
    - Generate multiple components

3. **Fly CLI Integration**

    - Run `fly generate screen` on generated project
    - Run `fly generate service` on generated project
    - Run `fly generate provider` on generated project
    - Run `fly context export` on generated project
    - Run `fly mcp serve` on generated project

4. **Code Generation**

    - Run `build_runner` successfully
    - Verify generated `.g.dart` files
    - Verify Riverpod providers work
    - Verify no conflicts

5. **Mode Switching**

    - Generate project, then add components
    - Verify consistency between modes
    - Verify no conflicts

### 5.4 Performance Metrics

**Target Metrics:**

- **Template Generation Speed:** < 5 seconds for standard project
- **Component Generation Speed:** < 2 seconds per component
- **Large Project Generation:** < 15 seconds for project with 10+ features
- **Memory Usage:** < 500MB during generation
- **Disk Usage:** Minimal temporary files

**Measurement:**

- Benchmark generation times for each mode
- Profile memory usage
- Monitor disk I/O
- Track performance regressions

### 5.5 Compatibility Testing

**Flutter SDK Versions:**

- ✅ Flutter 3.10.0+ (minimum)
- ✅ Flutter 3.12.0+ (recommended)
- ✅ Flutter 3.16.0+ (latest stable)

**Dart SDK Versions:**

- ✅ Dart 3.0.0+ (minimum)
- ✅ Dart 3.2.0+ (recommended)
- ✅ Dart 3.4.0+ (latest stable)

**Platforms:**

- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

**Operating Systems:**

- ✅ macOS
- ✅ Linux
- ✅ Windows

**Generation Modes:**

- ✅ Project mode
- ✅ Screen mode
- ✅ Service mode
- ✅ Provider mode

---

## 6. Documentation Package

### 6.1 README.md Structure

**Sections:**

1. **Overview**

    - What is fly_unified
    - Unified template approach benefits
    - Key features
    - Quick start

2. **Installation**

    - Mason installation
    - Brick installation
    - Verification

3. **Usage**

    - Basic usage
    - Generation modes explained
    - Variable reference
    - Examples for each mode
    - Advanced usage

4. **Generation Modes**

    - Project mode
    - Screen mode
    - Service mode
    - Provider mode
    - Mode comparison

5. **Integration**

    - Fly CLI integration
    - Fly ecosystem packages
    - MCP integration
    - AI integration

6. **Customization**

    - Custom templates
    - Variable customization
    - Extension points
    - Conditional logic

7. **Troubleshooting**

    - Common issues
    - Error messages
    - Solutions
    - Mode-specific issues

8. **Contributing**

    - Development setup
    - Contribution guidelines
    - Code of conduct

### 6.2 API Reference

**Variable Reference:**

- Complete list of variables by mode
- Types and constraints
- Default values
- Validation rules
- Examples

**Template Structure:**

- Directory layout
- File organization
- Naming conventions
- Conditional logic

**Mode Reference:**

- Project mode details
- Screen mode details
- Service mode details
- Provider mode details

**Customization Guide:**

- Extending templates
- Adding custom variables
- Custom file generation
- Integration points

### 6.3 Examples

**Example 1: Minimal Project**

- Basic Flutter project
- Minimal dependencies
- Simple structure

**Example 2: Riverpod Project**

- Full Riverpod setup
- Multiple features
- Complete integration

**Example 3: Production Project**

- All Fly packages
- MCP integration
- AI context export
- Complete documentation

**Example 4: Screen Component**

- Screen with ViewModel
- Navigation integration
- Form validation

**Example 5: Service Component**

- API service
- Retry logic
- Caching support

**Example 6: Provider Component**

- Provider with state class
- Integration patterns

### 6.4 Migration Guide

**From Old Templates:**

- Step-by-step migration
- Template removal process
- Variable mapping
- Code changes required

**From Other CLI Tools:**

- Very Good CLI migration
- Other tool migrations
- Compatibility notes

### 6.5 Best Practices

**Project Structure:**

- Feature organization
- Naming conventions
- Code organization

**Development Workflow:**

- Using Fly CLI commands
- Code generation workflow
- Testing strategies
- Mode selection

**AI Integration:**

- MCP setup
- Context export
- AI-assisted development

---

## 7. Success Criteria

### 7.1 Completeness

✅ **All Generation Modes Supported**

- Project generation (minimal, riverpod)
- Screen generation (all types)
- Service generation
- Provider generation
- Manifest-based generation
- MCP integration

✅ **All Ecosystem Components Supported**

- fly_core integration
- fly_mvvm integration
- fly_state integration
- fly_networking integration
- fly_navigation integration
- fly_errors integration
- fly_logger integration
- fly_mcp integration

### 7.2 Standards Compliance

✅ **100% Adherence to Code Generation Standards**

- build_runner integration
- Riverpod code generation
- Dart style guide compliance
- Fly CLI command compatibility

### 7.3 Measurability

✅ **Clear Metrics Defined**

- Template generation speed (< 5 seconds)
- Component generation speed (< 2 seconds)
- Test coverage (80%+)
- Code quality (analyzer passing)
- Integration success rate (100%)

### 7.4 Usability

✅ **Developer Experience**

- Generate working project in < 2 minutes
- Generate component in < 30 seconds
- Clear documentation
- Helpful error messages
- Intuitive variable system
- Easy mode selection

### 7.5 Maintainability

✅ **Template Structure**

- Single unified template
- Modular template files
- Clear organization
- Easy to extend
- Well-documented
- Consistent patterns

### 7.6 Integration

✅ **Seamless Integration**

- Works with Fly CLI commands
- MCP integration functional
- AI context export working
- Generated code compiles and runs
- Components integrate with projects
- Consistent patterns across modes

---

## 8. Risk Assessment and Mitigation

### 8.1 Technical Risks

**Risk:** Unified template complexity leading to bugs

- **Mitigation:** Comprehensive testing, code review, incremental development, clear conditional logic

**Risk:** Mode-based routing breaking existing CLI commands

- **Mitigation:** Backward compatibility testing, gradual migration, fallback options

**Risk:** Mason brick API changes

- **Mitigation:** Pin Mason version, monitor updates, test compatibility

**Risk:** Fly ecosystem package API changes

- **Mitigation:** Version pinning, compatibility testing, update procedures

### 8.2 Integration Risks

**Risk:** Template manager changes breaking existing functionality

- **Mitigation:** Extensive testing, backward compatibility, versioned templates

**Risk:** Fly CLI command changes

- **Mitigation:** Version compatibility matrix, integration tests, update procedures

**Risk:** MCP integration breaking changes

- **Mitigation:** Version pinning, compatibility testing, fallback options

### 8.3 Quality Risks

**Risk:** Generated code quality issues

- **Mitigation:** Code analysis, linting, comprehensive testing, code review

**Risk:** Performance degradation

- **Mitigation:** Performance benchmarks, profiling, optimization

**Risk:** Inconsistent patterns between modes

- **Mitigation:** Shared template logic, code review, pattern validation

---

## 9. Timeline and Dependencies

### 9.1 Phase Dependencies

**Phase 1 → Phase 2:** Core template structure must be complete before component modes

**Phase 2 → Phase 3:** Component modes must be stable before integration

**Phase 3 → Phase 4:** All features must be complete before final testing

### 9.2 External Dependencies

- Mason CLI (latest stable)
- Fly CLI (compatible version)
- Fly ecosystem packages (compatible versions)
- Flutter SDK (3.10.0+)
- Dart SDK (3.0.0+)

### 9.3 Resource Requirements

- Development time: 8 weeks (1 developer)
- Testing time: 2 weeks (included in Phase 4)
- Documentation time: 1 week (included in Phase 4)
- Review time: 1 week (stakeholder review)

---

## 10. Appendices

### Appendix A: Template File Examples

**See implementation for complete examples**

### Appendix B: Variable Reference by Mode

**Complete variable definitions organized by generation_mode**

### Appendix C: Fly Ecosystem Package Versions

**Current versions to be pinned in templates**

### Appendix D: Testing Scenarios

**Complete test case documentation for all modes**

### Appendix E: Migration Checklist

**Step-by-step migration from old templates to unified template**

---

## Conclusion

This plan provides a comprehensive roadmap for developing a unified Mason brick template (`fly_unified`) that generates both Flutter projects and individual components using a single, consistent template system. The 8-week implementation plan ensures systematic development with clear deliverables, quality assurance, and comprehensive documentation.

The unified approach eliminates template duplication, ensures consistency, simplifies maintenance, and provides a single source of truth for Fly CLI patterns and ecosystem integration standards.

**Plan Updates:** This plan has been thoroughly analyzed and updated to match the architecture and implementation patterns found in the foundation project (`/Users/apple/Desktop/dev/flutter/me/projects/Fly/examples/foundation_project`). Key updates include:

- Updated project structure to match foundation project's feature-based architecture with data/domain/presentation layers
- Updated dependency injection pattern to use `GlobalContainer` (ProviderContainer singleton)
- Updated navigation pattern to use `FeatureScreen` enum and `RouteHandlerRegistry` with MaterialApp
- Added repository pattern with `BaseRepository` and Template Method Pattern
- Updated service pattern to return `AppResult<T>` from `fly_flow_guard`
- Added storage pattern with interfaces and managers
- Added database pattern using Drift (SQLite)
- Updated code generation to include drift_dev, auto_mappr, and json_serializable
- Updated localization pattern to use Flutter gen-l10n with `.arb` files
- Added event system integration via `fly_events` package
- Updated base classes to extend `BaseScreen` and `BaseViewModel` from foundation project
- Updated dependencies to match foundation project versions

**Next Steps:**

1. Review and approve plan
2. Remove existing templates
3. Set up unified template structure
4. Begin Phase 1 implementation
5. Establish testing infrastructure
6. Create documentation framework