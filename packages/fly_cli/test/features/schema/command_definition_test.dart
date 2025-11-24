import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/domain/command_metadata.dart';
import 'package:test/test.dart';

void main() {
  group('CommandDefinition', () {
    test('creates with required fields', () {
      const command = CommandDefinition(
        name: 'test',
        description: 'Test command',
      );

      expect(command.name, equals('test'));
      expect(command.description, equals('Test command'));
      expect(command.arguments, isEmpty);
      expect(command.options, isEmpty);
      expect(command.subcommands, isEmpty);
      expect(command.examples, isEmpty);
      expect(command.globalOptions, isEmpty);
      expect(command.isHidden, isFalse);
    });

    test('creates with all fields', () {
      const argument = ArgumentDefinition(
        name: 'project_name',
        description: 'Name of the project',
      );

      final option = GlobalFormatFlag();
      const globalOption = GlobalDebugFlag();

      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Generate a screen',
      );

      const example = CommandExample(
        command: 'fly create my_app --template=fly_foundation',
        description: 'Create a fly_foundation project',
      );

      final command = CommandDefinition(
        name: 'create',
        description: 'Create a new project',
        arguments: [argument],
        options: [option],
        subcommands: [subcommand],
        examples: [example],
        globalOptions: [globalOption],
        isHidden: true,
      );

      expect(command.name, equals('create'));
      expect(command.description, equals('Create a new project'));
      expect(command.arguments, hasLength(1));
      expect(command.options, hasLength(1));
      expect(command.subcommands, hasLength(1));
      expect(command.examples, hasLength(1));
      expect(command.globalOptions, hasLength(1));
      expect(command.isHidden, isTrue);
    });

    test('copyWith creates new instance with modified fields', () {
      const original = CommandDefinition(
        name: 'test',
        description: 'Original description',
      );

      final modified = original.copyWith(
        description: 'Modified description',
        isHidden: true,
      );

      expect(modified.name, equals('test'));
      expect(modified.description, equals('Modified description'));
      expect(modified.isHidden, isTrue);
      expect(original.description, equals('Original description'));
      expect(original.isHidden, isFalse);
    });

    test('toJson serializes correctly', () {
      const argument = ArgumentDefinition(
        name: 'name',
        description: 'Argument description',
        allowedValues: ['value1', 'value2'],
        defaultValue: 'value1',
      );

      final option = GlobalFormatFlag();

      final command = CommandDefinition(
        name: 'test',
        description: 'Test command',
        arguments: [argument],
        options: [option],
        globalOptions: [option],
      );

      final json = command.toJson();

      expect(json['name'], equals('test'));
      expect(json['description'], equals('Test command'));
      expect(json['arguments'], hasLength(1));
      expect(json['options'], hasLength(1));
      expect(json['global_options'], hasLength(1));
      expect(json['is_hidden'], isFalse);

      final argJson = json['arguments'][0];
      expect(argJson['name'], equals('name'));
      expect(argJson['description'], equals('Argument description'));
      expect(argJson['required'], isTrue);
      expect(argJson['allowed_values'], equals(['value1', 'value2']));
      expect(argJson['default_value'], equals('value1'));

      final optJson = json['options'][0];
      expect(optJson['name'], equals('format'));
      expect(optJson['description'],
          equals('Output format (human, json, or ai)'));
      expect(optJson['abbreviation'], equals('f'));
      expect(optJson['category'], equals('output'));
      expect(optJson['type'], equals('value'));
      expect(optJson['default_value'], equals('human'));
      expect(optJson['allowed_values'], equals(['human', 'json', 'ai']));
      expect(optJson['is_global'], isTrue);
      expect(optJson['is_negatable'], isFalse);
      expect(optJson['is_required'], isFalse);
    });

    test('isValid returns true for valid command', () {
      const command = CommandDefinition(
        name: 'test',
        description: 'Valid command',
      );

      expect(command.isValid(), isTrue);
    });

    test('isValid returns false for invalid command', () {
      const invalidName = CommandDefinition(
        name: '',
        description: 'Invalid name',
      );

      const invalidDescription = CommandDefinition(
        name: 'test',
        description: '',
      );

      expect(invalidName.isValid(), isFalse);
      expect(invalidDescription.isValid(), isFalse);
    });

    test('toString returns readable representation', () {
      const command = CommandDefinition(
        name: 'test',
        description: 'Test command',
      );

      expect(command.toString(),
          equals('CommandDefinition(name: test, description: Test command)'));
    });
  });

  group('ArgumentDefinition', () {
    test('creates with required fields', () {
      const argument = ArgumentDefinition(
        name: 'name',
        description: 'Argument description',
      );

      expect(argument.name, equals('name'));
      expect(argument.description, equals('Argument description'));
      expect(argument.required, isTrue);
      expect(argument.allowedValues, isNull);
      expect(argument.defaultValue, isNull);
    });

    test('creates with all fields', () {
      const argument = ArgumentDefinition(
        name: 'template',
        description: 'Project template',
        required: false,
        allowedValues: ['fly_foundation'],
        defaultValue: 'fly_foundation',
      );

      expect(argument.name, equals('template'));
      expect(argument.description, equals('Project template'));
      expect(argument.required, isFalse);
      expect(argument.allowedValues, equals(['fly_foundation']));
      expect(argument.defaultValue, equals('fly_foundation'));
    });

    test('toJson serializes correctly', () {
      const argument = ArgumentDefinition(
        name: 'name',
        description: 'Description',
        allowedValues: ['a', 'b'],
        defaultValue: 'a',
      );

      final json = argument.toJson();

      expect(json['name'], equals('name'));
      expect(json['description'], equals('Description'));
      expect(json['required'], isTrue);
      expect(json['allowed_values'], equals(['a', 'b']));
      expect(json['default_value'], equals('a'));
    });

    test('toJson omits null values', () {
      const argument = ArgumentDefinition(
        name: 'name',
        description: 'Description',
      );

      final json = argument.toJson();

      expect(json.containsKey('allowed_values'), isFalse);
      expect(json.containsKey('default_value'), isFalse);
    });

    test('isValid returns true for valid argument', () {
      const argument = ArgumentDefinition(
        name: 'name',
        description: 'Valid argument',
      );

      expect(argument.isValid(), isTrue);
    });

    test('isValid returns false for invalid argument', () {
      const invalidName = ArgumentDefinition(
        name: '',
        description: 'Invalid name',
      );

      const invalidDescription = ArgumentDefinition(
        name: 'name',
        description: '',
      );

      expect(invalidName.isValid(), isFalse);
      expect(invalidDescription.isValid(), isFalse);
    });

    test('toString returns readable representation', () {
      const argument = ArgumentDefinition(
        name: 'name',
        description: 'Description',
      );

      expect(argument.toString(),
          equals('ArgumentDefinition(name: name, required: true)'));
    });
  });

  group('CliFlag serialization', () {
    test('serializes flag metadata map correctly', () {
      final flag = GlobalFormatFlag();

      final json = flag.toJson();

      expect(json['name'], equals('format'));
      expect(json['description'],
          equals('Output format (human, json, or ai)'));
      expect(json['abbreviation'], equals('f'));
      expect(json['category'], equals('output'));
      expect(json['type'], equals('value'));
      expect(json['allowed_values'], equals(['human', 'json', 'ai']));
      expect(json['default_value'], equals('human'));
      expect(json['is_global'], isTrue);
      expect(json['is_negatable'], isFalse);
      expect(json['is_required'], isFalse);
    });

    test('round-trips flag from JSON metadata', () {
      final flag = GlobalFormatFlag();

      final restored = CliFlag.fromJson(
        flag.toJson(isGlobalOverride: true),
      );

      expect(restored.name, equals(flag.name));
      expect(restored.description, equals(flag.description));
      expect(restored.abbreviation, equals(flag.abbreviation));
      expect(restored.isGlobal, isTrue);
      expect(restored.category, equals(flag.category));
      expect(restored.type, equals(flag.type));
      expect(restored.allowedValues, equals(flag.allowedValues));
      expect(restored.defaultValue, equals(flag.defaultValue));
      expect(restored.isNegatable, equals(flag.isNegatable));
    });
  });

  group('SubcommandDefinition', () {
    test('creates with required fields', () {
      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Generate a screen',
      );

      expect(subcommand.name, equals('screen'));
      expect(subcommand.description, equals('Generate a screen'));
      expect(subcommand.isHidden, isFalse);
    });

    test('creates with all fields', () {
      const subcommand = SubcommandDefinition(
        name: 'service',
        description: 'Generate a service',
        isHidden: true,
      );

      expect(subcommand.name, equals('service'));
      expect(subcommand.description, equals('Generate a service'));
      expect(subcommand.isHidden, isTrue);
    });

    test('toJson serializes correctly', () {
      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Generate a screen',
        isHidden: true,
      );

      final json = subcommand.toJson();

      expect(json['name'], equals('screen'));
      expect(json['description'], equals('Generate a screen'));
      expect(json['is_hidden'], isTrue);
    });

    test('isValid returns true for valid subcommand', () {
      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Valid subcommand',
      );

      expect(subcommand.isValid(), isTrue);
    });

    test('isValid returns false for invalid subcommand', () {
      const invalidName = SubcommandDefinition(
        name: '',
        description: 'Invalid name',
      );

      const invalidDescription = SubcommandDefinition(
        name: 'name',
        description: '',
      );

      expect(invalidName.isValid(), isFalse);
      expect(invalidDescription.isValid(), isFalse);
    });

    test('toString returns readable representation', () {
      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Generate a screen',
      );

      expect(
          subcommand.toString(), equals('SubcommandDefinition(name: screen)'));
    });
  });

  group('CommandExample', () {
    test('creates with required fields', () {
      const example = CommandExample(
        command: 'fly create my_app',
        description: 'Create a new app',
      );

      expect(example.command, equals('fly create my_app'));
      expect(example.description, equals('Create a new app'));
    });

    test('toJson serializes correctly', () {
      const example = CommandExample(
        command: 'fly create my_app --template=fly_foundation',
        description: 'Create a fly_foundation app',
      );

      final json = example.toJson();

      expect(json['command'], equals('fly create my_app --template=fly_foundation'));
      expect(json['description'], equals('Create a fly_foundation app'));
    });

    test('toString returns readable representation', () {
      const example = CommandExample(
        command: 'fly create my_app',
        description: 'Create a new app',
      );

      expect(example.toString(),
          equals('CommandExample(command: fly create my_app)'));
    });
  });

}
