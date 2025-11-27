import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';
import 'package:test/test.dart';

/// Simple mock for [IWorkflowOrchestrator] to drive the feature use case.
class MockWorkflowOrchestrator implements IWorkflowOrchestrator {
  GenerationResult? _result;
  bool _shouldThrow = false;

  // Captured call parameters for assertions
  GenerationMode? lastMode;
  Map<String, dynamic>? lastVariables;
  String? lastOutputDirectory;
  bool? lastDryRun;

  void setResult(GenerationResult result) {
    _result = result;
  }

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<GenerationResult> executeWorkflow({
    required GenerationMode mode,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    lastMode = mode;
    lastVariables = variables;
    lastOutputDirectory = outputDirectory;
    lastDryRun = dryRun;

    if (_shouldThrow) {
      throw Exception('Orchestrator error');
    }

    return _result ??
        GenerationResult.success(
          files: const [],
          targetDirectory: outputDirectory,
        );
  }
}

void main() {
  group('GenerateFeatureUseCase', () {
    late MockWorkflowOrchestrator mockOrchestrator;
    late GenerateFeatureUseCase useCase;

    setUp(() {
      mockOrchestrator = MockWorkflowOrchestrator();

      useCase = GenerateFeatureUseCase(
        workflowOrchestrator: mockOrchestrator,
      );
    });

    group('success cases', () {
      test('should execute feature generation successfully', () async {
        // Arrange
        mockOrchestrator.setResult(
          GenerationResult.success(
            files: const [],
            targetDirectory: '/test/output',
          ),
        );

        const request = FeatureGenerationRequest(
          name: 'test_screen',
          outputDirectory: '/test/output',
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(mockOrchestrator.lastMode, GenerationMode.feature);
        expect(mockOrchestrator.lastOutputDirectory, '/test/output');
      });

      test('should handle dry run mode', () async {
        // Arrange
        // Default orchestrator result is success

        const request = FeatureGenerationRequest(
          name: 'test_screen',
          outputDirectory: '/test/output',
          dryRun: true,
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isTrue);
        expect(mockOrchestrator.lastDryRun, isTrue);
      });
    });

    group('error cases', () {
      test('should return error when brick not found', () async {
        // Arrange
        mockOrchestrator.setResult(
          GenerationResult.failure(
            error: 'Brick "feature" not found',
            data: const {'brick_name': 'feature'},
          ),
        );

        const request = FeatureGenerationRequest(
          name: 'test_screen',
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
        mockOrchestrator.setResult(
          GenerationResult.failure(
            error: 'Variable validation failed: Validation error',
            data: const {
              'validation_errors': ['Validation error'],
            },
          ),
        );

        const request = FeatureGenerationRequest(
          name: 'test_screen',
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
        mockOrchestrator.setShouldThrow(true);

        const request = FeatureGenerationRequest(
          name: 'test_screen',
          outputDirectory: '/test/output',
        );

        // Act
        final result = await useCase.execute(request);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Feature generation failed'));
      });
    });
  });
}
