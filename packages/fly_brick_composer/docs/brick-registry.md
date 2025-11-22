# Brick Registry

The brick registry is the central catalog of all available code generation bricks in the Fly Foundation system.

## Overview

Every brick that can be used in a workflow must be registered in the `BrickRegistry`. The registry provides:

- Brick lookup by ID or kind
- Validation of brick references
- Metadata about brick capabilities and dependencies

## Brick Definition

A `BrickDefinition` describes a brick's identity, behavior, and requirements:

```dart
BrickDefinition(
  id: 'fly_foundation_project',
  kind: BrickKind.projectTemplate,
  dependencies: [],
  buildVars: (globalVars, instanceConfig) {
    // Map global vars + instance config → brick-specific vars
    return {...};
  },
  resolveTargetDir: (globalVars, instanceConfig) {
    // Optional: compute target directory
    return 'lib/project';
  },
)
```

### Fields

- **`id`** (String): Unique identifier for the brick (e.g., `fly_foundation_project`)
- **`kind`** (BrickKind): Category of brick (projectTemplate, featureComponent, etc.)
- **`requiredCapabilities`** (List<String>): Capabilities this brick requires (future use)
- **`dependencies`** (List<String>): Brick IDs this brick depends on (metadata only)
- **`buildVars`** (Function): Maps `GlobalVars` + `InstanceConfig?` → `Map<String, dynamic>`
- **`resolveTargetDir`** (Function?): Optional function to compute target directory

## Brick Kinds

```dart
enum BrickKind {
  projectTemplate,    // Base project structure (e.g., fly_foundation_project)
  featureComponent,   // Feature/screen components (e.g., fly_foundation_feature)
  serviceComponent,   // Service components (e.g., fly_foundation_service)
  utility,            // Utility bricks (tooling, scripts)
  custom,             // Custom/unknown types
}
```

## Variable Building

The `buildVars` function receives:

1. **`GlobalVars`**: Contains:
   - `composed`: Shared + mode-specific derived variables
   - `base`: Base template variables (name, organization, etc.)
   - Helper method `toMasonVars()` to get full var map

2. **`InstanceConfig?`**: Per-instance configuration (null for single-step bricks)

It should return a `Map<String, dynamic>` with all variables the brick needs.

### Example: Feature Brick

```dart
buildVars: (globalVars, instanceConfig) {
  final vars = globalVars.toMasonVars();
  
  if (instanceConfig != null) {
    final featureConfig = FeatureInstanceConfig.fromInstanceConfig(instanceConfig);
    vars['component_name'] = featureConfig.name;
    vars['feature'] = featureConfig.featureKey;
    vars['screen_type'] = featureConfig.screenType?.key;
    // ... more feature-specific vars
  }
  
  return vars;
}
```

## Target Directory Resolution

The `resolveTargetDir` function (optional) computes where the brick should write its output, relative to the root output directory.

### Example: Feature Brick

```dart
resolveTargetDir: (globalVars, instanceConfig) {
  if (instanceConfig != null) {
    final featureConfig = FeatureInstanceConfig.fromInstanceConfig(instanceConfig);
    return 'lib/features/${featureConfig.featureKey}';
  }
  return null; // Use root directory
}
```

## Instance Configuration

For repeatable bricks (features, services), each instance needs configuration:

### Feature Instance Config

```dart
FeatureInstanceConfig(
  name: 'home',
  featureKey: 'home',
  screenType: ScreenType.list,
  withViewModel: true,
  withTests: true,
  withValidation: false,
  withNavigation: false,
)
```

### Service Instance Config

```dart
ServiceInstanceConfig(
  name: 'api',
  featureKey: 'core',
  serviceType: ServiceType.api,
  withTests: true,
  withMocks: false,
  withInterceptors: true,
  withRetryLogic: true,
  withCaching: false,
  baseUrl: 'https://api.example.com',
)
```

## Default Registry

The `BrickRegistry.defaultRegistry()` factory creates a registry with all bricks pre-registered:

- `fly_foundation_project` (projectTemplate)
- `fly_foundation_feature` (featureComponent)
- `fly_foundation_service` (serviceComponent)

## Using the Registry

```dart
// Get default registry
final registry = BrickRegistry.defaultRegistry();

// Look up a brick
final brick = registry.getById('fly_foundation_project');

// Get all bricks of a kind
final featureBricks = registry.getByKind(BrickKind.featureComponent);

// Validate a brick exists
registry.validateBrickId('fly_foundation_project'); // Throws if not found
```

## Adding New Bricks

See [Extending the System](extending.md) for detailed instructions on registering new bricks.

## Dependencies

Dependencies are **metadata only**. They don't enforce execution order or guarantee that dependent bricks have run. The workflow definition controls execution order.

However, dependencies are useful for:
- Documentation (understanding brick relationships)
- Future validation (could check that dependencies exist)
- Tooling (IDE support, dependency graphs)

## Best Practices

1. **Unique IDs**: Use descriptive, unique brick IDs (e.g., `fly_foundation_project`, not `project`)
2. **Complete Variable Mapping**: Ensure `buildVars` provides all variables the brick template needs
3. **Consistent Naming**: Use the same variable keys as defined in `MasonVarKey`
4. **Optional Target Dir**: Only provide `resolveTargetDir` if the brick needs a specific output location
5. **Type Safety**: Use typed instance config helpers (`FeatureInstanceConfig`, `ServiceInstanceConfig`)

