# Architecture Overview

This document describes the high-level architecture of the Fly Foundation Planning system.

## System Design

The composition system follows a **workflow-driven, brick-based architecture** that separates concerns into distinct layers:

```
┌─────────────────────────────────────────────────────────┐
│                    CLI / User Input                      │
│  (flags, manifest, interactive prompts)                  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Planning Request Layer                      │
│  • Normalizes input (ComposerRequest)                    │
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
│          Foundation Orchestrator                         │
│    (in fly_brick_composer)                          │
│  • Phase-based execution                                │
│  • Per-invocation target directories                    │
│  • Uses BrickExecutor abstraction                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│          CLI Executor Adapter                            │
│  • Implements BrickExecutor for CLI                     │
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

### 3. Planning Engine (`BrickComposer`)

Orchestrates the composition process:

1. **Input Normalization**: Converts raw input → `ComposerRequest`
2. **Variable Derivation**: Runs `CompositePlanner` (which uses `VariableDerivationPipeline`) to compute global variables
3. **Workflow Expansion**: Expands workflow steps into `BrickInvocation` objects
4. **Ordering**: Sorts invocations by phase and display name

**Key Design**: The planner is workflow-agnostic. It doesn't hard-code brick relationships.

### 4. Orchestration Engine (`BrickOrchestrator`)

Executes planned brick invocations:

1. **Planning**: Uses `BrickComposer` to plan brick invocations
2. **Phase Grouping**: Groups invocations by phase for ordered execution
3. **Brick Execution**: Uses `BrickExecutor` abstraction to execute each brick
4. **Result Aggregation**: Collects results from all brick executions

**Key Design**: The orchestrator is generic and CLI-agnostic. It uses the `BrickExecutor<TFile>` interface, allowing different hosts (CLI, tests, etc.) to provide their own execution implementation.

### 5. Variable System

Multi-layered variable derivation using a unified pipeline:

- **Base Variables**: Raw input (name, organization, platforms, etc.)
- **Shared Variables**: Common across all modes (naming variants, platform flags)
- **Mode-Specific Variables**: Unique to project/feature/service modes
- **Composed Variables**: Merged shared + mode-specific
- **Global Variables**: Wrapper around composed + base for brick access
- **Brick Variables**: Final vars for each brick (global + instance-specific)

**Key Design**: The variable derivation pipeline (`VariableDerivationPipeline`) uses declarative steps configured as data rather than multiple planner classes. Variables flow from global → brick-specific, with each brick receiving only what it needs.

## Data Flow

### Planning Phase

```
Raw Input (Map<String, dynamic>)
    ↓
ComposerRequest (normalized)
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
ComposerResult (sorted, ready for execution)
```

### Execution Phase

```
ComposerResult.brickInvocations
    ↓
BrickOrchestrator (in composition package)
    ↓
Grouped by phase
    ↓
Sorted within phase
    ↓
For each invocation:
    - Resolve target directory
    - Call BrickExecutor.executeBrick()
        ↓
    CLI Executor Adapter (implements BrickExecutor)
        ↓
    - Resolve brick definition (via TemplateManager)
    - Build Mason vars
    - Execute brick generation (via Mason)
```

## Extension Points

The architecture provides several extension points:

1. **New Bricks**: Register in `BrickRegistry` with variable builder
2. **New Workflows**: Define in `WorkflowRegistry` with step definitions
3. **New Variable Derivation Steps**: Add `SharedDerivationStep` to `VariableDerivationPipeline` or create custom pipeline
4. **New Instance Config Types**: Extend `InstanceConfig` with typed helpers
5. **Custom Brick Executors**: Implement `BrickExecutor<TFile>` for different execution contexts (CLI, tests, etc.)

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

