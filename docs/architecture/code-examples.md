# Fly CLI Architecture Code Examples

## Example 1: Creating a Use Case

```dart
// Domain interface
abstract class IMyRepository {
  Future<MyEntity> getEntity(String id);
}

// Application use case
class GetEntityUseCase {
  GetEntityUseCase({
    required IMyRepository repository,
  }) : _repository = repository;

  final IMyRepository _repository;

  Future<EntityDto> execute(String id) async {
    final entity = await _repository.getEntity(id);
    return EntityDto.fromEntity(entity);
  }
}

// Infrastructure implementation
class MyRepositoryImpl implements IMyRepository {
  @override
  Future<MyEntity> getEntity(String id) async {
    // Implementation details
  }
}
```

## Example 2: Using Dependency Injection

```dart
// Setup
final container = ScaffoldingServiceContainer(baseContainer);

// Register dependencies
container.registerBrickRepository(
  BrickRepositoryImpl(brickRegistry: brickRegistry),
);

// Resolve dependencies
final repository = container.getBrickRepository();
final useCase = GenerateFeatureUseCase(
  brickRepository: repository,
  variableProcessor: container.getVariableProcessor(),
  generationEngine: container.getGenerationEngine(),
);
```

## Example 3: Command Using Use Case

```dart
class MyCommand extends GenerationCommandBase {
  MyCommand(
    super.context, {
    required GenerationCommandHandler handler,
  }) : _handler = handler;

  final GenerationCommandHandler _handler;

  @override
  Future<CommandResult> execute() async {
    final variables = await buildVariables(
      interactive: false,
      outputDir: null,
    );

    final result = await _handler.executeFeature(
      variables: variables,
      outputDirectory: outputDir,
    );

    return result;
  }
}
```

## Example 4: MCP Tool Using Adapter

```dart
class MyMcpToolStrategy extends McpToolStrategy {
  MyMcpToolStrategy({
    required GenerationMcpAdapter adapter,
  }) : _adapter = adapter;

  final GenerationMcpAdapter _adapter;

  @override
  Future<Result> execute(Params params) async {
    final result = await _adapter.generateFeature(
      screenName: params.screenName,
      outputDirectory: params.outputDirectory,
    );

    return Result(
      success: result.success,
      message: result.error ?? 'Success',
    );
  }
}
```

## Example 5: Testing a Use Case

```dart
void main() {
  group('GenerateFeatureUseCase', () {
    late MockBrickRepository mockRepository;
    late MockVariableProcessor mockProcessor;
    late MockGenerationEngine mockEngine;
    late GenerateFeatureUseCase useCase;

    setUp(() {
      mockRepository = MockBrickRepository();
      mockProcessor = MockVariableProcessor();
      mockEngine = MockGenerationEngine();
      
      useCase = GenerateFeatureUseCase(
        brickRepository: mockRepository,
        variableProcessor: mockProcessor,
        generationEngine: mockEngine,
      );
    });

    test('executes successfully', () async {
      // Arrange
      when(mockRepository.getBrick('fly_foundation_feature'))
          .thenAnswer((_) async => mockBrick);
      when(mockProcessor.process(any))
          .thenAnswer((_) async => processedVariables);
      when(mockEngine.generate(any))
          .thenAnswer((_) async => successResult);

      // Act
      final result = await useCase.execute(request);

      // Assert
      expect(result.success, isTrue);
      verify(mockRepository.getBrick('fly_foundation_feature')).called(1);
    });
  });
}
```

## Example 6: Creating a Value Object

```dart
class VersionRange {
  const VersionRange({
    required this.minVersion,
    this.maxVersion,
    this.includeMin = true,
    this.includeMax = false,
  });

  final Version minVersion;
  final Version? maxVersion;
  final bool includeMin;
  final bool includeMax;

  bool satisfies(Version version) {
    final minCheck = includeMin
        ? version >= minVersion
        : version > minVersion;

    if (!minCheck) return false;
    if (maxVersion == null) return true;

    return includeMax
        ? version <= maxVersion!
        : version < maxVersion!;
  }
}
```

## Example 7: Domain Service

```dart
class CompatibilityService implements ICompatibilityService {
  const CompatibilityService();

  @override
  CompatibilityResult checkSdkCompatibility({
    required Version? requiredSdk,
    required Version currentSdk,
  }) {
    if (requiredSdk == null) {
      return const CompatibilityResult.compatible();
    }

    if (currentSdk < requiredSdk) {
      return CompatibilityResult.incompatible(
        errors: [
          'SDK version $currentSdk is below required version $requiredSdk',
        ],
      );
    }

    return const CompatibilityResult.compatible();
  }
}
```

## Example 8: Repository Implementation

```dart
class BrickRepositoryImpl implements IBrickRepository {
  BrickRepositoryImpl({
    required BrickRegistry brickRegistry,
  }) : _brickRegistry = brickRegistry;

  final BrickRegistry _brickRegistry;

  @override
  Future<BrickInfo?> getBrick(String name) async {
    final bricks = await discoverBricks();
    try {
      return bricks.firstWhere((brick) => brick.name == name);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BrickInfo>> discoverBricks({bool forceRefresh = false}) async {
    return await _brickRegistry.discoverBricks(forceRefresh: forceRefresh);
  }
}
```

