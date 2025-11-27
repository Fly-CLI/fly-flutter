# Generation Mode Strategies

This directory contains the Strategy pattern implementation for generation modes, serving as the **single source of truth** for all generation mode implementations.

## Architecture

The strategy pattern encapsulates mode-specific generation logic, ensuring:

- **Extensibility**: New modes are added by implementing the interface and registering in the registry
- **Readability**: All mode-specific logic is centralized and discoverable through the strategy interface
- **Maintainability**: Changes to generation behavior are isolated to their respective strategy implementations
- **Robustness**: Type safety and consistent contracts across all generation modes

## Core Components

### `GenerationModeStrategy<T>`

Abstract interface that all generation mode strategies must implement:

```dart
abstract class GenerationModeStrategy<T extends GenerationRequestDto> {
  /// The generation mode this strategy handles
  GenerationMode get mode;
  
  /// Execute generation for this mode
  Future<GenerationResultDto> execute(T request);
  
  /// Get next steps for successful generation
  List<NextStep> getNextSteps(GenerationResultDto result);
}
```

### `GenerationModeRegistry`

Central registry that maps `GenerationMode` enum values to their corresponding strategy implementations. This registry serves as the authoritative mapping and must be used for all generation execution.

**Key methods:**
- `execute(GenerationRequestDto request)` - Execute generation using the appropriate strategy
- `getStrategy(GenerationMode mode)` - Get strategy for a mode (throws if not found)
- `forMode(GenerationMode mode)` - Get strategy for a mode (returns null if not found)
- `isRegistered(GenerationMode mode)` - Check if a mode is registered
- `registeredModes` - Get all registered modes

## Adding a New Generation Mode

To add a new generation mode, follow these steps:

### 1. Add Enum Value

Add the new mode to the `GenerationMode` enum in `fly_brick_composer`:

```dart
enum GenerationMode {
  project,
  feature,
  service,
  yourNewMode, // Add here
}
```

### 2. Create Request DTO

Create a new request DTO class extending `GenerationRequestDto`:

```dart
final class YourNewModeGenerationRequest extends GenerationRequestDto {
  const YourNewModeGenerationRequest({
    required this.name,
    required super.outputDirectory,
    // ... other fields
    super.dryRun = false,
  });

  final String name;
  // ... other fields

  @override
  GenerationMode get mode => GenerationMode.yourNewMode;

  @override
  Map<String, dynamic> toJson() {
    // ... implementation
  }
}
```

### 3. Create Use Case

Create a use case for the new mode (if needed):

```dart
class GenerateYourNewModeUseCase {
  GenerateYourNewModeUseCase({
    required IWorkflowOrchestrator workflowOrchestrator,
  }) : _workflowOrchestrator = workflowOrchestrator;

  final IWorkflowOrchestrator _workflowOrchestrator;

  Future<GenerationResultDto> execute(YourNewModeGenerationRequest request) async {
    // ... implementation
  }
}
```

### 4. Implement Strategy

Create a new strategy class in this directory:

```dart
class YourNewModeGenerationModeStrategy
    implements GenerationModeStrategy<YourNewModeGenerationRequest> {
  YourNewModeGenerationModeStrategy({
    required GenerateYourNewModeUseCase useCase,
  }) : _useCase = useCase;

  final GenerateYourNewModeUseCase _useCase;

  @override
  GenerationMode get mode => GenerationMode.yourNewMode;

  @override
  Future<GenerationResultDto> execute(YourNewModeGenerationRequest request) {
    return _useCase.execute(request);
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    return [
      const NextStep(
        command: 'your-command',
        description: 'Description of next step',
      ),
    ];
  }
}
```

### 5. Register in DI Container

In `ServiceBootstrapper` (`lib/src/cli/application/bootstrapping/service_bootstrapper.dart`):

1. Register the use case (if created):
```dart
..registerSingleton<GenerateYourNewModeUseCase>(
  GenerateYourNewModeUseCase(
    workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
  ),
)
```

2. Register the strategy:
```dart
final yourNewModeStrategy = YourNewModeGenerationModeStrategy(
  useCase: container.get<GenerateYourNewModeUseCase>(),
);
container
  ..registerSingleton<YourNewModeGenerationModeStrategy>(yourNewModeStrategy)
```

3. Add to the registry:
```dart
..registerSingleton<GenerationModeRegistry>(
  GenerationModeRegistry({
    GenerationMode.feature: featureStrategy,
    GenerationMode.service: serviceStrategy,
    GenerationMode.project: projectStrategy,
    GenerationMode.yourNewMode: yourNewModeStrategy, // Add here
  }),
)
```

### 6. Create Command (Optional)

If you want a CLI command for the new mode, create a command class similar to `GenerateFeatureCommand`.

## Important Rules

1. **All generation modes must be registered in `GenerationModeRegistry`** - This is the single source of truth
2. **No mode-specific generation logic outside strategies** - All generation behavior should be in strategy implementations
3. **Use the registry for execution** - Always route generation requests through `GenerationModeRegistry.execute()`
4. **Type safety** - Each strategy should use a specific request type (`GenerationModeStrategy<T>`)

## Testing

When adding a new mode, ensure:

1. The strategy is registered in the registry
2. The registry's `execute()` method correctly routes requests to your strategy
3. The strategy's `getNextSteps()` returns appropriate suggestions
4. All CLI-used `GenerationMode` values are represented in the registry

## Current Strategies

- `FeatureGenerationModeStrategy` - Handles feature/screen generation
- `ServiceGenerationModeStrategy` - Handles service generation
- `ProjectGenerationModeStrategy` - Handles project generation

