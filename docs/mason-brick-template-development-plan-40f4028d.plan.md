# Unified Mason Brick Template Development Plan for Fly CLI Ecosystem

## Executive Summary

This plan outlines the development of a **unified Mason brick template** (`fly_foundation`) that
generates both complete Flutter projects and individual components (screens, services, providers)
using a single, consistent template system. The unified approach eliminates template duplication,
ensures consistency across all generated code, simplifies maintenance, and provides a single source
of truth for Fly CLI architecture patterns, ecosystem integration standards, and AI-powered
development workflows.

**Key Objectives:**

- Single unified template (`fly_foundation`) for both project and component generation
- Mode-based generation controlled by `generation_mode` variable (project, screen, service, provider)
- Generate Flutter projects that integrate seamlessly with Fly CLI commands
- Generate individual components with consistent patterns matching project structure
- Support Fly ecosystem packages (fly_core, fly_mvvm, fly_state, fly_networking, etc.)
- Enable AI-powered development through MCP integration
- Follow Fly CLI code generation standards and conventions
- Provide manifest-based project generation capabilities
- Achieve 95%+ industry standards compliance
- Implement comprehensive accessibility support (0% → 85%+)
- Provide extensive documentation (42% → 90%+)

**Timeline:** 8 weeks across 4 phases

**Target Deliverable:** Production-ready unified Mason brick template (`fly_foundation`) with
comprehensive documentation, industry-leading compliance, and accessibility support

**Current Compliance Score:** 82% ⚠️  
**Target Compliance Score:** 95%+ ✅

**Compliance Improvement Targets:**

- Flutter/Dart Code Generation Standards: 75% → 95%+
- Documentation Standards: 42% → 90%+
- Accessibility Standards: 0% → 85%+
- Template Organization: 56% → 90%+
- Developer Experience: 72% → 90%+

**Implementation Reference:** This plan has been updated to match the architecture and patterns
found in `/Users/apple/Desktop/dev/flutter/me/projects/Fly/examples/foundation_project`, which
serves as the reference implementation for the core architecture and components.

---

## Standards Compliance Overview

This plan has been comprehensively analyzed against industry standards and best practices. The
following compliance matrix outlines current state, target improvements, and implementation
priorities.

### Compliance Score Summary

| Category                         | Current Score | Target Score | Status      | Priority |
|----------------------------------|---------------|--------------|-------------|----------|
| **Feature-Based Architecture**   | 100%          | 100%         | ✅ Excellent | -        |
| **MVVM Pattern Implementation**  | 100%          | 100%         | ✅ Excellent | -        |
| **State Management Integration** | 100%          | 100%         | ✅ Excellent | -        |
| **CLI Tool Template Systems**    | 92%           | 95%          | ✅ Excellent | Low      |
| **Mason Brick Template Design**  | 85%           | 90%          | ✅ Good      | Low      |
| **Flutter/Dart Code Generation** | 75%           | 95%          | ⚠️ Good     | **High** |
| **Template Organization**        | 56%           | 90%          | ⚠️ Moderate | **High** |
| **Developer Experience**         | 72%           | 90%          | ⚠️ Moderate | Medium   |
| **Documentation Standards**      | 42%           | 90%          | ❌ Poor      | **High** |
| **Accessibility Standards**      | 0%            | 85%          | ❌ Critical  | **High** |
| **Overall Compliance**           | **82%**       | **95%+**     | ⚠️ Good     | -        |

### Critical Gaps Requiring Immediate Attention

1. **Accessibility Standards (0% → 85%+)**
    - Missing semantic labels in generated widgets
    - No screen reader support
    - Missing keyboard navigation
    - No color contrast guidelines
    - **Impact:** Legal compliance risk, exclusion of users with disabilities

2. **Documentation Standards (42% → 90%+)**
    - Missing comprehensive best practices guide (20+ sections required)
    - Incomplete API reference documentation
    - Limited generated code documentation
    - Missing workflow documentation
    - **Impact:** Poor developer experience, increased support burden

3. **Code Generation Workflow (56% → 95%+)**
    - Missing explicit `build.yaml` configuration
    - Limited build workflow documentation
    - No incremental build support documentation
    - **Impact:** Build performance issues, developer confusion

4. **Template Organization (56% → 90%+)**
    - Missing template versioning strategy
    - No template composition patterns
    - Limited template structure validation
    - **Impact:** Template maintenance challenges, quality issues

### Compliance Improvement Roadmap

**Phase 1 (Weeks 1-2):** Address critical gaps → Compliance: 90%+  
**Phase 2 (Weeks 3-4):** Enhance developer experience → Compliance: 95%+  
**Phase 3 (Weeks 5-8):** Complete documentation → Compliance: 98%+  
**Phase 4 (Ongoing):** Continuous improvement → Compliance: Industry-leading

