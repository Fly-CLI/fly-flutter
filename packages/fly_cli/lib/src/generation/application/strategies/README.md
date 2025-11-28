# Generation Mode Strategies

This directory contains the Strategy pattern implementation for generation modes, serving as the *
*single source of truth** for all generation mode implementations.

## Architecture

The generation mode system uses a **Mode Profile** pattern that centralizes all mode-specific wiring
in one place. Each `GenerationModeProfile` contains:

- The generation mode enum value
- The brick/template identifier
- The variable processor for that mode
- The generation mode strategy

This ensures:

- **Single source of truth**: All mode-specific components are defined in one profile entry
- **Extensibility**: New modes are added by implementing the required components and registering *
  *one profile entry**
- **Readability**: All mode-specific logic is centralized and discoverable through the profile
- **Maintainability**: Changes to generation behavior are isolated to their respective
  implementations
- **Robustness**: Type safety and consistent contracts across all generation modes
- **No scattered updates**: Adding a new mode requires **zero changes** to existing mode code

## Core Components

### `GenerationExecutor<T>`

Abstract interface that all generation executor strategies must implement:

```dart
abstract class GenerationExecutor<T extends GenerationRequestDto> {
  /// The generation mode this executor handles
  GenerationMode get mode;

  /// Execute generation for this mode
  Future<GenerationResultDto> execute(T request);

  /// Get next steps for successful generation
  List<NextStep> getNextSteps(GenerationResultDto result);
}
```

### `GenerationModeProfile`

Value type that defines all mode-specific components for a generation mode. This is the **single
source of truth** for mode wiring.

**Properties:**

- `mode` - The generation mode enum value
- `brickId` - The brick/template identifier (e.g., 'project', 'feature', 'service')
- `variableProcessor` - The variable processor for this mode
- `strategy` - The generation mode strategy for this mode

### `GenerationExecutorRegistry`

Central registry that maps `GenerationMode` enum values to their corresponding executor strategy
implementations. This registry serves as the **single source of truth for all generation execution**
and must be used for all generation requests.

The registry must be constructed from mode profiles to ensure a single source of truth for all
mode-specific wiring.

**Key methods:**

- `execute(GenerationRequestDto request)` - **Execute generation using the appropriate executor strategy** (preferred method)
- `getStrategy(GenerationMode mode)` - Get executor strategy for a mode (throws if not found)
- `forMode(GenerationMode mode)` - Get executor strategy for a mode (returns null if not found)
- `getProfile(GenerationMode mode)` - Get full profile for a mode (if constructed from profiles)
- `getBrickId(GenerationMode mode)` - Get brick ID for a mode (if constructed from profiles)
- `isRegistered(GenerationMode mode)` - Check if a mode is registered
- `registeredModes` - Get all registered modes

**Important**: All generation execution must go through `GenerationExecutorRegistry.execute()`. CLI commands and MCP adapters delegate to the registry rather than calling executor strategies directly.

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

### 4. Implement Executor Strategy

Create a new executor strategy class in this directory:

```dart
class YourNewModeGenerationExecutor
    implements GenerationExecutor<YourNewModeGenerationRequest> {
  YourNewModeGenerationExecutor({
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

### 5. Create Variable Processor (if needed)

If your mode requires different variable derivation or validation rules, create a new processor:

```dart
class YourNewModeVariableProcessor implements IVariableProcessor {
  // ... implementation
}
```

Register it in `_registerVariableProcessing`:

```dart
..registerSingleton<YourNewModeVariableProcessor>(
YourNewModeVariableProcessor(logger: composerLogger),
)
```

### 6. Register Mode Profile

All generation-related services are registered through the `GenerationServicesFactory` (
`lib/src/cli/application/bootstrapping/generation_services_factory.dart`). This factory serves as
the composition root for all generation dependencies.

To add a new generation mode:

1. Register the use case in `_registerWorkflowAndUseCases` method (if created):

```dart
..registerSingleton<GenerateYourNewModeUseCase>(
GenerateYourNewModeUseCase(
workflowOrchestrator: container.get<IWorkflowOrchestrator>(),
),
)
```

2. **Add a single profile entry** to the `_createModeProfiles` method:

```dart
Map<GenerationMode, GenerationModeProfile> _createModeProfiles(ServiceContainer container,) {
  // ... existing profiles ...

  // Resolve your new processor and use case
  final yourNewModeProcessor = container.get<YourNewModeVariableProcessor>();
  final yourNewModeUseCase = container.get<GenerateYourNewModeUseCase>();

  // Create executor strategy
  final yourNewModeExecutor = YourNewModeGenerationExecutor(
    useCase: yourNewModeUseCase,
  );

  return {
    GenerationMode.feature: featureProfile,
    GenerationMode.service: serviceProfile,
    GenerationMode.project: projectProfile,
    GenerationMode.yourNewMode: GenerationModeProfile(
      mode: GenerationMode.yourNewMode,
      brickId: 'your_new_mode', // The brick identifier
      variableProcessor: yourNewModeProcessor,
      strategy: yourNewModeExecutor,
    ), // Add this single entry
  };
}
```

**That's it!** The factory automatically:

- Registers individual executor strategies as singletons
- Creates and registers the `GenerationExecutorRegistry` from profiles
- Creates and registers the `VariableProcessorFactory` from the same profiles
- Registers the `GenerationMcpAdapter` that uses the registry
- CLI commands use `GenerationExecutorRegistry` directly for execution

**Key benefit**: Adding a new mode requires **zero changes** to existing mode code. Only the new
profile entry is added.

**Note**: The factory pattern centralizes all generation dependency wiring, making it easier to
extend and test. For testing, you can inject a custom `IGenerationServicesFactory` into
`ServiceBootstrapper`.

### 7. Create Command (Optional)

If you want a CLI command for the new mode, create a command class similar to
`GenerateFeatureCommand`.

## Important Rules

1. **All generation modes must have a `GenerationModeProfile`** - This is the single source of truth
   for mode wiring
2. **Register profiles in `_createModeProfiles`** - This is the **only** place where modes are wired
   together
3. **No mode-specific generation logic outside executor strategies** - All generation behavior should be in
   executor strategy implementations
4. **Use the registry for execution** - Always route generation requests through
   `GenerationExecutorRegistry.execute()` - this is the single source of truth for generation execution
5. **Type safety** - Each executor strategy should use a specific request type (`GenerationExecutor<T>`)
6. **No scattered updates** - Adding a new mode should **never** require editing existing mode code
7. **CLI commands delegate to registry** - CLI commands use the registry directly, not through an intermediate handler

## Testing

When adding a new mode, ensure:

1. The executor strategy is registered in the registry
2. The registry's `execute()` method correctly routes requests to your executor strategy
3. The executor strategy's `getNextSteps()` returns appropriate suggestions
4. All CLI-used `GenerationMode` values are represented in the registry

## Current Executor Strategies

- `FeatureGenerationExecutor` - Handles feature/screen generation
- `ServiceGenerationExecutor` - Handles service generation
- `ProjectGenerationExecutor` - Handles project generation

