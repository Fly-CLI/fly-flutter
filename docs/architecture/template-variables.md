# Template Variable Architecture

## Overview

The `fly_foundation` template uses a strongly-typed, enum-oriented variable management system that
replaces ad-hoc `Map<String, dynamic>` usage with type-safe models and enums.

## Architecture Components

### 1. Shared Enums (`foundation_enums.dart`)

All categorical variables are defined as enums with parsing and serialization helpers:

- **`GenerationMode`**: `project`, `feature`, `service`
- **`ScreenType`**: `list`, `detail`, `form`, `auth`, `settings`
- **`ServiceType`**: `api`, `local`, `cache`, `analytics`, `storage`
- **`PlatformType`**: `ios`, `android`, `web`, `macos`, `windows`, `linux`
- **`StateManagement`**: `riverpod`, `bloc`, `cubit`

Each enum provides:

- `key` getter: Returns the canonical string used in Mason variables
- `fromKey(String)`: Parses a string to the enum value (throws on invalid)
- `tryFromKey(String?, {defaultValue})`: Safe parsing with default fallback

### 2. Core Models (`foundation_variables.dart`)

#### `BaseTemplateVariables`

Represents user-provided input variables with proper types:

- Common fields: `name`, `organization`, `generationMode`, `platforms`, `description`, etc.
- Cross-cutting flags: `withTests`, `withDocs`, `withMcp`, `codeGeneration`, `aiIntegration`
- Mode-specific optional fields: `screenType`, `serviceType`, `apiBaseUrl`, `preset`
- Methods:
    - `fromMasonVars(Map<String, dynamic>)`: Parses from Mason variable map
    - `toMasonVars()`: Converts to Mason variable map (for backward compatibility)
    - `copyWith(...)`: Creates immutable copy with updated fields

#### `DerivedTemplateVariables`

Represents computed/derived flags and values from planner plugins:

- Platform flags: `supportsIos`, `supportsAndroid`, etc.
- Feature flags: `screenType`, `isListScreen`, `isDetailScreen`, etc.
- Service flags: `serviceType`, `isApiService`, `supportsRetry`, etc.
- Naming-derived values: `projectName`, `feature`, `componentName`, etc.
- Methods:
    - `empty()`: Creates empty instance
    - `merge(DerivedTemplateVariables)`: Merges with another instance
    - `toMasonVars()`: Converts to Mason variable map

### 3. Hook System (`hooks/plugins/`)

The template hooks use a planner plugin architecture:

#### `PlannerPlugin` Interface

```dart
abstract class PlannerPlugin {
  bool canHandle(BaseTemplateVariables base);

  DerivedTemplateVariables derive(BaseTemplateVariables base,
      DerivedTemplateVariables acc,
      Logger logger,);
}
```

#### Planner Plugins

- **`PresetPlanner`**: Applies preset configurations (now handled in `pre_gen.dart`)
- **`CoreVarsPlanner`**: Derives core naming and mode flags
- **`ProjectModePlanner`**: Adds project-specific platform flags
- **`FeatureModePlanner`**: Adds feature-specific screen and state management flags
- **`ServiceModePlanner`**: Adds service-specific type and capability flags

#### `CompositePlanner`

Orchestrates multiple planners, merging their derived variables in sequence.

### 4. Hook Entry Point (`pre_gen.dart`)

The main hook entry point:

1. Parses raw Mason variables into `BaseTemplateVariables`
2. Applies preset if specified
3. Runs planners to compute derived variables
4. Converts derived variables back to Mason format and adds to context

## Usage Patterns

### Adding a New Variable Category

1. **Add enum** in `foundation_enums.dart`:
   ```dart
   enum MyCategory { option1, option2; }
   ```

2. **Add to models**:
    - Add field to `BaseTemplateVariables` if user-provided
    - Add field to `DerivedTemplateVariables` if computed
    - Update `fromMasonVars`/`toMasonVars` methods

3. **Update planners** if the variable affects derived logic

4. **Update validators** to use enum values

### Accessing Variables in Planners

```dart
@override
DerivedTemplateVariables derive(BaseTemplateVariables base,
    DerivedTemplateVariables acc,
    Logger logger,) {
  // Type-safe access
  if (base.generationMode == GenerationMode.feature) {
    final screenType = base.screenType ?? ScreenType.list;
    // Use enum comparisons
    if (screenType == ScreenType.form) {
      // ...
    }
  }

  return DerivedTemplateVariables(
    // Set derived flags
    isFeature: true,
    screenType: screenType,
    // ...
  );
}
```

### Backward Compatibility

The system maintains backward compatibility with Mason templates:

- All enum values serialize to their canonical string keys via `toMasonVars()`
- Mason templates continue to receive the same variable keys and types
- No changes required to existing Mustache templates

## Benefits

1. **Type Safety**: Compile-time checks prevent typos and type errors
2. **IDE Support**: Autocomplete and refactoring support for all variables
3. **Single Source of Truth**: Centralized enum definitions eliminate duplication
4. **Maintainability**: Clear, testable architecture that's easy to extend
5. **Error Prevention**: Enum parsing validates input early with clear error messages

## Migration Notes

- Old string-based comparisons (`screenType == 'list'`) replaced with enum comparisons (
  `screenType == ScreenType.list`)
- Map access (`vars['key']`) replaced with property access (`base.field`)
- Type casting (`as String?`) eliminated through proper typing
- Validation now uses enum parsers instead of string set checks

