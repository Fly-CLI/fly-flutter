# Fly CLI Architecture Migration Guide

## Overview

This guide helps you migrate from the old architecture to the new Clean Architecture implementation.

## Migration Strategy

### Phase 1: Gradual Migration
The new architecture is designed to coexist with the old code. You can migrate incrementally:

1. New code should use the new architecture
2. Existing code continues to work
3. Migrate modules one at a time

### Phase 2: Using New Components

#### Using Use Cases

**Old Way:**
```dart
final generator = FeatureGenerator(
  context: context,
  logger: logger,
);
final result = await generator.generate(
  rawVars: rawVars,
  outputDirectory: targetDir,
);
```

**New Way:**
```dart
final useCase = GenerateFeatureUseCase(
  brickRepository: brickRepository,
  variableProcessor: variableProcessor,
  generationEngine: generationEngine,
);

final request = GenerationRequestDto(
  mode: GenerationMode.feature,
  variables: rawVars,
  outputDirectory: targetDir,
);

final result = await useCase.execute(request);
```

#### Using Repositories

**Old Way:**
```dart
final brickRegistry = BrickRegistry(logger: logger);
final bricks = await brickRegistry.discoverBricks();
```

**New Way:**
```dart
final repository = BrickRepositoryImpl(
  brickRegistry: brickRegistry,
);
final bricks = await repository.discoverBricks();
```

#### Using Command Handler

**Old Way:**
```dart
final generator = FeatureGenerator(...);
final result = await generator.generate(...);
```

**New Way:**
```dart
final handler = GenerationCommandHandler(
  generateFeatureUseCase: featureUseCase,
  generateServiceUseCase: serviceUseCase,
  generateProjectUseCase: projectUseCase,
);

final result = await handler.executeFeature(
  variables: variables,
  outputDirectory: outputDir,
);
```

## Dependency Injection Setup

### Service Container Configuration

```dart
final container = ScaffoldingServiceContainer(baseContainer);

// Register repositories
container.registerBrickRepository(
  BrickRepositoryImpl(brickRegistry: brickRegistry),
);

container.registerTemplateRepository(
  TemplateRepositoryImpl(templateManager: templateManager),
);

// Register services
container.registerGenerationEngine(
  MasonGenerationEngine(
    masonAdapter: MasonAdapter(),
    logger: logger,
  ),
);

container.registerVariableProcessor(
  VariableProcessingService(),
);

// Register use cases
final featureUseCase = GenerateFeatureUseCase(
  brickRepository: container.getBrickRepository(),
  variableProcessor: container.getVariableProcessor(),
  generationEngine: container.getGenerationEngine(),
);
```

## MCP Integration

### Using MCP Adapters

**Old Way:**
```dart
final generationService = GenerationService(...);
final result = await generationService.generate(...);
```

**New Way:**
```dart
final adapter = GenerationMcpAdapter(
  generateFeatureUseCase: featureUseCase,
  generateServiceUseCase: serviceUseCase,
  generateProjectUseCase: projectUseCase,
);

final result = await adapter.generateFeature(
  screenName: 'home',
  outputDirectory: outputDir,
);
```

## Testing

### Unit Testing Use Cases

```dart
test('GenerateFeatureUseCase executes successfully', () async {
  // Arrange
  final mockBrickRepository = MockBrickRepository();
  final mockVariableProcessor = MockVariableProcessor();
  final mockGenerationEngine = MockGenerationEngine();

  when(mockBrickRepository.getBrick(any))
      .thenAnswer((_) async => mockBrick);
  when(mockVariableProcessor.process(any))
      .thenAnswer((_) async => processedVariables);
  when(mockGenerationEngine.generate(any))
      .thenAnswer((_) async => successResult);

  final useCase = GenerateFeatureUseCase(
    brickRepository: mockBrickRepository,
    variableProcessor: mockVariableProcessor,
    generationEngine: mockGenerationEngine,
  );

  // Act
  final result = await useCase.execute(request);

  // Assert
  expect(result.success, isTrue);
  verify(mockBrickRepository.getBrick('feature')).called(1);
});
```

## Backward Compatibility

All existing APIs remain functional. The new architecture provides:
- Factory methods for converting between old and new types
- Adapter classes that wrap old implementations
- Gradual migration path

## Common Patterns

### Creating a New Use Case

1. Define the use case interface (if needed)
2. Implement the use case class
3. Register in service container
4. Use in commands or MCP tools

### Creating a New Repository

1. Define the repository interface in domain layer
2. Implement in infrastructure layer
3. Register in service container
4. Use in use cases

## Troubleshooting

### Issue: Service not registered
**Solution**: Ensure all dependencies are registered in the service container before use.

### Issue: Circular dependencies
**Solution**: Review dependency flow - dependencies should only flow inward (toward domain).

### Issue: Tests failing
**Solution**: Use mocks for all dependencies. All interfaces are mockable.

## Next Steps

1. Review the architecture documentation
2. Set up dependency injection
3. Migrate one command at a time
4. Add tests for new components
5. Update MCP tools to use adapters

