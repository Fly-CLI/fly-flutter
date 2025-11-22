# Variable System

The composition system uses a multi-layered variable derivation approach to compute the correct variables for each brick.

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

**Derivation steps involved:**
- **Naming step**: Name variants (snake, camel, pascal) - derived in `VariableDerivationPipeline`
- **Platform step**: Platform flags - computed from base.platforms
- **Preset shared step**: Preset-based configuration (flyPackages) - applied from active preset

## Mode-Specific Variables

Computed by mode-specific derivation functions in `VariableDerivationPipeline`, unique to each generation mode:

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

The variable derivation uses `VariableDerivationPipeline`, which runs steps in a declarative sequence:

### 1. Preprocessing

```dart
final baseWithPreset = pipeline.preprocessor(base, logger);
```

Applies preset defaults to base variables (if a preset is specified).

### 2. Shared Derivation Steps

```dart
for (final step in pipeline.sharedSteps) {
  if (step.predicate(baseWithPreset)) {
    shared = step.derive(baseWithPreset, shared, logger);
  }
}
```

Steps run in order:
1. **Naming step**: Derives name variants (snake, camel, pascal case)
2. **Preset shared step**: Applies preset-based configuration (flyPackages)
3. **Platform step**: Computes platform support flags from base.platforms

### 3. Mode-Specific Derivation

```dart
final modeFn = pipeline.modeFunctions[baseWithPreset.generationMode];
final modeSpecific = modeFn(baseWithPreset, logger);
```

Selects and runs the mode-specific function:
- Project derivation for `GenerationMode.project`
- Feature derivation for `GenerationMode.feature`
- Service derivation for `GenerationMode.service`

### 4. Composition

```dart
return ComposedDerivedVariables(
  shared: shared,
  modeSpecific: modeSpecific,
);
```

### Extending the Pipeline

To add new shared derivation steps:

```dart
final customPipeline = VariableDerivationPipeline(
  preprocessor: _defaultPreprocessor,
  sharedSteps: [
    ..._defaultSharedSteps,
    SharedDerivationStep(
      id: 'custom_step',
      predicate: (base) => base.someCondition,
      derive: _customDerivation,
    ),
  ],
  modeFunctions: _defaultModeFunctions,
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

Derivation functions validate variable combinations:

```dart
// Service derivation validates service type + options
if (serviceType == ServiceType.analytics && withCaching) {
  throw ComposerException('Analytics services do not support caching');
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

