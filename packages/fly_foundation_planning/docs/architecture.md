# Architecture Overview

This document describes the high-level architecture of the Fly Foundation Planning system.

## System Design

The planning system follows a **workflow-driven, brick-based architecture** that separates concerns into distinct layers:

```
┌─────────────────────────────────────────────────────────┐
│                    CLI / User Input                      │
│  (flags, manifest, interactive prompts)                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Planning Request Layer                      │
│  • Normalizes input (PlanningRequest)                    │
│  • Infers workflow ID from generation mode              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Foundation Planner                          │
│  • Variable derivation (CompositePlanner)              │
│  • Workflow expansion (WorkflowRegistry)                │
│  • Brick invocation creation                            │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Planning Result                             │
│  • Ordered list of BrickInvocations                     │
│  • Derived variables                                    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Foundation Orchestrator                     │
│  • Phase-based execution                                │
│  • Per-invocation target directories                    │
│  • Brick generation via Mason                           │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Brick Registry (`BrickRegistry`)

The central registry of all available bricks. Each brick is defined with:

- **Identity**: Unique ID (e.g., `fly_foundation_project`)
- **Kind**: Category (projectTemplate, featureComponent, serviceComponent, etc.)
- **Dependencies**: Other bricks this brick depends on
- **Variable Builder**: Function to map global vars + instance config → brick vars
- **Target Directory Resolver**: Optional function to compute output path

**Key Design**: Bricks are completely independent. They don't know about each other; dependencies are metadata only.

### 2. Workflow Registry (`WorkflowRegistry`)

Defines how bricks are composed together. A workflow consists of:

- **Steps**: Ordered list of workflow steps
- **Repeatability**: Whether a step can be executed multiple times
- **Selection Key**: Where to find instance data in raw input

**Key Design**: Workflows are declarative data structures. Adding a new workflow doesn't require code changes to the planner.

### 3. Planning Engine (`FoundationPlanner`)

Orchestrates the planning process:

1. **Input Normalization**: Converts raw input → `PlanningRequest`
2. **Variable Derivation**: Runs `CompositePlanner` to compute global variables
3. **Workflow Expansion**: Expands workflow steps into `BrickInvocation` objects
4. **Ordering**: Sorts invocations by phase and display name

**Key Design**: The planner is workflow-agnostic. It doesn't hard-code brick relationships.

### 4. Variable System

Multi-layered variable derivation:

- **Base Variables**: Raw input (name, organization, platforms, etc.)
- **Shared Variables**: Common across all modes (naming variants, platform flags)
- **Mode-Specific Variables**: Unique to project/feature/service modes
- **Composed Variables**: Merged shared + mode-specific
- **Global Variables**: Wrapper around composed + base for brick access
- **Brick Variables**: Final vars for each brick (global + instance-specific)

**Key Design**: Variables flow from global → brick-specific, with each brick receiving only what it needs.

## Data Flow

### Planning Phase

```
Raw Input (Map<String, dynamic>)
    ↓
PlanningRequest (normalized)
    ↓
BaseTemplateVariables (parsed)
    ↓
ComposedDerivedVariables (derived)
    ↓
GlobalVars (wrapped)
    ↓
WorkflowDefinition (looked up)
    ↓
BrickInvocation[] (expanded)
    ↓
PlanningResult (sorted, ready for execution)
```

### Execution Phase

```
PlanningResult.brickInvocations
    ↓
Grouped by phase
    ↓
Sorted within phase
    ↓
For each invocation:
    - Resolve brick definition
    - Resolve target directory
    - Build Mason vars
    - Execute brick generation
```

## Extension Points

The architecture provides several extension points:

1. **New Bricks**: Register in `BrickRegistry` with variable builder
2. **New Workflows**: Define in `WorkflowRegistry` with step definitions
3. **New Variable Planners**: Add to `CompositePlanner` via `PlannerFactory`
4. **New Instance Config Types**: Extend `InstanceConfig` with typed helpers

## Design Principles

1. **Separation of Concerns**: Planning vs. execution, bricks vs. workflows
2. **Composition over Inheritance**: Workflows compose bricks, don't extend them
3. **Data-Driven**: Workflows and brick metadata are data, not code
4. **Type Safety**: Strong typing throughout, with clear contracts
5. **Extensibility**: Add new capabilities without modifying core logic
6. **Determinism**: Same input always produces same output (sorted, predictable)

## Benefits

- **Flexibility**: Mix and match bricks in any combination
- **Maintainability**: Clear separation makes changes localized
- **Testability**: Each component can be tested independently
- **Scalability**: Easy to add new bricks and workflows
- **Clarity**: Declarative workflows are easier to understand than imperative code

