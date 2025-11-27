import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/services/processors/feature_variable_processor.dart';
import 'package:fly_cli/src/generation/brick/brick_metadata.dart';
import 'package:fly_cli/src/generation/domain/entities/brick.dart';
import 'package:fly_cli/src/generation/domain/value_objects/brick_variable.dart'
    as domain;
import 'package:fly_cli/src/generation/foundation/foundation_enums.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureVariableProcessor', () {
    late FeatureVariableProcessor processor;

    setUp(() {
      processor = FeatureVariableProcessor();
    });

    group('process', () {
      test('should process variables successfully', () async {
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
        final result = await processor.process(
          rawVars: rawVars,
          mode: GenerationMode.feature,
          brick: brick,
        );

        // Assert
        expect(result.validationResult, isA<VariableValidationResult>());
      });

      test('should throw ArgumentError for non-feature mode', () async {
        // Arrange
        final brick = Brick(
          name: 'test_brick',
          version: Version.parse('1.0.0'),
          description: 'Test',
          path: '/test',
          type: BrickType.project,
          category: BrickCategory.project,
          variables: {},
          features: [],
          packages: [],
        );

        final rawVars = {
          'name': 'test_project',
        };

        // Act & Assert
        expect(
          () => processor.process(
            rawVars: rawVars,
            mode: GenerationMode.project,
            brick: brick,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
