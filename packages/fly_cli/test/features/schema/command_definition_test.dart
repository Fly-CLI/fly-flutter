import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
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

      const option = OptionDefinition(
        name: 'template',
        description: 'Project template',
        short: 't',
        type: OptionType.value,
        allowedValues: ['minimal', 'riverpod'],
      );

      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Add a screen',
      );

      const example = CommandExample(
        command: 'fly create my_app --template=minimal',
        description: 'Create a minimal project',
      );

      const command = CommandDefinition(
        name: 'create',
        description: 'Create a new project',
        arguments: [argument],
        options: [option],
        subcommands: [subcommand],
        examples: [example],
        globalOptions: [option],
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

      const option = OptionDefinition(
        name: 'option',
        description: 'Option description',
        short: 'o',
        defaultValue: true,
        isGlobal: true,
      );

      const command = CommandDefinition(
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
      expect(optJson['name'], equals('option'));
      expect(optJson['description'], equals('Option description'));
      expect(optJson['short'], equals('o'));
      expect(optJson['type'], equals('flag'));
      expect(optJson['default_value'], isTrue);
      expect(optJson['is_global'], isTrue);
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

      expect(command.toString(), equals('CommandDefinition(name: test, description: Test command)'));
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
        allowedValues: ['minimal', 'riverpod'],
        defaultValue: 'minimal',
      );

      expect(argument.name, equals('template'));
      expect(argument.description, equals('Project template'));
      expect(argument.required, isFalse);
      expect(argument.allowedValues, equals(['minimal', 'riverpod']));
      expect(argument.defaultValue, equals('minimal'));
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

      expect(argument.toString(), equals('ArgumentDefinition(name: name, required: true)'));
    });
  });

  group('OptionDefinition', () {
    test('creates with required fields', () {
      const option = OptionDefinition(
        name: 'verbose',
        description: 'Enable verbose output',
      );

      expect(option.name, equals('verbose'));
      expect(option.description, equals('Enable verbose output'));
      expect(option.short, isNull);
      expect(option.type, equals(OptionType.flag));
      expect(option.defaultValue, isNull);
      expect(option.allowedValues, isNull);
      expect(option.isGlobal, isFalse);
      expect(option.isRequired, isFalse);
    });

    test('creates with all fields', () {
      const option = OptionDefinition(
        name: 'output',
        description: 'Output format',
        short: 'o',
        type: OptionType.value,
        defaultValue: 'human',
        allowedValues: ['human', 'json'],
        isGlobal: true,
        isRequired: true,
      );

      expect(option.name, equals('output'));
      expect(option.description, equals('Output format'));
      expect(option.short, equals('o'));
      expect(option.type, equals(OptionType.value));
      expect(option.defaultValue, equals('human'));
      expect(option.allowedValues, equals(['human', 'json']));
      expect(option.isGlobal, isTrue);
      expect(option.isRequired, isTrue);
    });

    test('getDisplayName returns correct format', () {
      const withShort = OptionDefinition(
        name: 'verbose',
        description: 'Verbose output',
        short: 'v',
      );

      const withoutShort = OptionDefinition(
        name: 'output',
        description: 'Output format',
      );

      expect(withShort.getDisplayName(), equals('-v/--verbose'));
      expect(withoutShort.getDisplayName(), equals('--output'));
    });

    test('toJson serializes correctly', () {
      const option = OptionDefinition(
        name: 'output',
        description: 'Output format',
        short: 'o',
        type: OptionType.value,
        defaultValue: 'human',
        allowedValues: ['human', 'json'],
        isGlobal: true,
        isRequired: true,
      );

      final json = option.toJson();

      expect(json['name'], equals('output'));
      expect(json['description'], equals('Output format'));
      expect(json['short'], equals('o'));
      expect(json['type'], equals('value'));
      expect(json['default_value'], equals('human'));
      expect(json['allowed_values'], equals(['human', 'json']));
      expect(json['is_global'], isTrue);
      expect(json['is_required'], isTrue);
    });

    test('toJson omits null values', () {
      const option = OptionDefinition(
        name: 'verbose',
        description: 'Verbose output',
      );

      final json = option.toJson();

      expect(json.containsKey('short'), isFalse);
      expect(json.containsKey('default_value'), isFalse);
      expect(json.containsKey('allowed_values'), isFalse);
    });

    test('isValid returns true for valid option', () {
      const option = OptionDefinition(
        name: 'verbose',
        description: 'Valid option',
      );

      expect(option.isValid(), isTrue);
    });

    test('isValid returns false for invalid option', () {
      const invalidName = OptionDefinition(
        name: '',
        description: 'Invalid name',
      );

      const invalidDescription = OptionDefinition(
        name: 'name',
        description: '',
      );

      const invalidFlagDefault = OptionDefinition(
        name: 'flag',
        description: 'Flag option',
        defaultValue: 'not-a-bool',
      );

      expect(invalidName.isValid(), isFalse);
      expect(invalidDescription.isValid(), isFalse);
      expect(invalidFlagDefault.isValid(), isFalse);
    });

    test('toString returns readable representation', () {
      const option = OptionDefinition(
        name: 'verbose',
        description: 'Verbose output',
      );

      expect(option.toString(), equals('OptionDefinition(name: verbose, type: flag)'));
    });
  });

  group('SubcommandDefinition', () {
    test('creates with required fields', () {
      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Add a screen',
      );

      expect(subcommand.name, equals('screen'));
      expect(subcommand.description, equals('Add a screen'));
      expect(subcommand.isHidden, isFalse);
    });

    test('creates with all fields', () {
      const subcommand = SubcommandDefinition(
        name: 'service',
        description: 'Add a service',
        isHidden: true,
      );

      expect(subcommand.name, equals('service'));
      expect(subcommand.description, equals('Add a service'));
      expect(subcommand.isHidden, isTrue);
    });

    test('toJson serializes correctly', () {
      const subcommand = SubcommandDefinition(
        name: 'screen',
        description: 'Add a screen',
        isHidden: true,
      );

      final json = subcommand.toJson();

      expect(json['name'], equals('screen'));
      expect(json['description'], equals('Add a screen'));
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
        description: 'Add a screen',
      );

      expect(subcommand.toString(), equals('SubcommandDefinition(name: screen)'));
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
        command: 'fly create my_app --template=minimal',
        description: 'Create a minimal app',
      );

      final json = example.toJson();

      expect(json['command'], equals('fly create my_app --template=minimal'));
      expect(json['description'], equals('Create a minimal app'));
    });

    test('toString returns readable representation', () {
      const example = CommandExample(
        command: 'fly create my_app',
        description: 'Create a new app',
      );

      expect(example.toString(), equals('CommandExample(command: fly create my_app)'));
    });
  });

  group('OptionType', () {
    test('has correct values', () {
      expect(OptionType.values, hasLength(3));
      expect(OptionType.values, contains(OptionType.flag));
      expect(OptionType.values, contains(OptionType.value));
      expect(OptionType.values, contains(OptionType.multiple));
    });

    test('has correct names', () {
      expect(OptionType.flag.name, equals('flag'));
      expect(OptionType.value.name, equals('value'));
      expect(OptionType.multiple.name, equals('multiple'));
    });
  });
}
