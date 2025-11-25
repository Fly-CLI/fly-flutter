import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

class MockBrickRepository implements IBrickRepository {
  Brick? _brick;
  bool _shouldThrow = false;

  void setBrick(Brick? brick) {
    _brick = brick;
  }

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<Brick?> getBrick(String name) async {
    if (_shouldThrow) throw Exception('Repository error');
    return _brick;
  }

  @override
  Future<List<Brick>> discoverBricks({bool forceRefresh = false}) async {
    return _brick != null ? [_brick!] : [];
  }

  @override
  Future<bool> brickExists(String name) async {
    return _brick != null && _brick!.name == name;
  }

  @override
  Future<BrickValidationResult> validateBrick(Brick brick) async {
    return BrickValidationResult.success();
  }

  @override
  Future<List<Brick>> getBricksByType(BrickType type) async {
    return _brick != null && _brick!.type == type ? [_brick!] : [];
  }

  @override
  Future<void> clearCache() async {}
}

class MockVariableProcessor implements IVariableProcessor {
  ProcessedVariables? _result;
  bool _shouldFail = false;

  void setResult(ProcessedVariables result) {
    _result = result;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    if (_shouldFail) {
      return ProcessedVariables(
        values: rawVars,
        validationResult: VariableValidationResult.failure([
          'Validation error',
        ]),
      );
    }
    return _result ??
        ProcessedVariables(
          values: rawVars,
          validationResult: VariableValidationResult.success(),
        );
  }
}

class MockGenerationEngine implements IGenerationEngine {
  GenerationResult? _result;
  bool _shouldThrow = false;

  void setResult(GenerationResult result) {
    _result = result;
  }

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<GenerationResult> generate({
    required Brick brick,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    if (_shouldThrow) throw Exception('Generation error');
    return _result ??
        GenerationResult.success(
          files: [],
          targetDirectory: outputDirectory,
        );
  }

  @override
  Future<GenerationResult> preview({
    required Brick brick,
    required Map<String, dynamic> variables,
    required String outputDirectory,
  }) async {
    return generate(
      brick: brick,
      variables: variables,
      outputDirectory: outputDirectory,
      dryRun: true,
    );
  }
}

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

    group('success cases', () {
      test('should execute feature generation successfully', () async {
        // Arrange
        final brick = Brick(
          name: 'feature',
          version: Version.parse('1.0.0'),
          description: 'Test brick',
          path: '/test/brick',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        mockRepository.setBrick(brick);
        mockProcessor.setResult(
          ProcessedVariables(
            values: {'name': 'test_screen'},
            validationResult: VariableValidationResult.success(),
          ),
        );
        mockEngine.setResult(
          GenerationResult.success(
            files: [],
            targetDirectory: '/test/output',
          ),
        );

        final request = GenerationRequestDto(
          mode: GenerationMode.feature,
          variables: {'name': 'test_screen'},
          outputDirectory: '/test/output',
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('should handle dry run mode', () async {
        // Arrange
        final brick = Brick(
          name: 'feature',
          version: Version.parse('1.0.0'),
          description: 'Test brick',
          path: '/test/brick',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        mockRepository.setBrick(brick);
        mockProcessor.setResult(
          ProcessedVariables(
            values: {'name': 'test_screen'},
            validationResult: VariableValidationResult.success(),
          ),
        );

        final request = GenerationRequestDto(
          mode: GenerationMode.feature,
          variables: {'name': 'test_screen'},
          outputDirectory: '/test/output',
          dryRun: true,
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isTrue);
      });
    });

    group('error cases', () {
      test('should return error when brick not found', () async {
        // Arrange
        mockRepository.setBrick(null);

        final request = GenerationRequestDto(
          mode: GenerationMode.feature,
          variables: {'name': 'test_screen'},
          outputDirectory: '/test/output',
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('not found'));
      });

      test('should return error when variable validation fails', () async {
        // Arrange
        final brick = Brick(
          name: 'feature',
          version: Version.parse('1.0.0'),
          description: 'Test brick',
          path: '/test/brick',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        mockRepository.setBrick(brick);
        mockProcessor.setShouldFail(true);

        final request = GenerationRequestDto(
          mode: GenerationMode.feature,
          variables: {'name': 'test_screen'},
          outputDirectory: '/test/output',
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('validation'));
      });

      test('should handle generation engine errors', () async {
        // Arrange
        final brick = Brick(
          name: 'feature',
          version: Version.parse('1.0.0'),
          description: 'Test brick',
          path: '/test/brick',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        mockRepository.setBrick(brick);
        mockProcessor.setResult(
          ProcessedVariables(
            values: {'name': 'test_screen'},
            validationResult: VariableValidationResult.success(),
          ),
        );
        mockEngine.setShouldThrow(true);

        final request = GenerationRequestDto(
          mode: GenerationMode.feature,
          variables: {'name': 'test_screen'},
          outputDirectory: '/test/output',
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('failed'));
      });
    });
  });
}
