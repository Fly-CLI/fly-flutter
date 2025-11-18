# fly_foundation_planning

Shared planning library for Fly foundation template generation.

## Overview

This library provides planning and variable derivation logic for the Fly foundation template generation system. It is a pure Dart library with no Mason-specific dependencies, making it reusable across different tools and integrations.

## Features

- **Variable Derivation**: Converts raw user input into derived variables for template rendering
- **Module Selection**: Determines which module bricks should be executed based on generation mode
- **Preset Support**: Applies preset configurations (starter, batteries_included, minimal)
- **Mode Support**: Handles project, feature, and service generation modes
- **Validation**: Validates variable combinations and throws clear errors for invalid inputs

## Usage

```dart
import 'package:fly_foundation_planning/fly_foundation_planning.dart';

final planner = FoundationPlanner();
final result = planner.planFoundationGeneration({
  'name': 'my_project',
  'organization': 'com.example',
  'generation_mode': 'project',
  'platforms': ['ios', 'android'],
  'preset': 'starter',
});

// Get which bricks to run
for (final invocation in result.moduleInvocations) {
  print('Run brick: ${invocation.brickId}');
  print('Variables: ${invocation.vars}');
}

// Get all derived variables
final derivedVars = result.derivedVars;
```

## Architecture

### Core Components

- **FoundationPlanner**: Main entry point for planning generation
- **CompositePlanner**: Orchestrates variable derivation using multiple planners
- **PlannerFactory**: Manages mode-specific and cross-cutting planners
- **ModuleInvocation**: Represents a brick that should be executed

### Planners

- **Mode-Specific Planners**: ProjectPlanner, FeaturePlanner, ServicePlanner
- **Cross-Cutting Planners**: NamingPlanner, PresetPlanner, PlatformPlanner

### Variables

- **BaseTemplateVariables**: Raw input variables
- **ComposedDerivedVariables**: Final derived variables (shared + mode-specific)
- **SharedDerivedVariables**: Variables common to all modes
- **ModeSpecificVariables**: Variables specific to project/feature/service

## Integration

This library is used by:

- **Fly CLI**: For orchestrating foundation generation
- **Future Tools**: Can be integrated into other tools that need to plan Fly foundation generation

## License

See the main Fly repository for license information.

