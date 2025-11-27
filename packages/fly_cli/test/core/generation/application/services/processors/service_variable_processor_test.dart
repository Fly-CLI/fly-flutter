import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/service_variable_processor.dart';
import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/domain/value_objects/brick_variable.dart'
    as domain;
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceVariableProcessor', () {
    late ServiceVariableProcessor processor;

    setUp(() {
      processor = ServiceVariableProcessor();
    });

    group('process', () {
      test('should process variables successfully', () async {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test',
          path: '/test',
          type: BrickType.service,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        final rawVars = {
          'name': 'test_service',
          'generation_mode': 'service',
        };

        // Act
        final result = await processor.process(
          rawVars: rawVars,
          mode: GenerationMode.service,
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
          type: BrickType.service,
          category: BrickCategory.component,
          variables: {},
          features: [],
          packages: [],
        );

        final rawVars = {
          'name': 'test_service',
          'feature': 'core',
        };

        // Act
        final result = await processor.process(
          rawVars: rawVars,
          mode: GenerationMode.service,
          brick: brick,
        );

        // Assert
        expect(result.values['name'], equals('test_service'));
        expect(result.values['feature'], equals('core'));
      });

      test('should validate variables', () async {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test',
          path: '/test',
          type: BrickType.service,
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
          'name': 'test_service',
        };

        // Act
        final result = await processor.process(
          rawVars: rawVars,
          mode: GenerationMode.service,
          brick: brick,
        );

        // Assert
        expect(result.validationResult, isA<VariableValidationResult>());
      });

      test('should throw ArgumentError for non-service mode', () async {
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
          'name': 'test_feature',
        };

        // Act & Assert
        expect(
          () => processor.process(
            rawVars: rawVars,
            mode: GenerationMode.feature,
            brick: brick,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
