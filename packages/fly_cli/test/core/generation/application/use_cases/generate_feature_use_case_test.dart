import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/modes/generation_request_factory.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/application/use_cases/generate_feature_use_case.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/generation_variable_builder.dart';
import 'package:fly_cli/src/generation/generators/generation_result.dart';
import 'package:test/test.dart';

/// Simple mock for [IWorkflowOrchestrator] to drive the feature use case.
class MockWorkflowOrchestrator implements IWorkflowOrchestrator {
  GenerationResult? _result;
  bool _shouldThrow = false;

  // Captured call parameters for assertions
  GenerationModeProfile? lastProfile;
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
    required GenerationModeProfile profile,
    required Map<String, dynamic> variables,
    required String outputDirectory,
    bool dryRun = false,
  }) async {
    lastProfile = profile;
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

/// Mock variable processor for testing
class _MockVariableProcessor implements IVariableProcessor {
  @override
  Future<ProcessedVariables> process({
    required Map<String, dynamic> rawVars,
    required GenerationMode mode,
    required Brick brick,
  }) async {
    return ProcessedVariables(
      values: rawVars,
      validationResult: VariableValidationResult.success(),
    );
  }
}

/// Mock strategy for testing
class _MockFeatureGenerationExecutor implements GenerationExecutor<FeatureGenerationRequest> {
  @override
  GenerationMode get mode => GenerationMode.feature;

  @override
  Future<GenerationResultDto> execute(FeatureGenerationRequest request) async {
    return const GenerationResultDto(
      success: true,
      generatedFiles: [],
      data: {},
    );
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    return [];
  }
}

void main() {
  group('GenerateFeatureUseCase', () {
    late MockWorkflowOrchestrator mockOrchestrator;
    late GenerateFeatureUseCase useCase;
    late GenerationModeProfile profile;

    setUp(() {
      mockOrchestrator = MockWorkflowOrchestrator();

      profile = GenerationModeProfile(
        mode: GenerationMode.feature,
        brickId: BrickId.feature,
        variableProcessor: _MockVariableProcessor(),
        strategy: _MockFeatureGenerationExecutor(),
        variableBuilder: const FeatureVariableBuilder(),
        requestFactory: const FeatureRequestFactory(),
      );

      useCase = GenerateFeatureUseCase(
        workflowOrchestrator: mockOrchestrator,
        profile: profile,
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
        expect(mockOrchestrator.lastProfile?.mode, GenerationMode.feature);
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