---

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
   └── foundation/         # Base classes (BaseScreen, BaseViewModel)
       └── screen/
           ├── base_screen.dart
           └── base_view_model.dart
   ```
   
   **Note:** Additional core directories (analytics, database, di, event_system, models, navigation, pagination, providers, repositories, services, storage) can be added as needed for specific project requirements. The foundation project includes these, but the template generates a minimal structure with only foundation by default.

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

12. **Event System** (Optional):
    - Uses `fly_events` package
    - `AppEventEmitter` from GlobalContainer (when DI is enabled)
    - Event definitions can be added to `core/event_system/` when needed
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
└── fly_foundation/
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
fly_foundation/
├── __brick__/
│   ├── {{#is_project}}
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── core/
│   │   │   │   └── foundation/
│   │   │   │       └── screen/
│   │   │   │           ├── base_screen.dart
│   │   │   │           └── base_view_model.dart
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
│   │                   │   └── {{name}}_screen.dart
│   │                   {{#with_viewmodel}}
│   │                   ├── view_models/
│   │                   │   └── {{name}}_view_model.dart
│   │                   {{/with_viewmodel}}
│   │                   {{#with_tests}}
│   │                   └── test/
│   │                       └── {{name}}_screen_test.dart
│   │                   {{/with_tests}}
│   │   {{/is_screen}}
│   │
│   ├── {{#is_service}}
│   │   └── lib/
│   │       └── core/
│   │           └── services/
│   │               └── {{name}}_service.dart
│   │       {{#with_provider}}
│   │       └── core/
│   │           └── providers/
│   │               └── service_providers.dart (add provider)
│   │       {{/with_provider}}
│   │       {{#with_tests}}
│   │       └── test/
│   │           └── core/
│   │               └── services/
│   │                   └── {{name}}_service_test.dart
│   │       {{/with_tests}}
│   │   {{/is_service}}
│   │   Note: Services are generated in core/services/ directory which is created when needed
│   │
│   └── {{#is_provider}}
│       └── lib/
│           └── core/
│               └── providers/
│                   └── {{name}}_provider.dart
│       {{/is_provider}}
│       Note: Providers are generated in core/providers/ directory which is created when needed
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

**name** (string) - **REQUIRED when component**

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

- `{{name.pascalCase()}}` - PascalCase for class names
- `{{name.snakeCase()}}` - snake_case for file names
- `{{name.camelCase()}}` - camelCase for variable names
- `{{project_name.snakeCase()}}` - Project name in snake_case

### 2.4 Template Files

#### Project Mode Files

**pubspec.yaml**

- Dynamic package dependencies based on selected Fly packages
- Code generation dependencies (build_runner, riverpod_generator)
- Platform-specific configurations
- Conditional dependencies based on `fly_packages` variable

**main.dart**

- `GlobalContainer.initialize()` before `runApp()` (when DI is enabled)
- `UncontrolledProviderScope` with `GlobalContainer.instance` (when DI is enabled)
- Storage services initialization (regularStorage, secureStorage) - optional, when storage is needed
- App data manager initialization - optional, when storage managers are needed
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

**Note on Additional Core Directories:**

The foundation project includes additional core directories (analytics, database, di, event_system, models, navigation, pagination, providers, repositories, services, storage) that can be added as needed. The template generates a minimal structure with only the foundation directory by default. Additional directories can be added:

- When specific features are enabled (e.g., database when `with_database=true`)
- When generating components that require them (e.g., services directory when generating a service)
- Manually as the project grows

**global_container.dart** (core/di/global_container.dart) - Optional

- ProviderContainer singleton
- `initialize()` method for app startup
- `overrideForTesting()` for test support
- `reset()` for test cleanup
- Generated when dependency injection is needed

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

**{{name}}_screen.dart**

- Extends `BaseScreen<V, S>` (which extends `FlyScreen<V, S>`)
- ViewModel integration via `getViewModelProvider()` method
- State management with Riverpod providers
- Error handling integration via `runAsyncOperation()` in ViewModel
- Navigation integration using `AppNavigator`
- Conditional rendering based on screen type
- Form validation (if enabled)
- Pull-to-refresh support via `onRefresh()` method
- Localization support via `AppLocalizations`

**{{name}}_view_model.dart** (if with_viewmodel=true)

- Extends `BaseViewModel<S>` (which extends `FlyViewModel<S>`)
- State class implementing `FlyViewModelState<S>`
- Uses `runAsyncOperation()` for async operations
- Integration with services via providers
- Error handling via `runAsyncOperation()` error callbacks
- Loading state management
- Screen type-specific logic
- Provider definition: `final {{name}}ViewModelProvider = NotifierProvider<...>`

**{{name}}_screen_test.dart** (if with_tests=true)

- Widget tests
- Provider mocking
- Navigation testing
- Error state testing

#### Service Mode Files

**{{name}}_service.dart**

- Service class with dependency injection via providers
- Returns `AppResult<T>` from `fly_flow_guard` for consistent error handling
- Uses `FlyLogger` for logging
- Integration with repositories (if needed)
- Integration with storage managers (if needed)
- Retry logic with connectivity (if enabled)
- Caching support via `CacheService` (if enabled)
- API endpoint definitions
- Provider definition: `final {{name}}ServiceProvider = Provider<...>`

**{{name}}_service_test.dart** (if with_tests=true)

- Service tests
- API mocking
- Error handling tests
- Retry logic tests

#### Provider Mode Files

**{{name}}_provider.dart**

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

final {{name}}ViewModelProvider = NotifierProvider<{{ComponentName}}ViewModel, {{ComponentName}}ViewModelState>(
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

## 3. Recommendations Integration Matrix

This section maps all 25 prioritized recommendations to implementation tasks, organized by phase and
priority level.

### High-Priority Recommendations (8) - Must Address

| ID     | Recommendation                            | Phase   | Success Criteria                                                          | Dependencies       |
|--------|-------------------------------------------|---------|---------------------------------------------------------------------------|--------------------|
| **H1** | Add Explicit `build.yaml` Configuration   | Phase 1 | `build.yaml` included in all projects, 20%+ build performance improvement | None               |
| **H2** | Create Comprehensive Best Practices Guide | Phase 1 | Guide with 20+ sections, 90%+ developer satisfaction                      | None               |
| **H3** | Document Code Generation Workflow         | Phase 1 | Comprehensive workflow docs, 90%+ developer understanding                 | H1                 |
| **H4** | Add Accessibility Best Practices          | Phase 1 | All widgets include accessibility support, passes audits                  | None               |
| **H5** | Implement Template Structure Validation   | Phase 2 | Zero validation failures in production                                    | Phase 1 foundation |
| **H6** | Create Comprehensive Quick Start Guide    | Phase 1 | Project generation in < 5 minutes, 90%+ success rate                      | None               |
| **H7** | Add Incremental Build Support             | Phase 1 | `build_runner watch` documented, 50%+ build time reduction                | H1                 |
| **H8** | Improve Generated Code Documentation      | Phase 2 | 90%+ code coverage with documentation                                     | Phase 1 foundation |

### Medium-Priority Recommendations (10) - Should Address

| ID      | Recommendation                          | Phase   | Success Criteria                                         | Dependencies       |
|---------|-----------------------------------------|---------|----------------------------------------------------------|--------------------|
| **M1**  | Implement Template Versioning Strategy  | Phase 2 | Versioning strategy defined, smooth migration experience | Phase 1 foundation |
| **M2**  | Create Detailed Migration Guide         | Phase 2 | 90%+ successful migration rate                           | M1                 |
| **M3**  | Add Comprehensive API Reference         | Phase 3 | 100% API coverage, 90%+ developer satisfaction           | Phase 2 foundation |
| **M4**  | Define Template Composition Patterns    | Phase 3 | Patterns defined and documented                          | Phase 2 foundation |
| **M5**  | Add Troubleshooting Guide               | Phase 2 | 80%+ issue resolution rate                               | Phase 1 foundation |
| **M6**  | Compare with Very Good CLI Patterns     | Phase 3 | Comparison document created, improvements identified     | Phase 2 foundation |
| **M7**  | Add Generated File Exclusion Strategy   | Phase 3 | Zero version control issues                              | H1                 |
| **M8**  | Add FlutterFire CLI Pattern Analysis    | Phase 3 | Pattern analysis completed                               | Phase 2 foundation |
| **M9**  | Add Community Standards Alignment       | Phase 3 | Community conventions aligned                            | Phase 2 foundation |
| **M10** | Add Performance Optimization Guidelines | Phase 3 | Performance benchmarks met                               | Phase 2 foundation |

### Low-Priority Recommendations (7) - Nice-to-Have

| ID     | Recommendation                          | Phase   | Success Criteria                  | Dependencies       |
|--------|-----------------------------------------|---------|-----------------------------------|--------------------|
| **L1** | Add Code Comment Generation             | Phase 4 | Comments added to complex logic   | Phase 3 foundation |
| **L2** | Add FAQ Section                         | Phase 4 | 80%+ question coverage            | Phase 3 foundation |
| **L3** | Add Video Tutorials                     | Phase 4 | High production quality tutorials | Phase 3 foundation |
| **L4** | Add Template Testing Examples           | Phase 4 | Test examples included            | Phase 3 foundation |
| **L5** | Add Security Best Practices             | Phase 4 | Security audits passed            | Phase 3 foundation |
| **L6** | Add Internationalization Best Practices | Phase 4 | i18n patterns documented          | Phase 3 foundation |
| **L7** | Add Analytics Integration Patterns      | Phase 4 | Analytics patterns included       | Phase 3 foundation |

---

## 4. Implementation Plan

### Phase 1: Critical Improvements (Weeks 1-2)

**Focus:** Address critical gaps for production readiness  
**Target Outcome:** Compliance score improves to 90%+  
**Key Deliverables:** Accessibility support, build configuration, best practices guide, quick start
guide

#### Week 1: Foundation and Critical Standards

**Tasks:**

1. **Unified Template Structure** (Foundation)
    - Remove existing templates from `packages/fly_cli/templates/`
    - Create `fly_foundation` template directory structure
    - Define `brick.yaml` with `generation_mode` and all variable definitions
    - Create `template.yaml` with Fly CLI metadata
    - Implement conditional logic helpers (is_project, is_screen, etc.)
    - Create core template files structure with conditionals
    - Implement variable validation logic based on generation_mode

2. **H1: Explicit `build.yaml` Configuration** ⭐ HIGH PRIORITY
    - Create comprehensive `build.yaml` template with all generators configured
    - Add builder ordering for optimal performance (riverpod_generator → drift_dev → auto_mappr →
      json_serializable)
    - Include incremental build configuration
    - Document configuration options and performance optimizations
    - Add to project mode template generation
    - **Success Criteria:** `build.yaml` included in all generated projects, 20%+ build performance
      improvement

3. **H4: Accessibility Best Practices** ⭐ HIGH PRIORITY
    - Research Flutter accessibility guidelines (WCAG 2.1 compliance)
    - Add semantic labels to all widget templates (Semantics widget)
    - Include accessibility properties in generated screens
    - Add keyboard navigation support to generated widgets
    - Include color contrast guidelines in theme templates
    - Create accessibility documentation section
    - Add accessibility tests to template generation
    - **Success Criteria:** All generated widgets include semantic labels, screen reader support,
      keyboard navigation, passes accessibility audits

4. **H6: Comprehensive Quick Start Guide** ⭐ HIGH PRIORITY
    - Create step-by-step quick start guide:
        - Installation instructions
        - First project generation (< 5 minutes)
        - Running the project
        - Next steps and common workflows
    - Add code examples and visual aids
    - Include troubleshooting tips for common issues
    - Add to template README
    - **Success Criteria:** Project generation in < 5 minutes, 90%+ success rate for first-time
      users

**Deliverables:**
- Unified template structure (`fly_foundation/`)
- Complete `brick.yaml` with all variables
- `template.yaml` with metadata
- Comprehensive `build.yaml` configuration
- Accessibility support in all generated widgets
- Quick start guide documentation
- Unit tests for variable validation

#### Week 2: Documentation and Workflow

**Tasks:**

1. **H2: Comprehensive Best Practices Guide** ⭐ HIGH PRIORITY
    - Research industry best practices (Very Good CLI, Flutter Architecture Recommendations)
    - Create guide structure with 20+ sections:
        - Architecture patterns (MVVM, Clean Architecture)
        - Code organization (feature-based structure)
        - State management (Riverpod best practices)
        - Error handling (AppResult pattern)
        - Testing strategies (unit, widget, integration)
        - Performance optimization
        - Security best practices
        - Accessibility guidelines
        - Code generation workflows
        - Navigation patterns
        - Dependency injection patterns
        - Repository patterns
        - Service patterns
        - Storage patterns
        - Database patterns
        - Localization patterns
        - Event system patterns
        - MCP integration patterns
        - AI integration patterns
        - Troubleshooting common issues
    - Add code examples and anti-patterns for each section
    - Include in template documentation
    - **Success Criteria:** Best practices guide with 20+ sections, covers all major scenarios, 90%+
      developer satisfaction

2. **H3: Code Generation Workflow Documentation** ⭐ HIGH PRIORITY
    - Document build commands:
        - `build_runner build --delete-conflicting-outputs` (clean builds)
        - `build_runner watch` (incremental development)
        - `build_runner build` (production builds)
    - Create workflow diagrams (development vs. production)
    - Document development workflow:
        - Initial project setup
        - Adding new features
        - Running code generation
        - Handling conflicts
    - Document production workflow:
        - Pre-deployment code generation
        - CI/CD integration
        - Build optimization
    - Add troubleshooting section:
        - Common build errors
        - Conflict resolution
        - Performance issues
    - Include in template README and best practices guide
    - **Success Criteria:** Comprehensive workflow documentation, 90%+ developer understanding

3. **H7: Incremental Build Support** ⭐ HIGH PRIORITY
    - Document `build_runner watch` usage for development
    - Add to development workflow documentation
    - Include in quick start guide
    - Add troubleshooting tips for watch mode issues
    - Document performance benefits (50%+ build time reduction)
    - Include in template README
    - **Success Criteria:** Incremental build workflow documented, `build_runner watch` included in
      development workflow, 50%+ build time reduction

4. **Project Mode Implementation**
    - Implement project mode template files:
        - `pubspec.yaml` with dynamic dependencies
        - `main.dart` with GlobalContainer and router
        - `app_router.dart` with FeatureScreen enum and RouteHandlerRegistry
        - `app_theme.dart` with Material 3 and accessibility support
        - `app_config.dart` with environment config
        - `build.yaml` with explicit configuration (H1)
        - `analysis_options.yaml` with generated file exclusions
        - `.gitignore` with generated file patterns
        - `README.md` with quick start guide (H6)
    - Implement feature-based directory generation
    - Add MCP integration templates
    - Add AI context export templates
    - Implement post-generation hooks (build_runner, format)

**Deliverables:**

- Comprehensive best practices guide (20+ sections)
- Code generation workflow documentation
- Incremental build support documentation
- Complete project mode templates with accessibility
- MCP integration setup
- Post-generation automation
- Integration tests for project generation

**Phase 1 Success Metrics:**

- ✅ Compliance score: 90%+
- ✅ Accessibility support: 85%+ compliance
- ✅ Build configuration: 95%+ compliance
- ✅ Documentation coverage: 70%+ compliance
- ✅ All high-priority recommendations (H1-H7) implemented

---

### Phase 2: Important Improvements (Weeks 3-4)

**Focus:** Enhance developer experience and documentation  
**Target Outcome:** Compliance score improves to 95%+  
**Key Deliverables:** Template validation, versioning, migration guide, API reference foundation

#### Week 3: Component Modes and Template Validation

**Tasks:**

1. **Screen Mode Implementation**
    - Implement screen mode templates with accessibility support (H4):
        - Screen widget with BaseScreen and Semantics
        - ViewModel template (conditional) with accessibility considerations
        - Test template (conditional) with accessibility tests
        - Screen type-specific logic (list, detail, form, auth, settings)
    - Add conditional ViewModel integration
    - Add conditional navigation integration
    - Add conditional form validation with accessibility

2. **Service Mode Implementation**
    - Implement service mode templates:
        - Service class with fly_networking
        - Test template (conditional)
        - Retry logic integration
        - Caching support (conditional)

3. **Provider Mode Implementation**
    - Implement provider mode templates:
        - Provider with @riverpod annotation
        - Provider type variations (notifier, future, stream, state)
        - State class generation (conditional)

4. **H5: Template Structure Validation** ⭐ HIGH PRIORITY
    - Define validation rules:
        - Variable validation (type, required, constraints)
        - File structure validation (required files, directory structure)
        - Conditional logic validation (Mustache conditionals)
        - Naming convention validation (Dart naming standards)
    - Implement validation checks:
        - Pre-generation validation
        - Post-generation validation
        - Template integrity checks
    - Add to template testing suite
    - Integrate into CI/CD pipeline
    - Document validation rules
    - **Success Criteria:** Template validation implemented, all templates pass validation, zero
      validation failures in production

5. **H8: Improve Generated Code Documentation** ⭐ HIGH PRIORITY
    - Add API documentation to all template classes:
        - Class-level documentation
        - Method documentation
        - Parameter documentation
        - Return value documentation
    - Include inline comments for complex logic:
        - State management patterns
        - Error handling flows
        - Navigation logic
        - Async operation handling
    - Add code examples in documentation:
        - Usage examples
        - Integration examples
        - Best practice examples
    - Follow Dart documentation conventions
    - **Success Criteria:** All generated classes have API documentation, 90%+ code coverage with
      documentation

**Deliverables:**

- Screen mode templates with accessibility
- Service mode templates
- Provider mode templates
- Template structure validation system
- Improved generated code documentation
- Integration tests for component generation

#### Week 4: Versioning, Migration, and Troubleshooting

**Tasks:**

1. **M1: Template Versioning Strategy** ⭐ MEDIUM PRIORITY
    - Define versioning scheme (semantic versioning: MAJOR.MINOR.PATCH)
    - Implement version detection:
        - Template version in `template.yaml`
        - Project version tracking
        - Version compatibility checking
    - Create migration support:
        - Version migration scripts
        - Breaking change detection
        - Migration guides per version
    - Develop migration tools:
        - Automated migration scripts
        - Manual migration guides
        - Version compatibility matrix
    - Document versioning strategy
    - **Success Criteria:** Versioning strategy defined and documented, migration support
      implemented, smooth migration experience

2. **M2: Detailed Migration Guide** ⭐ MEDIUM PRIORITY
    - Identify migration scenarios:
        - Old templates → Unified template
        - Very Good CLI → Fly CLI
        - Other tools → Fly CLI
    - Create step-by-step guides for each scenario:
        - Pre-migration checklist
        - Migration steps
        - Post-migration verification
        - Common issues and solutions
    - Develop migration tools:
        - Automated migration scripts where possible
        - Manual migration checklists
        - Migration validation tools
    - Document common issues:
        - Breaking changes
        - Compatibility issues
        - Workarounds
    - Include in template documentation
    - **Success Criteria:** Migration guide covers all scenarios, 90%+ successful migration rate

3. **M5: Troubleshooting Guide** ⭐ MEDIUM PRIORITY
    - Research common issues and errors:
        - Template generation errors
        - Build errors
        - Runtime errors
        - Integration issues
    - Document solutions for each issue:
        - Root cause analysis
        - Step-by-step solutions
        - Prevention strategies
    - Create troubleshooting guide structure:
        - Error message index
        - Issue categories
        - Search functionality
    - Include error message explanations:
        - What the error means
        - Why it occurs
        - How to fix it
    - Add to template documentation
    - **Success Criteria:** Troubleshooting guide covers common issues, 80%+ issue resolution rate

4. **Template Manager Updates**
    - Update template manager to support unified template:
        - Read `generation_mode` from variables
        - Map `generation_mode` to `BrickType` for compatibility
        - Update `_determineBrickType()` to handle unified template
        - Add mode-based variable validation
    - Update CLI commands to use unified template:
        - `fly create` → `generation_mode=project`
        - `fly generate screen` → `generation_mode=screen`
        - `fly generate service` → `generation_mode=service`
        - Add `fly generate provider` → `generation_mode=provider`
    - Update manifest parser to set appropriate generation_mode

**Deliverables:**

- Template versioning strategy and implementation
- Comprehensive migration guide
- Troubleshooting guide
- Updated template manager
- Updated CLI commands
- Manifest parser updates

**Phase 2 Success Metrics:**

- ✅ Compliance score: 95%+
- ✅ Template validation: 100% pass rate
- ✅ Generated code documentation: 90%+ coverage
- ✅ Migration success rate: 90%+
- ✅ All high-priority recommendations (H5, H8) implemented
- ✅ Medium-priority recommendations (M1, M2, M5) implemented

---

### Phase 3: Enhancement Improvements (Weeks 5-8)

**Focus:** Complete documentation and add enhancements  
**Target Outcome:** Compliance score reaches 98%+  
**Key Deliverables:** API reference, template composition, industry comparisons, performance
optimization

#### Week 5: API Reference and Template Composition

**Tasks:**

1. **M3: Comprehensive API Reference** ⭐ MEDIUM PRIORITY
    - Document all template variables:
        - Variable name and type
        - Description and purpose
        - Default values
        - Validation rules
        - Usage examples
    - Create API reference structure:
        - Variables by mode (project, screen, service, provider)
        - Variables by category (required, optional, conditional)
        - Search functionality
        - Cross-references
    - Include usage examples:
        - Basic usage examples
        - Advanced usage examples
        - Integration examples
    - Add search functionality
    - Include in template documentation
    - **Success Criteria:** All variables documented, 100% API coverage, 90%+ developer satisfaction

2. **M4: Template Composition Patterns** ⭐ MEDIUM PRIORITY
    - Research composition patterns:
        - Mason brick composition
        - Template inheritance
        - Template extension
        - Template composition strategies
    - Define composition strategies:
        - When to compose templates
        - How to compose templates
        - Best practices for composition
    - Document patterns with examples:
        - Basic composition examples
        - Advanced composition examples
        - Real-world use cases
    - Test composition patterns:
        - Validate composition works correctly
        - Test edge cases
        - Performance testing
    - Include in template documentation
    - **Success Criteria:** Composition patterns defined, strategies documented, examples provided

3. **M7: Generated File Exclusion Strategy** ⭐ MEDIUM PRIORITY
    - Document exclusion patterns:
        - Generated file patterns (`*.g.dart`, `*.freezed.dart`, etc.)
        - Build output patterns
        - Temporary file patterns
    - Create `.gitignore` template:
        - All generated file patterns
        - Build output directories
        - IDE-specific files
    - Configure `analysis_options.yaml`:
        - Exclude generated files from analysis
        - Performance optimizations
    - Include in template generation
    - Document in best practices guide
    - **Success Criteria:** Exclusion patterns documented, zero version control issues

4. **Fly Ecosystem Integration**
    - Integrate fly_core patterns (BaseScreen, BaseViewModel)
    - Integrate fly_state patterns
    - Integrate fly_networking patterns
    - Integrate fly_navigation patterns
    - Integrate fly_errors error handling patterns
    - Integrate fly_logger logging patterns
    - Create integration tests with generated projects
    - Verify all Fly packages work correctly

**Deliverables:**

- Comprehensive API reference documentation
- Template composition patterns and documentation
- Generated file exclusion strategy
- Fly ecosystem package integration
- Integration tests passing

#### Week 6: Industry Comparisons and Community Alignment

**Tasks:**

1. **M6: Very Good CLI Pattern Comparison** ⭐ MEDIUM PRIORITY
    - Research Very Good CLI patterns:
        - Template organization
        - Best practices enforcement
        - Documentation standards
        - Testing strategies
    - Compare with Fly template plan:
        - Template structure comparison
        - Best practices comparison
        - Documentation comparison
        - Feature comparison
    - Identify best practices:
        - Practices to adopt
        - Practices to improve
        - Unique Fly advantages
    - Document findings:
        - Comparison matrix
        - Best practices identified
        - Improvement recommendations
    - Create improvement recommendations
    - **Success Criteria:** Comparison document created, best practices identified, improvements
      documented

2. **M8: FlutterFire CLI Pattern Analysis** ⭐ MEDIUM PRIORITY
    - Research FlutterFire CLI patterns:
        - Integration-focused templates
        - Platform configuration
        - Setup automation
        - Dependency management
    - Analyze integration strategies:
        - How FlutterFire handles integrations
        - Platform-specific configurations
        - Automation patterns
    - Document findings:
        - Integration patterns identified
        - Best practices extracted
        - Improvement opportunities
    - Identify improvements:
        - Integration patterns to adopt
        - Automation improvements
        - Configuration improvements
    - Create recommendations
    - **Success Criteria:** Pattern analysis completed, integration strategies identified,
      improvements recommended

3. **M9: Community Standards Alignment** ⭐ MEDIUM PRIORITY
    - Research Flutter community conventions:
        - Dart Style Guide compliance
        - Flutter best practices
        - Community patterns
        - Naming conventions
    - Compare with template plan:
        - Identify alignment gaps
        - Identify deviations
        - Identify improvements
    - Align template with conventions:
        - Update template patterns
        - Update naming conventions
        - Update code style
    - Document alignment:
        - Alignment matrix
        - Deviations and rationale
        - Community feedback integration
    - Update template as needed
    - **Success Criteria:** Community conventions aligned, alignment documented, positive community
      feedback

4. **Manifest-Based Generation**
    - Implement manifest parser (YAML)
    - Create manifest-to-variables converter
    - Implement multi-feature generation from manifest
    - Add environment-specific configuration
    - Implement custom template overrides
    - Enhance MCP integration templates
    - Add context export functionality
    - Add schema export templates

**Deliverables:**

- Very Good CLI comparison document
- FlutterFire CLI pattern analysis
- Community standards alignment documentation
- Manifest parsing system
- Multi-feature generation
- Enhanced MCP integration

#### Week 7: Performance Optimization and Testing

**Tasks:**

1. **M10: Performance Optimization Guidelines** ⭐ MEDIUM PRIORITY
    - Research performance best practices:
        - Flutter performance guidelines
        - Build performance optimization
        - Runtime performance optimization
        - Code generation performance
    - Add performance guidelines to template:
        - Build performance optimizations
        - Runtime performance patterns
        - Code generation optimizations
    - Include in generated code:
        - Performance-conscious patterns
        - Optimization hints
        - Performance monitoring integration
    - Document optimization strategies:
        - Build optimization strategies
        - Runtime optimization strategies
        - Profiling and monitoring
    - Add to best practices guide
    - **Success Criteria:** Performance guidelines included, optimization strategies documented,
      performance benchmarks met

2. **Comprehensive Testing**
    - Write unit tests for all template generation logic:
        - Variable validation tests
        - Mode-based validation logic tests
        - Template file generation tests
        - Conditional logic testing
        - Variable transformation tests
    - Write integration tests with Fly CLI:
        - Full project generation (all modes)
        - Component generation (screen, service, provider)
        - Code compilation verification
        - Fly CLI command integration
        - Manifest-based generation
    - End-to-end tests:
        - Complete project lifecycle
        - Component addition to existing project
        - Manifest-based generation
        - MCP integration setup
        - AI context export
    - Performance testing:
        - Generation speed benchmarks (< 5 seconds for standard project)
        - Component generation speed (< 2 seconds per component)
        - Large project generation (< 15 seconds for 10+ features)
        - Memory usage (< 500MB during generation)
    - Compatibility testing:
        - Flutter SDK versions (3.10.0+, 3.12.0+, 3.16.0+)
        - Dart SDK versions (3.0.0+, 3.2.0+, 3.4.0+)
        - All platforms (iOS, Android, Web, macOS, Windows, Linux)
        - All generation modes

**Deliverables:**

- Performance optimization guidelines
- Comprehensive test suite (80%+ coverage)
- Performance benchmarks
- Compatibility matrix
- Bug fixes and improvements

#### Week 8: Final Documentation and Examples

**Tasks:**

1. **Complete Documentation Package**
    - Finalize README.md with all sections:
        - Overview
        - Installation
        - Usage (all modes)
        - Generation modes explained
        - Variable reference
        - Examples for each mode
        - Advanced usage
        - Integration guides
        - Customization
        - Troubleshooting
        - Contributing
    - Complete API reference documentation
    - Finalize best practices guide (20+ sections)
    - Complete migration guide
    - Complete troubleshooting guide
    - Add FAQ section (L2 - Phase 4 preparation)

2. **Usage Examples**
    - Example 1: Minimal Project
        - Basic Flutter project
        - Minimal dependencies
        - Simple structure
    - Example 2: Riverpod Project
        - Full Riverpod setup
        - Multiple features
        - Complete integration
    - Example 3: Production Project
        - All Fly packages
        - MCP integration
        - AI context export
        - Complete documentation
    - Example 4: Screen Component
        - Screen with ViewModel
        - Navigation integration
        - Form validation
        - Accessibility support
    - Example 5: Service Component
        - API service
        - Retry logic
        - Caching support
    - Example 6: Provider Component
        - Provider with state class
        - Integration patterns

3. **Documentation Quality Assurance**
    - Review all documentation for completeness
    - Verify all examples work correctly
    - Check for broken links
    - Ensure consistent formatting
    - Validate code examples compile
    - Review accessibility of documentation

**Deliverables:**

- Complete documentation package
- Example projects and components
- All documentation reviewed and validated
- Documentation quality assurance complete

**Phase 3 Success Metrics:**

- ✅ Compliance score: 98%+
- ✅ API reference: 100% coverage
- ✅ Template composition: Patterns defined and documented
- ✅ Industry comparisons: Completed
- ✅ Performance optimization: Guidelines included
- ✅ Test coverage: 80%+
- ✅ All medium-priority recommendations (M3-M10) implemented

---

### Phase 4: Long-Term Enhancements (Ongoing)

**Focus:** Continuous improvement and enhancement  
**Target Outcome:** Industry-leading compliance and developer experience  
**Key Deliverables:** Code comments, FAQ, video tutorials, security, i18n, analytics

#### Ongoing Enhancements

**Tasks:**

1. **L1: Code Comment Generation** ⭐ LOW PRIORITY
    - Identify complex logic in templates
    - Add explanatory comments to templates
    - Document patterns in comments
    - Include in template generation
    - Review comment quality
    - **Success Criteria:** Comments added to complex logic, patterns explained, code readability
      improved

2. **L2: FAQ Section** ⭐ LOW PRIORITY
    - Research common questions:
        - Template usage questions
        - Troubleshooting questions
        - Integration questions
        - Best practices questions
    - Create FAQ structure:
        - Categorized questions
        - Searchable format
        - Regular updates
    - Document answers:
        - Clear, concise answers
        - Code examples where helpful
        - Links to detailed documentation
    - Make FAQ searchable
    - Include in template documentation
    - **Success Criteria:** FAQ covers common questions, 80%+ question coverage

3. **L3: Video Tutorials** ⭐ LOW PRIORITY
    - Plan video content and structure:
        - Quick start tutorial
        - Project generation tutorial
        - Component generation tutorials
        - Advanced usage tutorials
    - Create video scripts:
        - Step-by-step scripts
        - Visual aids planning
        - Code examples preparation
    - Record tutorials:
        - High production quality
        - Clear audio and video
        - Professional presentation
    - Edit and enhance videos:
        - Add captions
        - Add annotations
        - Add links to documentation
    - Publish and include in documentation
    - **Success Criteria:** Video tutorials created, high production quality, positive developer
      feedback

4. **L4: Template Testing Examples** ⭐ LOW PRIORITY
    - Research testing best practices:
        - Flutter testing guidelines
        - Unit testing patterns
        - Widget testing patterns
        - Integration testing patterns
    - Add test examples to templates:
        - Unit test examples
        - Widget test examples
        - Integration test examples
    - Include in generated code:
        - Test file templates
        - Test helper utilities
        - Testing best practices
    - Document testing strategies:
        - Testing approach
        - Test organization
        - Test coverage goals
    - Add to best practices guide
    - **Success Criteria:** Test examples included, testing strategies documented, test coverage
      improved

5. **L5: Security Best Practices** ⭐ LOW PRIORITY
    - Research security best practices:
        - Flutter security guidelines
        - Secure storage patterns
        - API security patterns
        - Authentication patterns
    - Add security guidelines to template:
        - Secure storage patterns
        - API security patterns
        - Authentication patterns
        - Data protection patterns
    - Include in generated code:
        - Security-conscious patterns
        - Security monitoring integration
        - Security best practices
    - Document security patterns:
        - Security guidelines
        - Security checklist
        - Security audit recommendations
    - Add to best practices guide
    - **Success Criteria:** Security guidelines included, security patterns documented, security
      audits passed

6. **L6: Internationalization Best Practices** ⭐ LOW PRIORITY
    - Research i18n best practices:
        - Flutter i18n guidelines
        - Localization patterns
        - RTL support patterns
    - Date/time formatting patterns
    - Enhance i18n support in template:
        - Improved localization setup
        - RTL support
        - Date/time formatting
        - Number formatting
    - Add examples:
        - Multi-language examples
        - RTL examples
        - Formatting examples
    - Document i18n patterns:
        - Localization guide
        - RTL support guide
        - Formatting guide
    - Add to best practices guide
    - **Success Criteria:** i18n best practices included, examples provided, i18n patterns
      documented

7. **L7: Analytics Integration Patterns** ⭐ LOW PRIORITY
    - Research analytics patterns:
        - Flutter analytics integration
        - Event tracking patterns
        - User behavior tracking
        - Performance monitoring
    - Add integration patterns to template:
        - Analytics setup patterns
        - Event tracking patterns
        - User behavior tracking patterns
    - Include in generated code:
        - Analytics integration examples
        - Event tracking utilities
        - Analytics best practices
    - Document analytics strategies:
        - Analytics setup guide
        - Event tracking guide
        - Analytics best practices
    - Add to best practices guide
    - **Success Criteria:** Analytics patterns included, integration examples provided, analytics
      strategies documented

**Phase 4 Success Metrics:**

- ✅ Industry-leading compliance: 98%+
- ✅ Developer satisfaction: 90%+
- ✅ All low-priority recommendations (L1-L7) implemented
- ✅ Continuous improvement process established
- ✅ Community feedback integration

---

## 5. Success Criteria and Measurable Metrics

This section defines measurable success criteria for each phase and overall project success, aligned
with industry standards and recommendations.

### Overall Success Criteria

**Compliance Targets:**

- ✅ **Overall Compliance Score**: 95%+ (Current: 82%)
- ✅ **Flutter/Dart Code Generation Standards**: 95%+ (Current: 75%)
- ✅ **Documentation Standards**: 90%+ (Current: 42%)
- ✅ **Accessibility Standards**: 85%+ (Current: 0%)
- ✅ **Template Organization**: 90%+ (Current: 56%)
- ✅ **Developer Experience**: 90%+ (Current: 72%)

**Quality Metrics:**

- ✅ **Test Coverage**: 80%+ code coverage
- ✅ **Template Generation Speed**: < 5 seconds for standard project
- ✅ **Component Generation Speed**: < 2 seconds per component
- ✅ **Build Performance**: 20%+ improvement in build times
- ✅ **Developer Satisfaction**: 90%+ satisfaction rate
- ✅ **Migration Success**: 90%+ successful migration rate
- ✅ **Template Quality**: Zero validation failures in production

**Documentation Metrics:**

- ✅ **Best Practices Guide**: 20+ sections
- ✅ **API Reference**: 100% API coverage
- ✅ **Generated Code Documentation**: 90%+ code coverage with documentation
- ✅ **Workflow Documentation**: Comprehensive coverage of all workflows
- ✅ **Accessibility Documentation**: Complete accessibility guidelines

**Accessibility Metrics:**

- ✅ **Semantic Labels**: All generated widgets include semantic labels
- ✅ **Screen Reader Support**: All widgets support screen readers
- ✅ **Keyboard Navigation**: All interactive widgets support keyboard navigation
- ✅ **Color Contrast**: All generated themes meet WCAG 2.1 AA standards
- ✅ **Accessibility Audits**: Generated code passes accessibility audits

### Phase-Specific Success Criteria

**Phase 1 (Weeks 1-2) - Critical Improvements:**

- ✅ Compliance score: 90%+
- ✅ Accessibility support: 85%+ compliance
- ✅ Build configuration: 95%+ compliance
- ✅ Documentation coverage: 70%+ compliance
- ✅ All high-priority recommendations (H1-H7) implemented
- ✅ Quick start guide enables project generation in < 5 minutes
- ✅ Best practices guide with 20+ sections created

**Phase 2 (Weeks 3-4) - Important Improvements:**

- ✅ Compliance score: 95%+
- ✅ Template validation: 100% pass rate
- ✅ Generated code documentation: 90%+ coverage
- ✅ Migration success rate: 90%+
- ✅ All high-priority recommendations (H5, H8) implemented
- ✅ Medium-priority recommendations (M1, M2, M5) implemented
- ✅ Template versioning strategy defined and documented

**Phase 3 (Weeks 5-8) - Enhancement Improvements:**

- ✅ Compliance score: 98%+
- ✅ API reference: 100% coverage
- ✅ Template composition: Patterns defined and documented
- ✅ Industry comparisons: Completed
- ✅ Performance optimization: Guidelines included
- ✅ Test coverage: 80%+
- ✅ All medium-priority recommendations (M3-M10) implemented

**Phase 4 (Ongoing) - Long-Term Enhancements:**

- ✅ Industry-leading compliance: 98%+
- ✅ Developer satisfaction: 90%+
- ✅ All low-priority recommendations (L1-L7) implemented
- ✅ Continuous improvement process established
- ✅ Community feedback integration

### Recommendation Implementation Checklist

**High-Priority Recommendations (8):**

- [ ] H1: Explicit `build.yaml` configuration - Phase 1
- [ ] H2: Comprehensive best practices guide - Phase 1
- [ ] H3: Code generation workflow documentation - Phase 1
- [ ] H4: Accessibility best practices - Phase 1
- [ ] H5: Template structure validation - Phase 2
- [ ] H6: Comprehensive quick start guide - Phase 1
- [ ] H7: Incremental build support - Phase 1
- [ ] H8: Generated code documentation - Phase 2

**Medium-Priority Recommendations (10):**

- [ ] M1: Template versioning strategy - Phase 2
- [ ] M2: Detailed migration guide - Phase 2
- [ ] M3: Comprehensive API reference - Phase 3
- [ ] M4: Template composition patterns - Phase 3
- [ ] M5: Troubleshooting guide - Phase 2
- [ ] M6: Very Good CLI pattern comparison - Phase 3
- [ ] M7: Generated file exclusion strategy - Phase 3
- [ ] M8: FlutterFire CLI pattern analysis - Phase 3
- [ ] M9: Community standards alignment - Phase 3
- [ ] M10: Performance optimization guidelines - Phase 3

**Low-Priority Recommendations (7):**

- [ ] L1: Code comment generation - Phase 4
- [ ] L2: FAQ section - Phase 4
- [ ] L3: Video tutorials - Phase 4
- [ ] L4: Template testing examples - Phase 4
- [ ] L5: Security best practices - Phase 4
- [ ] L6: Internationalization best practices - Phase 4
- [ ] L7: Analytics integration patterns - Phase 4

---
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

## 6. Standards Compliance Matrix

This section provides detailed compliance tracking for each category, including current scores,
target scores, gap analysis, and implementation tasks to close gaps.

### 6.1 Flutter/Dart Code Generation Standards

**Current Score: 75%** ⚠️ | **Target Score: 95%+** ✅

| Standard                     | Current State                 | Target State                       | Gap                         | Priority | Implementation Task                         |
|------------------------------|-------------------------------|------------------------------------|-----------------------------|----------|---------------------------------------------|
| build_runner Integration     | ✅ Mentioned                   | ✅ Required                         | None                        | -        | -                                           |
| build.yaml Configuration     | ⚠️ Mentioned but not detailed | ✅ Explicit configuration required  | Missing detailed config     | **High** | H1: Add explicit `build.yaml` configuration |
| Incremental Builds           | ❌ Not mentioned               | ✅ Standard practice                | Missing incremental support | Medium   | H7: Add incremental build support           |
| Generated File Management    | ✅ Basic exclusion             | ✅ Comprehensive exclusion strategy | Limited guidance            | Medium   | M7: Add generated file exclusion strategy   |
| Build Workflow Documentation | ⚠️ Minimal                    | ✅ Comprehensive workflow docs      | Missing detailed workflow   | **High** | H3: Document code generation workflow       |

**Compliance Checklist:**

✅ **build_runner Integration** (100% compliant)
- Uses `build_runner` for code generation
- Generated files in `.g.dart` format
- Delete conflicting outputs handling

⚠️ **build.yaml Configuration** (60% → Target: 95%+) - **H1 Implementation Required**

- ⚠️ Currently: Mentioned but not detailed
- ✅ Target: Explicit `build.yaml` configuration with builder ordering
- ✅ Target: Incremental build support configuration
- ✅ Target: Performance optimization settings

✅ **Riverpod Code Generation** (100% compliant)
- Uses `@riverpod` annotations (v3 syntax)
- Proper provider patterns
- Generated provider files
- State management best practices

✅ **Code Style** (88% compliant)
- Follows Dart style guide
- Uses `flutter_lints` package (v5.0.0)
- Custom linting rules via analyzer plugins (optional)
- Proper import organization
- Consistent naming conventions
- Excludes generated files from analysis (`*.g.dart`, `*.freezed.dart`)
- Linter rules: always_declare_return_types, avoid_print, prefer_const_constructors, etc.

**Gap Analysis:**

- **Critical Gap**: Missing explicit `build.yaml` configuration (H1)
- **Important Gap**: Missing incremental build support documentation (H7)
- **Moderate Gap**: Limited generated file exclusion guidance (M7)

**Implementation Tasks:**

1. **H1**: Create comprehensive `build.yaml` template with all generators configured
2. **H7**: Document `build_runner watch` usage for incremental builds
3. **M7**: Document comprehensive generated file exclusion patterns

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

### 6.6 Documentation Standards Compliance

**Current Score: 42%** ❌ | **Target Score: 90%+** ✅

| Standard                     | Current State | Target State                         | Gap                       | Priority | Implementation Task                           |
|------------------------------|---------------|--------------------------------------|---------------------------|----------|-----------------------------------------------|
| Best Practices Guide         | ❌ Missing     | ✅ Comprehensive guide (20+ sections) | Critical gap              | **High** | H2: Create comprehensive best practices guide |
| API Reference                | ⚠️ Planned    | ✅ Comprehensive API reference        | Missing detailed API docs | Medium   | M3: Add comprehensive API reference           |
| Generated Code Documentation | ⚠️ Limited    | ✅ Comprehensive inline docs          | Missing comment strategy  | **High** | H8: Improve generated code documentation      |
| Workflow Documentation       | ⚠️ Minimal    | ✅ Comprehensive workflow docs        | Missing detailed workflow | **High** | H3: Document code generation workflow         |
| Quick Start Guide            | ⚠️ Planned    | ✅ Comprehensive guide                | Needs comprehensive guide | **High** | H6: Create comprehensive quick start guide    |
| Migration Guide              | ⚠️ Basic      | ✅ Detailed migration path            | Limited migration docs    | Medium   | M2: Create detailed migration guide           |
| Troubleshooting Guide        | ⚠️ Planned    | ✅ Detailed guide                     | Needs detailed guide      | Medium   | M5: Add troubleshooting guide                 |

**Gap Analysis:**

- **Critical Gap**: Missing comprehensive best practices guide (H2)
- **Critical Gap**: Missing comprehensive workflow documentation (H3)
- **Critical Gap**: Missing comprehensive quick start guide (H6)
- **Important Gap**: Limited generated code documentation (H8)
- **Moderate Gap**: Missing detailed API reference (M3)
- **Moderate Gap**: Limited migration guide (M2)
- **Moderate Gap**: Missing troubleshooting guide (M5)

**Implementation Tasks:**

1. **H2**: Create best practices guide with 20+ sections covering all major development scenarios
2. **H3**: Document comprehensive code generation workflow (development and production)
3. **H6**: Create comprehensive quick start guide enabling project generation in < 5 minutes
4. **H8**: Add API documentation to all generated classes (90%+ code coverage)
5. **M3**: Create comprehensive API reference with 100% API coverage
6. **M2**: Create detailed migration guide covering all migration scenarios
7. **M5**: Create troubleshooting guide covering common issues and solutions

---

### 6.7 Accessibility Standards Compliance

**Current Score: 0%** ❌ | **Target Score: 85%+** ✅

| Standard                    | Current State   | Target State                                          | Gap                   | Priority | Implementation Task                  |
|-----------------------------|-----------------|-------------------------------------------------------|-----------------------|----------|--------------------------------------|
| Semantic Labels             | ❌ Not mentioned | ✅ All widgets include semantic labels                 | Missing accessibility | **High** | H4: Add accessibility best practices |
| Screen Reader Support       | ❌ Not mentioned | ✅ All widgets support screen readers                  | Missing accessibility | **High** | H4: Add accessibility best practices |
| Keyboard Navigation         | ❌ Not mentioned | ✅ All interactive widgets support keyboard navigation | Missing accessibility | **High** | H4: Add accessibility best practices |
| Color Contrast              | ❌ Not mentioned | ✅ All themes meet WCAG 2.1 AA standards               | Missing accessibility | **High** | H4: Add accessibility best practices |
| Accessibility Documentation | ❌ Not mentioned | ✅ Complete accessibility guidelines                   | Missing accessibility | **High** | H4: Add accessibility best practices |

**Compliance Checklist:**

❌ **Accessibility Support** (0% → Target: 85%+) - **H4 Implementation Required**

- ❌ Currently: Complete lack of accessibility support
- ✅ Target: All generated widgets include semantic labels (Semantics widget)
- ✅ Target: Screen reader support in all generated code
- ✅ Target: Keyboard navigation support for all interactive widgets
- ✅ Target: Color contrast guidelines included in theme templates
- ✅ Target: Accessibility documentation provided
- ✅ Target: Generated code passes accessibility audits

**Gap Analysis:**

- **Critical Gap**: Complete lack of accessibility standards (H4)
- **Impact**: Legal compliance risk, exclusion of users with disabilities
- **Required**: Immediate implementation of accessibility best practices

**Implementation Tasks:**

1. **H4**: Research Flutter accessibility guidelines (WCAG 2.1 compliance)
2. **H4**: Add semantic labels to all widget templates (Semantics widget)
3. **H4**: Include accessibility properties in generated screens
4. **H4**: Add keyboard navigation support to generated widgets
5. **H4**: Include color contrast guidelines in theme templates
6. **H4**: Create accessibility documentation section
7. **H4**: Add accessibility tests to template generation

---

### 6.8 Template Organization Standards Compliance

**Current Score: 56%** ⚠️ | **Target Score: 90%+** ✅

| Standard               | Current State     | Target State                  | Gap                          | Priority | Implementation Task                         |
|------------------------|-------------------|-------------------------------|------------------------------|----------|---------------------------------------------|
| Template Versioning    | ❌ Not addressed   | ✅ Versioning strategy needed  | No versioning plan           | Medium   | M1: Implement template versioning strategy  |
| Template Composition   | ⚠️ Not discussed  | ✅ Reusable components         | Missing composition strategy | Medium   | M4: Define template composition patterns    |
| Template Testing       | ⚠️ Output-focused | ✅ Structure validation needed | Limited template testing     | **High** | H5: Implement template structure validation |
| Template Documentation | ✅ Basic           | ✅ Comprehensive inline docs   | Missing detailed docs        | Low      | L1: Add code comment generation             |

**Gap Analysis:**

- **Important Gap**: Missing template versioning strategy (M1)
- **Important Gap**: Missing template composition patterns (M4)
- **Critical Gap**: Limited template structure validation (H5)
- **Low Priority Gap**: Missing detailed template documentation (L1)

**Implementation Tasks:**

1. **H5**: Implement template structure validation (variable, file structure, conditional logic,
   naming)
2. **M1**: Implement template versioning strategy (semantic versioning)
3. **M4**: Define template composition patterns and strategies
4. **L1**: Add code comment generation for complex logic

---

## 7. Quality Assurance Plan

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

    - What is fly_foundation
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

This plan provides a comprehensive roadmap for developing a unified Mason brick template (
`fly_foundation`) that generates both Flutter projects and individual components using a single,
consistent template system. The 8-week implementation plan ensures systematic development with clear
deliverables, quality assurance, and comprehensive documentation.

The unified approach eliminates template duplication, ensures consistency, simplifies maintenance,
and provides a single source of truth for Fly CLI patterns and ecosystem integration standards.

**Plan Updates:** This plan has been thoroughly analyzed and updated to match the architecture and
implementation patterns found in the foundation project (
`/Users/apple/Desktop/dev/flutter/me/projects/Fly/examples/foundation_project`). Key updates
include:

- Updated project structure to match foundation project's simplified core structure (only foundation
  directory by default)
- Updated core organization to generate minimal structure with only `core/foundation/` directory
  initially
- Additional core directories (analytics, database, di, event_system, models, navigation,
  pagination, providers, repositories, services, storage) are optional and can be added as needed
- Updated dependency injection pattern to use `GlobalContainer` (ProviderContainer singleton) -
  optional, generated when needed
- Updated navigation pattern to use `FeatureScreen` enum and `RouteHandlerRegistry` with MaterialApp
- Added repository pattern with `BaseRepository` and Template Method Pattern - optional, when
  repositories are needed
- Updated service pattern to return `AppResult<T>` from `fly_flow_guard` - services directory
  created when generating services
- Added storage pattern with interfaces and managers - optional, when storage is needed
- Added database pattern using Drift (SQLite) - optional, when database is needed
- Updated code generation to include drift_dev, auto_mappr, and json_serializable
- Updated localization pattern to use Flutter gen-l10n with `.arb` files
- Added event system integration via `fly_events` package - optional, when events are needed
- Updated base classes to extend `BaseScreen` and `BaseViewModel` from foundation project
- Updated dependencies to match foundation project versions

**Next Steps:**

1. Review and approve plan
2. Remove existing templates
3. Set up unified template structure
4. Begin Phase 1 implementation
5. Establish testing infrastructure
6. Create documentation framework