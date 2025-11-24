# Fly Brick Composer

A flexible, extensible composition system for orchestrating multi-brick Flutter project generation.

## Overview

The Fly Brick Composer library provides a powerful workflow engine that enables composable brick-based project generation. Instead of hard-coding brick relationships, this system uses declarative workflow definitions to orchestrate multiple independent bricks in a single generation process.

## Key Concepts

- **Bricks**: Independent, reusable code generation units (e.g., `project`, `feature`, `service`)
- **Workflows**: Declarative definitions that describe how to compose bricks together
- **Composition**: The process of expanding a workflow into an ordered list of brick invocations
- **Orchestration**: The execution of composed brick invocations with proper ordering and variable propagation

## Quick Start

```dart
import 'package:fly_brick_composer/fly_brick_composer.dart';

// Create a composer
final composer = BrickComposer();

// Compose a project with features and services
final rawVars = {
  'name': 'my_app',
  'organization': 'com.example',
  'platforms': ['ios', 'android'],
  'generation_mode': 'project',
  'features': [
    {
      'name': 'home',
      'type': 'feature',
      'params': {
        'feature': 'home',
        'screen_type': 'list',
        'with_viewmodel': true,
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
        'with_tests': true,
      },
    },
  ],
};

final result = composer.composeBricks(rawVars, workflowId);

// Execute the composed invocations using the orchestrator
// Note: In CLI, use the BrickOrchestrator wrapper that implements
// BrickExecutor using TemplateManager and Mason
final orchestrator = BrickOrchestrator<String>(
  executor: myBrickExecutor,  // Implement BrickExecutor for your context
  logger: myLogger,
  composer: composer,
);

final orchestrationResult = await orchestrator.generate(
  rawVars: rawVars,
  workflowId: workflowId,
  outputDirectory: './output',
);
```

## Architecture

The composition system consists of several key components:

1. **[Brick Registry](docs/brick-registry.md)**: Manages brick definitions and metadata
2. **[Workflow Definitions](docs/workflows.md)**: Declares how bricks are composed
3. **[Composition Engine](docs/planning.md)**: Expands workflows into execution plans
4. **[Variable Derivation](docs/variables.md)**: Computes variables for each brick using unified pipeline
5. **[Orchestration](docs/architecture.md)**: Executes composed brick invocations with phase-based ordering

## Documentation

- [Architecture Overview](docs/architecture.md) - High-level system design
- [Brick Registry](docs/brick-registry.md) - How bricks are defined and registered
- [Workflows](docs/workflows.md) - Creating and using workflow definitions
- [Composition Process](docs/planning.md) - How composition works internally
- [Variable System](docs/variables.md) - Variable derivation and propagation
- [Extending the System](docs/extending.md) - Adding new bricks and workflows
- [Examples](docs/examples.md) - Practical usage examples

## Features

- **Composable**: Mix and match bricks in any combination
- **Extensible**: Add new bricks without modifying core logic
- **Declarative**: Define workflows as data, not code
- **Type-Safe**: Strong typing throughout the composition pipeline
- **Flexible**: Support for single-brick and multi-brick workflows
- **Ordered**: Automatic phase-based execution ordering

## Usage Patterns

### Single Brick Generation

```dart
// Generate a single feature
final result = composer.composeBricks({
  'name': 'home_screen',
  'generation_mode': 'feature',
  'feature': 'home',
  'screen_type': 'list',
}, workflowId);
```

### Multi-Brick Project Generation

```dart
// Generate project with multiple features and services
final result = composer.composeBricks({
  'name': 'my_app',
  'generation_mode': 'project',
  'features': [/* ... */],
  'services': [/* ... */],
}, workflowId);
```

## Contributing

When adding new bricks or workflows:

1. Register the brick in `BrickRegistry`
2. Define a workflow (if needed) in `WorkflowRegistry`
3. Implement brick-specific variable mapping
4. Add tests for the new functionality

See [Extending the System](docs/extending.md) for detailed instructions.

## License

See the main project LICENSE file.
