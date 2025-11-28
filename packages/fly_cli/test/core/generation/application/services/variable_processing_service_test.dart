import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/modes/generation_request_factory.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor_factory.dart';
import 'package:fly_cli/src/generation/application/services/processors/feature_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/project_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/service_variable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_executor.dart';
import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/domain/value_objects/brick_variable.dart'
    as domain;
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/generation_variable_builder.dart';
import 'package:fly_cli/src/generation/infrastructure/variable_processing/variable_processor_factory.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// Integration tests for the variable processor factory and processors.
///
/// Tests the complete flow of variable processing through the factory,
/// ensuring that the mode-specific processors work correctly.
void main() {
  group('VariableProcessorFactory Integration', () {
    late IVariableProcessorFactory factory;

    setUp(() {
      final projectProcessor = ProjectVariableProcessor();
      final featureProcessor = FeatureVariableProcessor();
      final serviceProcessor = ServiceVariableProcessor();
      final mockStrategy = _MockGenerationExecutor();

      final profiles = {
        GenerationMode.project: GenerationModeProfile(
          mode: GenerationMode.project,
          brickId: BrickId.project,
          variableProcessor: projectProcessor,
          strategy: mockStrategy,
          variableBuilder: const ProjectVariableBuilder(),
          requestFactory: const ProjectRequestFactory(),
        ),
        GenerationMode.feature: GenerationModeProfile(
          mode: GenerationMode.feature,
          brickId: BrickId.feature,
          variableProcessor: featureProcessor,
          strategy: mockStrategy,
          variableBuilder: const FeatureVariableBuilder(),
          requestFactory: const FeatureRequestFactory(),
        ),
        GenerationMode.service: GenerationModeProfile(
          mode: GenerationMode.service,
          brickId: BrickId.service,
          variableProcessor: serviceProcessor,
          strategy: mockStrategy,
          variableBuilder: const ServiceVariableBuilder(),
          requestFactory: const ServiceRequestFactory(),
        ),
      };

      factory = VariableProcessorFactory.fromProfiles(profiles);
    });

    group('Feature mode processing', () {
      test('should process feature variables successfully', () async {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test',
          path: '/test',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        final rawVars = {
          'name': 'test_screen',
          'generation_mode': 'feature',
        };

        // Act
        final processor = factory.getProcessor(GenerationMode.feature);
        final result = await processor.process(
          rawVars: rawVars,
          mode: GenerationMode.feature,
          brick: brick,
        );

        // Assert
        expect(result, isA<ProcessedVariables>());
        expect(result.values, isA<Map<String, dynamic>>());
        expect(result.validationResult, isA<VariableValidationResult>());
      });

      test('should include original variables in result', () async {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test',
          path: '/test',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        final rawVars = {
          'name': 'test_screen',
          'feature': 'home',
        };

        // Act
        final processor = factory.getProcessor(GenerationMode.feature);
        final result = await processor.process(
          rawVars: rawVars,
          mode: GenerationMode.feature,
          brick: brick,
        );

        // Assert
        expect(result.values['name'], equals('test_screen'));
        expect(result.values['feature'], equals('home'));
      });

      test('should validate variables', () async {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test',
          path: '/test',
          type: BrickType.feature,
          category: BrickCategory.component,
          variables: {
            'name': const domain.BrickVariable(
              name: 'name',
              type: 'string',
              required: true,
            ),
          },
          features: [],
          packages: [],
          minFlutterSdk: Version.parse('3.10.0'),
          minDartSdk: Version.parse('3.0.0'),
        );

        final rawVars = {
          'name': 'test_screen',
        };

        // Act
        final processor = factory.getProcessor(GenerationMode.feature);
        final result = await processor.process(
          rawVars: rawVars,
          mode: GenerationMode.feature,
          brick: brick,
        );

        // Assert
        expect(result.validationResult, isA<VariableValidationResult>());
      });
    });
  });
}

/// Mock strategy for testing
class _MockGenerationExecutor implements GenerationExecutor<GenerationRequestDto> {
  @override
  GenerationMode get mode => GenerationMode.project;

  @override
  Future<GenerationResultDto> execute(GenerationRequestDto request) async {
    throw UnimplementedError();
  }

  @override
  List<NextStep> getNextSteps(GenerationResultDto result) {
    throw UnimplementedError();
  }
}
