import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/generation/application/dto/generation_request_dto.dart';
import 'package:fly_cli/src/generation/application/dto/generation_result_dto.dart';
import 'package:fly_cli/src/generation/application/modes/generation_mode_profile.dart';
import 'package:fly_cli/src/generation/application/services/processors/feature_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/project_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/service_variable_processor.dart';
import 'package:fly_cli/src/generation/application/strategies/generation_mode_strategy.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/infrastructure/variable_processing/variable_processor_factory.dart';
import 'package:test/test.dart';

void main() {
  group('VariableProcessorFactory', () {
    late VariableProcessorFactory factory;
    late ProjectVariableProcessor projectProcessor;
    late FeatureVariableProcessor featureProcessor;
    late ServiceVariableProcessor serviceProcessor;
    late _MockStrategy mockStrategy;

    setUp(() {
      projectProcessor = ProjectVariableProcessor();
      featureProcessor = FeatureVariableProcessor();
      serviceProcessor = ServiceVariableProcessor();
      mockStrategy = _MockStrategy();

      final profiles = {
        GenerationMode.project: GenerationModeProfile(
          mode: GenerationMode.project,
          brickId: 'project',
          variableProcessor: projectProcessor,
          strategy: mockStrategy,
        ),
        GenerationMode.feature: GenerationModeProfile(
          mode: GenerationMode.feature,
          brickId: 'feature',
          variableProcessor: featureProcessor,
          strategy: mockStrategy,
        ),
        GenerationMode.service: GenerationModeProfile(
          mode: GenerationMode.service,
          brickId: 'service',
          variableProcessor: serviceProcessor,
          strategy: mockStrategy,
        ),
      };

      factory = VariableProcessorFactory.fromProfiles(profiles);
    });

    group('getProcessor', () {
      test('should return project processor for project mode', () {
        // Act
        final result = factory.getProcessor(GenerationMode.project);

        // Assert
        expect(result, same(projectProcessor));
        expect(result, isA<ProjectVariableProcessor>());
      });

      test('should return feature processor for feature mode', () {
        // Act
        final result = factory.getProcessor(GenerationMode.feature);

        // Assert
        expect(result, same(featureProcessor));
        expect(result, isA<FeatureVariableProcessor>());
      });

      test('should return service processor for service mode', () {
        // Act
        final result = factory.getProcessor(GenerationMode.service);

        // Assert
        expect(result, same(serviceProcessor));
        expect(result, isA<ServiceVariableProcessor>());
      });
    });

    group('getProcessorOrNull', () {
      test('should return project processor for project mode', () {
        // Act
        final result = factory.getProcessorOrNull(GenerationMode.project);

        // Assert
        expect(result, same(projectProcessor));
      });

      test('should return feature processor for feature mode', () {
        // Act
        final result = factory.getProcessorOrNull(GenerationMode.feature);

        // Assert
        expect(result, same(featureProcessor));
      });

      test('should return service processor for service mode', () {
        // Act
        final result = factory.getProcessorOrNull(GenerationMode.service);

        // Assert
        expect(result, same(serviceProcessor));
      });
    });

    group('fromProfiles', () {
      test('should throw ArgumentError when constructed with empty profiles', () {
        expect(
          () => VariableProcessorFactory.fromProfiles({}),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

/// Mock strategy for testing
class _MockStrategy implements GenerationModeStrategy<GenerationRequestDto> {
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
