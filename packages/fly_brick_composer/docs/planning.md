# Planning Process

This document explains how the composition system transforms user input into an executable plan.

## Overview

The composition process converts raw user input (flags, manifest, prompts) into an ordered list of `BrickInvocation` objects, each ready for execution.

## Planning Pipeline

```
┌─────────────────┐
│   Raw Input     │  Map<String, dynamic>
│  (rawVars)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ComposerRequest │  Normalized request with workflow ID
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ BaseTemplate    │  Parsed base variables
│   Variables     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Composite       │  Variable derivation
│   Planner       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Composed        │  Shared + mode-specific
│   Variables     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GlobalVars      │  Wrapper for brick access
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Workflow        │  Look up workflow definition
│   Definition    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Workflow        │  Expand steps into invocations
│   Expansion     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ BrickInvocation │  Ordered, ready for execution
│      List       │
└─────────────────┘
```

## Step-by-Step Process

### 1. Input Normalization

```dart
final request = ComposerRequest.fromVars(rawVars);
```

- Parses `generation_mode` to infer `WorkflowId`
- Validates workflow ID exists
- Creates normalized `ComposerRequest`

### 2. Base Variable Parsing

```dart
final base = BaseTemplateVariables.fromVars(request.raw);
```

Extracts:
- Project name, organization, description
- Platforms, preset
- Generation mode
- Feature/service flags

### 3. Variable Derivation

```dart
final composed = _planner.run(base, _logger);
```

The `CompositePlanner` delegates to `VariableDerivationPipeline`:
1. **Preprocessing**: Applies preset (if specified) to base variables
2. **Shared Derivation Steps**: Runs shared derivation steps in order:
   - Naming step: Derives name variants (snake, camel, pascal)
   - Preset shared step: Applies preset-based configuration (flyPackages)
   - Platform step: Computes platform support flags
3. **Mode-Specific Derivation**: Runs mode-specific function (project/feature/service)
4. **Composition**: Merges shared + mode-specific variables into `ComposedDerivedVariables`

### 4. Global Variables Wrapper

```dart
final globalVars = GlobalVars(composed: composed, base: base);
```

Provides unified access to:
- All derived variables (`composed.toMasonVars()`)
- Base variables (name, organization, etc.)

### 5. Workflow Lookup

```dart
final workflow = _workflowRegistry.getById(request.workflowId);
```

Retrieves the workflow definition for the requested workflow.

### 6. Workflow Expansion

For each step in the workflow:

#### Single Steps

```dart
// Create one invocation
final vars = brickDef.buildVars(globalVars, null);
final invocation = BrickInvocation(
  brickId: step.brickId,
  phase: step.defaultPhase,
  vars: vars,
  // ...
);
```

#### Repeatable Steps

```dart
// Look up instances
final instances = request.raw[step.selectionKey] as List;

// Create one invocation per instance
for (final instanceRaw in instances) {
  final instanceConfig = InstanceConfig.fromMap(instanceRaw);
  final vars = brickDef.buildVars(globalVars, instanceConfig);
  final invocation = BrickInvocation(/* ... */);
}
```

### 7. Sorting

```dart
brickInvocations.sort((a, b) {
  final phaseCompare = a.phase.compareTo(b.phase);
  if (phaseCompare != 0) return phaseCompare;
  return a.displayName.compareTo(b.displayName);
});
```

Ensures deterministic execution order:
1. By phase (0, 1, 2, ...)
2. By displayName within phase

## Planning Result

The planner returns a `ComposerResult`:

```dart
ComposerResult(
  derivedVars: globalVars.toMasonVars(),  // All derived variables
  brickInvocations: [...],                // New model
  moduleInvocations: [...],               // Legacy compatibility
)
```

## Standalone Generation

For standalone feature/service generation, the planner creates an `InstanceConfig` from rawVars:

```dart
// For feature-only workflow
if (step.brickId == 'feature') {
  instanceConfig = InstanceConfig(
    type: 'feature',
    name: raw['name'],
    params: {
      'feature': raw['feature'],
      'screen_type': raw['screen_type'],
      // ...
    },
  );
}
```

This allows the brick's `buildVars` to extract instance-specific variables.

## Variable Flow

```
Raw Input
  ↓
BaseTemplateVariables (parsed)
  ↓
SharedDerivedVariables (cross-cutting)
  ↓
ModeSpecificVariables (mode-specific)
  ↓
ComposedDerivedVariables (merged)
  ↓
GlobalVars (wrapped)
  ↓
Brick Variables (per invocation)
```

## Error Handling

The planner validates at multiple points:

1. **Workflow ID**: Throws if workflow not found
2. **Brick ID**: Validates all referenced bricks exist
3. **Variable Derivation**: Planners validate combinations
4. **Instance Config**: Validates required fields

All errors are `ComposerException` with descriptive messages.

## Example: Foundation Project

### Input

```dart
{
  'name': 'my_app',
  'organization': 'com.example',
  'generation_mode': 'project',
  'platforms': ['ios', 'android'],
  'features': [
    {'name': 'home', 'type': 'feature', 'params': {...}},
    {'name': 'profile', 'type': 'feature', 'params': {...}},
  ],
  'services': [
    {'name': 'api', 'type': 'service', 'params': {...}},
  ],
}
```

### Planning Result

```dart
ComposerResult(
  brickInvocations: [
    // Phase 0: Project
    BrickInvocation(
      brickId: 'project',
      phase: 0,
      displayName: 'project',
      vars: {...},  // All project vars
    ),
    
    // Phase 1: Features
    BrickInvocation(
      brickId: 'feature',
      phase: 1,
      displayName: 'feature:home:home',
      vars: {...},  // Global + feature-specific
      targetDir: 'lib/features/home',
    ),
    BrickInvocation(
      brickId: 'feature',
      phase: 1,
      displayName: 'feature:profile:profile',
      vars: {...},
      targetDir: 'lib/features/profile',
    ),
    
    // Phase 2: Services
    BrickInvocation(
      brickId: 'service',
      phase: 2,
      displayName: 'service:api:api',
      vars: {...},  // Global + service-specific
      targetDir: 'lib/services/core',
    ),
  ],
)
```

## Performance Considerations

- **Caching**: Variable derivation results could be cached (future)
- **Lazy Evaluation**: Instance configs are created only when needed
- **Determinism**: Sorting ensures consistent output for same input

## Testing

The composition process is fully testable:

```dart
test('compose project with features', () {
  final composer = BrickComposer();
  final result = composer.composeBricks({
    'name': 'test',
    'generation_mode': 'project',
    'features': [...],
  });
  
  expect(result.brickInvocations.length, greaterThan(1));
  expect(result.brickInvocations.first.phase, 0);
});
```

