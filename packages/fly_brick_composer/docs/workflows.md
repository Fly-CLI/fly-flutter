# Workflows

Workflows are declarative definitions that describe how to compose multiple bricks together in a single generation process.

## Overview

A workflow defines:
- Which bricks to execute
- In what order (via phases)
- Whether steps are repeatable
- Where to find instance data

## Workflow ID

Workflows are identified by a `WorkflowId` enum:

```dart
enum WorkflowId {
  foundationProject('foundation_project'),  // Project + features + services
  featureOnly('feature_only'),              // Single feature
  serviceOnly('service_only'),              // Single service
}
```

## Workflow Definition

A `WorkflowDefinition` consists of an ID and a list of steps:

```dart
WorkflowDefinition(
  id: WorkflowId.foundationProject,
  steps: [
    WorkflowStep(
      id: 'project',
      brickId: 'project',
      defaultPhase: 0,
      repeatable: false,
    ),
    WorkflowStep(
      id: 'features',
      brickId: 'feature',
      defaultPhase: 1,
      repeatable: true,
      selectionKey: 'features',
    ),
    // ...
  ],
)
```

## Workflow Steps

Each step defines:

- **`id`**: Unique identifier within the workflow
- **`brickId`**: Which brick to use
- **`defaultPhase`**: Execution phase (lower numbers run first)
- **`repeatable`**: Whether this step can run multiple times
- **`selectionKey`**: Key in raw input to find instances (for repeatable steps)

## Step Types

### Single Steps

Non-repeatable steps execute exactly once:

```dart
WorkflowStep(
  id: 'project',
  brickId: 'project',
  defaultPhase: 0,
  repeatable: false,
)
```

For single steps, the brick's `buildVars` receives `instanceConfig: null`.

### Repeatable Steps

Repeatable steps can execute zero or more times based on input:

```dart
WorkflowStep(
  id: 'features',
  brickId: 'feature',
  defaultPhase: 1,
  repeatable: true,
  selectionKey: 'features',  // Look in rawVars['features']
)
```

For repeatable steps:
- The planner looks up `rawVars[selectionKey]` (must be a `List`)
- Creates one `BrickInvocation` per item in the list
- Each invocation gets an `InstanceConfig` built from the list item

## Execution Phases

Phases control execution order:

- **Phase 0**: Project template (runs first)
- **Phase 1**: Features (runs after project)
- **Phase 2**: Services (runs after features)

Within a phase, invocations are sorted by `displayName` for determinism.

## Default Workflows

### Foundation Project Workflow

Generates a project with optional features and services:

```dart
WorkflowDefinition(
  id: WorkflowId.foundationProject,
  steps: [
    // Phase 0: Project template (required, single)
    WorkflowStep(id: 'project', brickId: 'project', ...),
    
    // Phase 1: Features (optional, repeatable)
    WorkflowStep(id: 'features', brickId: 'feature', ...),
    
    // Phase 2: Services (optional, repeatable)
    WorkflowStep(id: 'services', brickId: 'service', ...),
  ],
)
```

### Feature-Only Workflow

Generates a single feature (standalone):

```dart
WorkflowDefinition(
  id: WorkflowId.featureOnly,
  steps: [
    WorkflowStep(id: 'feature', brickId: 'feature', ...),
  ],
)
```

### Service-Only Workflow

Generates a single service (standalone):

```dart
WorkflowDefinition(
  id: WorkflowId.serviceOnly,
  steps: [
    WorkflowStep(id: 'service', brickId: 'service', ...),
  ],
)
```

## Input Format

### Foundation Project

```dart
{
  'name': 'my_app',
  'organization': 'com.example',
  'generation_mode': 'project',
  'features': [
    {
      'name': 'home',
      'type': 'feature',
      'params': {
        'feature': 'home',
        'screen_type': 'list',
        // ...
      },
    },
  ],
  'services': [
    {
      'name': 'api',
      'type': 'service',
      'params': {
        'feature': 'core',
        'service_type': 'api',
        // ...
      },
    },
  ],
}
```

### Feature-Only

```dart
{
  'name': 'home_screen',
  'generation_mode': 'feature',
  'feature': 'home',
  'screen_type': 'list',
  'with_viewmodel': true,
  // ...
}
```

## Workflow Registry

The `WorkflowRegistry` manages all workflow definitions:

```dart
final registry = WorkflowRegistry.defaultRegistry(brickRegistry);

// Get a workflow
final workflow = registry.getById(WorkflowId.foundationProject);

// Validate workflow ID exists
registry.validateWorkflowId(WorkflowId.foundationProject);
```

## Workflow Inference

The planner automatically infers the workflow from `generation_mode`:

- `generation_mode: 'project'` → `WorkflowId.foundationProject`
- `generation_mode: 'feature'` → `WorkflowId.featureOnly`
- `generation_mode: 'service'` → `WorkflowId.serviceOnly`

You can also explicitly specify a workflow ID in `ComposerRequest`.

## Creating New Workflows

See [Extending the System](extending.md) for instructions on creating custom workflows.

## Best Practices

1. **Clear Phase Ordering**: Use phases to express dependencies (project before features)
2. **Descriptive Step IDs**: Use clear, unique step IDs
3. **Consistent Selection Keys**: Use the same keys in raw input and workflow definitions
4. **Validate Early**: Register workflows with brick registry validation
5. **Document Dependencies**: Use phases to document execution order

## Execution Flow

1. Planner looks up workflow by ID
2. For each step:
   - If repeatable: Look up instances from `selectionKey`
   - If single: Execute once
3. Create `BrickInvocation` for each execution
4. Sort all invocations by phase, then displayName
5. Return `ComposerResult` with ordered invocations

