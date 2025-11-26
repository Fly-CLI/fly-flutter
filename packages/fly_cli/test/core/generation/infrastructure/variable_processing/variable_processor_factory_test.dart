import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/feature_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/project_variable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/service_variable_processor.dart';
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:fly_cli/src/generation/infrastructure/variable_processing/variable_processor_factory.dart';
import 'package:test/test.dart';

void main() {
  group('VariableProcessorFactory', () {
    late VariableProcessorFactory factory;
    late ProjectVariableProcessor projectProcessor;
    late FeatureVariableProcessor featureProcessor;
    late ServiceVariableProcessor serviceProcessor;

    setUp(() {
      projectProcessor = ProjectVariableProcessor();
      featureProcessor = FeatureVariableProcessor();
      serviceProcessor = ServiceVariableProcessor();

      factory = VariableProcessorFactory(
        projectProcessor: projectProcessor,
        featureProcessor: featureProcessor,
        serviceProcessor: serviceProcessor,
      );
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
  });
}

