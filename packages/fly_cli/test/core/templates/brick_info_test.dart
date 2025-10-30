import 'package:fly_cli/src/core/templates/brick_info.dart';
import 'package:test/test.dart';

void main() {
  group('BrickInfo', () {
    test('should create BrickInfo from JSON', () {
      final json = {
        'name': 'test_brick',
        'version': '1.0.0',
        'description': 'Test brick',
        'path': '/path/to/brick',
        'type': 'project',
        'variables': {
          'project_name': {
            'name': 'project_name',
            'type': 'string',
            'required': true,
            'defaultValue': null,
            'choices': null,
            'description': 'Project name',
            'prompt': null,
          }
        },
        'features': ['feature1', 'feature2'],
        'packages': ['package1'],
        'minFlutterSdk': '3.10.0',
        'minDartSdk': '3.0.0',
        'isValid': true,
        'validationErrors': [],
      };

      final brickInfo = BrickInfo.fromJson(json);

      expect(brickInfo.name, equals('test_brick'));
      expect(brickInfo.version, equals('1.0.0'));
      expect(brickInfo.type, equals(BrickType.project));
      expect(brickInfo.variables.length, equals(1));
      expect(brickInfo.variables['project_name']?.name, equals('project_name'));
      expect(brickInfo.isValid, isTrue);
    });

    test('should convert to JSON', () {
      final brickInfo = BrickInfo(
        name: 'test_brick',
        version: '1.0.0',
        description: 'Test brick',
        path: '/path/to/brick',
        type: BrickType.project,
        variables: {
          'project_name': BrickVariable(
            name: 'project_name',
            type: 'string',
            required: true,
            description: 'Project name',
          ),
        },
        features: ['feature1'],
        packages: ['package1'],
        minFlutterSdk: '3.10.0',
        minDartSdk: '3.0.0',
      );

      final json = brickInfo.toJson();

      expect(json['name'], equals('test_brick'));
      expect(json['type'], equals('project'));
      expect(json['variables'], isA<Map<String, dynamic>>());
    });

    test('should identify required variables', () {
      final brickInfo = BrickInfo(
        name: 'test_brick',
        version: '1.0.0',
        description: 'Test brick',
        path: '/path/to/brick',
        type: BrickType.project,
        variables: {
          'required_var': BrickVariable(
            name: 'required_var',
            type: 'string',
            required: true,
          ),
          'optional_var': BrickVariable(
            name: 'optional_var',
            type: 'string',
            required: false,
          ),
        },
        features: [],
        packages: [],
        minFlutterSdk: '3.10.0',
        minDartSdk: '3.0.0',
      );

      expect(brickInfo.requiredVariables.length, equals(1));
      expect(brickInfo.requiredVariables.first.name, equals('required_var'));
      expect(brickInfo.optionalVariables.length, equals(1));
      expect(brickInfo.optionalVariables.first.name, equals('optional_var'));
    });
  });

  group('BrickVariable', () {
    test('should create BrickVariable from JSON', () {
      final json = {
        'name': 'test_var',
        'type': 'string',
        'required': true,
        'defaultValue': 'default',
        'choices': ['choice1', 'choice2'],
        'description': 'Test variable',
        'prompt': 'Enter test variable',
      };

      final variable = BrickVariable.fromJson(json);

      expect(variable.name, equals('test_var'));
      expect(variable.type, equals('string'));
      expect(variable.required, isTrue);
      expect(variable.defaultValue, equals('default'));
      expect(variable.choices, equals(['choice1', 'choice2']));
      expect(variable.description, equals('Test variable'));
      expect(variable.prompt, equals('Enter test variable'));
    });

    test('should convert to JSON', () {
      final variable = BrickVariable(
        name: 'test_var',
        type: 'string',
        required: true,
        defaultValue: 'default',
        choices: ['choice1', 'choice2'],
        description: 'Test variable',
        prompt: 'Enter test variable',
      );

      final json = variable.toJson();

      expect(json['name'], equals('test_var'));
      expect(json['type'], equals('string'));
      expect(json['required'], isTrue);
      expect(json['defaultValue'], equals('default'));
      expect(json['choices'], equals(['choice1', 'choice2']));
    });
  });
}
