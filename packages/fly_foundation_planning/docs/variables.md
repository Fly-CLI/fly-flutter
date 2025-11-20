# Variable System

The planning system uses a multi-layered variable derivation approach to compute the correct variables for each brick.

## Variable Layers

```
┌─────────────────────────────────────┐
│      Raw Input (rawVars)            │  User-provided
│  • name, organization, platforms    │
│  • generation_mode                  │
│  • features[], services[]           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   BaseTemplateVariables              │  Parsed & validated
│  • name: String                      │
│  • organization: String              │
│  • platforms: List<PlatformType>     │
│  • generationMode: GenerationMode    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   SharedDerivedVariables             │  Cross-cutting
│  • projectNameSnake, Camel, Pascal  │
│  • supportsIos, supportsAndroid... │
│  • flyPackages                       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   ModeSpecificVariables              │  Mode-specific
│  • ProjectVariables                  │
│  • FeatureVariables                  │
│  • ServiceVariables                  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   ComposedDerivedVariables           │  Merged
│  • shared: SharedDerivedVariables   │
│  • modeSpecific: ModeSpecificVars   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   GlobalVars                         │  Wrapper
│  • composed: ComposedDerivedVars    │
│  • base: BaseTemplateVariables      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Brick Variables                    │  Per-invocation
│  • Global vars + instance config     │
│  • Brick-specific mapping            │
└─────────────────────────────────────┘
```

## Base Template Variables

Parsed from raw input, represents the core user-provided values:

```dart
BaseTemplateVariables(
  name: 'my_app',
  organization: 'com.example',
  generationMode: GenerationMode.project,
  platforms: [PlatformType.ios, PlatformType.android],
  description: 'A new Flutter project',
  // ... more fields
)
```

## Shared Derived Variables

Computed by cross-cutting planners, common to all modes:

```dart
SharedDerivedVariables(
  projectName: 'my_app',
  projectNameSnake: 'my_app',
  projectNameCamel: 'myApp',
  projectNamePascal: 'MyApp',
  supportsIos: true,
  supportsAndroid: true,
  supportsWeb: false,
  // ... more fields
)
```

**Planners involved:**
- `NamingPlanner`: Name variants (snake, camel, pascal)
- `PlatformPlanner`: Platform flags
- `PresetPlanner`: Preset application

## Mode-Specific Variables

Computed by mode-specific planners, unique to each generation mode:

### Project Variables

```dart
ProjectVariables(
  isProject: true,
)
```

### Feature Variables

```dart
FeatureVariables(
  isFeature: true,
  screenType: ScreenType.list,
  isListScreen: true,
  withNavigation: false,
  useRiverpod: true,
  feature: 'home',
  componentName: 'home_screen',
)
```

### Service Variables

```dart
ServiceVariables(
  isService: true,
  serviceType: ServiceType.api,
  isApiService: true,
  supportsRetry: true,
  supportsInterceptors: true,
  feature: 'core',
  componentName: 'api_service',
)
```

## Composed Derived Variables

Merges shared + mode-specific:

```dart
ComposedDerivedVariables(
  shared: SharedDerivedVariables(...),
  modeSpecific: FeatureVariables(...),  // or Project/Service
)
```

Provides `toMasonVars()` to convert to a flat map.

## Global Variables

Wrapper that provides unified access:

```dart
GlobalVars(
  composed: ComposedDerivedVariables(...),
  base: BaseTemplateVariables(...),
)
```

Provides `toMasonVars()` that includes:
- All derived variables
- Base variables (name, organization, description, generation_mode)

## Brick Variables

Final variables for each brick invocation, built by the brick's `buildVars` function:

```dart
// In BrickDefinition
buildVars: (globalVars, instanceConfig) {
  final vars = globalVars.toMasonVars();  // Start with all global vars
  
  if (instanceConfig != null) {
    // Add instance-specific vars
    vars['component_name'] = instanceConfig.name;
    vars['feature'] = instanceConfig.params['feature'];
    // ...
  }
  
  return vars;
}
```

## Variable Keys

All variable keys are defined in `MasonVarKey` enum for type safety:

```dart
enum MasonVarKey {
  name('name'),
  organization('organization'),
  generationMode('generation_mode'),
  platforms('platforms'),
  // ... many more
}
```

## Variable Access

### In Planning Code

```dart
// From raw input
final name = rawVars[MasonVarKey.name.key];

// From BaseTemplateVariables
final name = base.name;

// From SharedDerivedVariables
final snakeName = shared.projectNameSnake;

// From GlobalVars
final allVars = globalVars.toMasonVars();
```

### In Brick Templates

Bricks receive a flat `Map<String, dynamic>` with all variables:

```mustache
{{name}}
{{organization}}
{{project_name_snake}}
{{supports_ios}}
{{is_feature}}
{{screen_type}}
```

## Variable Derivation Flow

### 1. Preset Application

```dart
final baseWithPreset = PresetPlanner.applyPresetToBase(base, logger);
```

Applies preset defaults to base variables.

### 2. Cross-Cutting Planners

```dart
for (final planner in _factory.getCrossCuttingPlanners()) {
  if (planner.canHandle(baseWithPreset)) {
    shared = planner.derive(baseWithPreset, shared, logger);
  }
}
```

Planners run in order:
1. `NamingPlanner`: Name variants
2. `PlatformPlanner`: Platform flags
3. `CrossCuttingPlanner`: Other shared concerns

### 3. Mode-Specific Planner

```dart
final modePlanner = _factory.getModePlanner(baseWithPreset.generationMode);
final modeSpecific = modePlanner.derive(baseWithPreset, logger);
```

Selects and runs:
- `ProjectPlanner` for `GenerationMode.project`
- `FeaturePlanner` for `GenerationMode.feature`
- `ServicePlanner` for `GenerationMode.service`

### 4. Composition

```dart
return ComposedDerivedVariables(
  shared: shared,
  modeSpecific: modeSpecific,
);
```

## Instance Configuration

For repeatable bricks, each instance has its own configuration:

```dart
InstanceConfig(
  type: 'feature',
  name: 'home',
  params: {
    'feature': 'home',
    'screen_type': 'list',
    'with_viewmodel': true,
    // ...
  },
)
```

The brick's `buildVars` receives this and merges it with global vars.

## Variable Validation

Planners validate variable combinations:

```dart
// ServicePlanner validates service type + options
if (serviceType == ServiceType.analytics && withCaching) {
  throw PlanningException('Analytics services do not support caching');
}
```

## Best Practices

1. **Use MasonVarKey**: Always use the enum, never string literals
2. **Complete Mapping**: Ensure `buildVars` provides all variables the brick needs
3. **Type Safety**: Use typed variable classes, not raw maps
4. **Validation**: Validate in planners, not in bricks
5. **Documentation**: Document which variables each brick expects

## Variable Naming Conventions

- **Snake case**: `project_name`, `with_tests`, `supports_ios`
- **Boolean flags**: `is_*`, `with_*`, `supports_*`, `has_*`
- **Type indicators**: `screen_type`, `service_type`, `state_mgmt`
- **Derived names**: `project_name_snake`, `project_name_camel`, `project_name_pascal`

