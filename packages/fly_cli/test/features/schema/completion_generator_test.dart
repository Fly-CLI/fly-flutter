import 'package:args/args.dart' hide OptionType;
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/fly_command_type.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/generators/bash_generator.dart';
import 'package:fly_cli/src/features/completion/generators/fish_generator.dart';
import 'package:fly_cli/src/features/completion/generators/powershell_generator.dart';
import 'package:fly_cli/src/features/completion/generators/zsh_generator.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';

/// Helper to create command instances from enum for testing
({
  Map<FlyCommandType, Command<int>> commandInstances,
  Map<String, Command<int>> commandGroups,
}) _createCommandInstances() {
  final context = CommandTestHelper.createMockCommandContext();
  final commandInstances = <FlyCommandType, Command<int>>{};
  
  // Create instances for all command types
  for (final commandType in FlyCommandType.values) {
    commandInstances[commandType] = commandType.createInstance(context);
  }
  
  // Build command groups dynamically
  final commandGroups = <String, Command<int>>{};
  final groupMap = <String, List<FlyCommandType>>{};
  for (final entry in commandInstances.entries) {
    final commandType = entry.key;
    final group = commandType.group;
    if (group != null) {
      groupMap.putIfAbsent(group.name, () => []).add(commandType);
    }
  }
  
  // Create group commands
  for (final entry in groupMap.entries) {
    final groupName = entry.key;
    final subcommandTypes = entry.value;
    final groupDescription = subcommandTypes.isNotEmpty
        ? subcommandTypes.first.group?.description
        : null;
    final groupCmd = GroupCommand(groupName, description: groupDescription);
    for (final subcommandType in subcommandTypes) {
      groupCmd.addSubcommand(commandInstances[subcommandType]!);
    }
    commandGroups[groupName] = groupCmd;
  }
  
  return (commandInstances: commandInstances, commandGroups: commandGroups);
}

void main() {
  group('CompletionGenerator', () {
    late CommandMetadataRegistry registry;

    setUp(() {
      registry = CommandMetadataRegistry.instance
        ..clear();

      // Setup test registry with instances-based initialization
      final globalParser = ArgParser()
        ..addFlag('verbose', abbr: 'v', help: 'Enable verbose output')
        ..addOption(
          'output',
          abbr: 'o',
          help: 'Output format',
          allowed: ['human', 'json'],
        );

      final instances = _createCommandInstances();
      registry.initializeFromInstances(
        commandInstances: instances.commandInstances,
        commandGroups: instances.commandGroups,
        globalOptionsParser: globalParser,
      );
    });

    tearDown(() {
      registry.clear();
    });

    group('BashCompletionGenerator', () {
      late BashCompletionGenerator generator;

      setUp(() {
        generator = const BashCompletionGenerator();
      });

      test('has correct shell name', () {
        expect(generator.shellName, equals('bash'));
      });

      test('generates valid bash completion script', () {
        final script = generator.generate(registry);

        expect(script, isNotEmpty);
        expect(script, contains('# Fly CLI bash completion script'));
        expect(script, contains('_fly_completion()'));
        expect(script, contains('complete -F _fly_completion fly'));
      });

      test('includes global options', () {
        final script = generator.generate(registry);

        expect(script, contains('--verbose'));
        expect(script, contains('--output'));
        expect(script, contains('global_opts'));
      });

      test('includes commands', () {
        final script = generator.generate(registry);

        expect(script, contains('create'));
        expect(script, contains('add'));
        expect(script, contains('doctor'));
        expect(script, contains('commands='));
      });

      test('includes command-specific options', () {
        final script = generator.generate(registry);

        expect(script, contains('--template'));
      });

      test('includes subcommands', () {
        final script = generator.generate(registry);

        expect(script, contains('screen'));
        expect(script, contains('service'));
      });

      test('escape handles single quotes', () {
        expect(generator.escape("don't"), equals(r"don'\''t"));
      });

      test('quote wraps text in single quotes', () {
        expect(generator.quote('text'), equals("'text'"));
      });

      test('generateCommandCompletion returns command name', () {
        const command = CommandDefinition(name: 'test', description: 'Test');
        expect(generator.generateCommandCompletion(command), equals('test'));
      });

      test('generateOptionsCompletion returns option names', () {
        final options = [
          const OptionDefinition(name: 'verbose', description: 'Verbose'),
          const OptionDefinition(name: 'output', description: 'Output'),
        ];
        expect(
          generator.generateOptionsCompletion(options),
          equals('--verbose --output'),
        );
      });

      test('generateSubcommandsCompletion returns subcommand names', () {
        final subcommands = [
          const SubcommandDefinition(name: 'screen', description: 'Screen'),
          const SubcommandDefinition(name: 'service', description: 'Service'),
        ];
        expect(
          generator.generateSubcommandsCompletion(subcommands),
          equals('screen service'),
        );
      });

      test('generateOptionValuesCompletion returns allowed values', () {
        const option = OptionDefinition(
          name: 'template',
          description: 'Template',
          allowedValues: ['minimal', 'riverpod'],
        );
        expect(
          generator.generateOptionValuesCompletion(option),
          equals('minimal riverpod'),
        );
      });

      test(
        'generateOptionValuesCompletion returns empty for no allowed values',
        () {
          const option = OptionDefinition(
            name: 'verbose',
            description: 'Verbose',
          );
          expect(generator.generateOptionValuesCompletion(option), equals(''));
        },
      );
    });

    group('ZshCompletionGenerator', () {
      late ZshCompletionGenerator generator;

      setUp(() {
        generator = const ZshCompletionGenerator();
      });

      test('has correct shell name', () {
        expect(generator.shellName, equals('zsh'));
      });

      test('generates valid zsh completion script', () {
        final script = generator.generate(registry);

        expect(script, isNotEmpty);
        expect(script, contains('#compdef fly'));
        expect(script, contains('_fly()'));
        expect(script, contains(r'_fly "$@"'));
      });

      test('includes global options in _arguments', () {
        final script = generator.generate(registry);

        expect(script, contains('--verbose'));
        expect(script, contains('--output'));
      });

      test('includes commands in completion', () {
        final script = generator.generate(registry);

        expect(script, contains('create'));
        expect(script, contains('add'));
        expect(script, contains('doctor'));
      });

      test('generates command-specific functions', () {
        final script = generator.generate(registry);

        expect(script, contains('_fly_add'));
        expect(script, contains('_fly_create'));
      });

      test('escape handles single quotes', () {
        expect(generator.escape("don't"), equals("don''t"));
      });

      test('quote wraps text in single quotes', () {
        expect(generator.quote('text'), equals("'text'"));
      });
    });

    group('FishCompletionGenerator', () {
      late FishCompletionGenerator generator;

      setUp(() {
        generator = const FishCompletionGenerator();
      });

      test('has correct shell name', () {
        expect(generator.shellName, equals('fish'));
      });

      test('generates valid fish completion script', () {
        final script = generator.generate(registry);

        expect(script, isNotEmpty);
        expect(script, contains('# Fly CLI fish completion script'));
        expect(script, contains('complete -c fly'));
      });

      test('includes global options', () {
        final script = generator.generate(registry);

        expect(script, contains('-l verbose'));
        expect(script, contains('-l output'));
      });

      test('includes commands', () {
        final script = generator.generate(registry);

        expect(script, contains('create'));
        expect(script, contains('add'));
        expect(script, contains('doctor'));
      });

      test('includes subcommands with proper conditions', () {
        final script = generator.generate(registry);

        expect(script, contains('screen'));
        expect(script, contains('service'));
        expect(script, contains('__fish_use_subcommand'));
        expect(script, contains('__fish_seen_subcommand_from'));
      });

      test('escape handles special characters', () {
        expect(generator.escape('text with spaces'), equals('text with spaces'));
      });

      test('quote wraps text in double quotes', () {
        expect(generator.quote('text'), equals('"text"'));
      });
    });

    group('PowerShellCompletionGenerator', () {
      late PowerShellCompletionGenerator generator;

      setUp(() {
        generator = const PowerShellCompletionGenerator();
      });

      test('has correct shell name', () {
        expect(generator.shellName, equals('powershell'));
      });

      test('generates valid PowerShell completion script', () {
        final script = generator.generate(registry);

        expect(script, isNotEmpty);
        expect(script, contains('# Fly CLI PowerShell completion script'));
        expect(script, contains('Register-ArgumentCompleter'));
        expect(script, contains('fly'));
      });

      test('includes commands', () {
        final script = generator.generate(registry);

        expect(script, contains('create'));
        expect(script, contains('add'));
        expect(script, contains('doctor'));
      });

      test('includes global options', () {
        final script = generator.generate(registry);

        expect(script, contains('--verbose'));
        expect(script, contains('--output'));
      });

      test('escape handles backticks and quotes', () {
        expect(
          generator.escape("text`with'quotes"),
          equals("text``with''quotes"),
        );
      });

      test('quote wraps text in single quotes', () {
        expect(generator.quote('text'), equals("'text'"));
      });
    });


    group('edge cases', () {
      test('handles empty registry', () {
        final emptyRegistry = _TestCommandMetadataRegistry();
        const generator = BashCompletionGenerator();
        final script = generator.generate(emptyRegistry);

        expect(script, isNotEmpty);
        expect(script, contains('_fly_completion()'));
        expect(script, contains('complete -F _fly_completion fly'));
      });

      test('handles commands with no options or subcommands', () {
        final simpleRegistry = _TestCommandMetadataRegistry();
        simpleRegistry
          ..addCommand(
            'simple',
            const CommandDefinition(
              name: 'simple',
              description: 'Simple command',
            ),
          )
          ..isInitialized = true;

        const generator = BashCompletionGenerator();
        final script = generator.generate(simpleRegistry);

        expect(script, contains('simple'));
        expect(script, isNotEmpty);
      });

      test('handles commands with special characters in names', () {
        final specialRegistry = _TestCommandMetadataRegistry();
        specialRegistry
          ..addCommand(
            'test-command',
            const CommandDefinition(
              name: 'test-command',
              description: 'Test command with dashes',
            ),
          )
          ..isInitialized = true;

        const generator = BashCompletionGenerator();
        final script = generator.generate(specialRegistry);

        expect(script, contains('test-command'));
        expect(script, isNotEmpty);
      });

      test('handles options with special characters in values', () {
        final specialRegistry = _TestCommandMetadataRegistry();
        specialRegistry
          ..addCommand(
            'test',
            const CommandDefinition(
              name: 'test',
              description: 'Test command',
              options: [
                OptionDefinition(
                  name: 'option',
                  description: 'Option with special values',
                  allowedValues: [
                    'value with spaces',
                    'value-with-dashes',
                    'value.with.dots',
                  ],
                ),
              ],
            ),
          )
          ..isInitialized = true;

        const generator = BashCompletionGenerator();
        final script = generator.generate(specialRegistry);

        expect(script, contains('--option'));
        expect(script, isNotEmpty);
      });
    });
  });
}

/// Test implementation of CommandMetadataRegistry for testing
class _TestCommandMetadataRegistry implements CommandMetadataRegistry {
  final Map<String, CommandDefinition> _commands = {};
  final List<OptionDefinition> _globalOptions = [];
  bool _initialized = false;

  void addCommand(String name, CommandDefinition command) {
    _commands[name] = command;
  }

  void addGlobalOptions(List<OptionDefinition> options) {
    _globalOptions.addAll(options);
  }

  @override
  bool get isInitialized => _initialized;

  set isInitialized(bool value) {
    _initialized = value;
  }

  @override
  CommandRegistrationData createAndInitialize({
    required CommandContext context,
    required ArgParser globalOptionsParser,
  }) {
    if (_initialized) {
      return CommandRegistrationData(
        topLevelCommands: {},
        commandGroups: {},
      );
    }
    _initialized = true;
    return CommandRegistrationData(
      topLevelCommands: {},
      commandGroups: {},
    );
  }

  @override
  void initializeFromInstances({
    required Map<FlyCommandType, Command<int>> commandInstances,
    required Map<String, Command<int>> commandGroups,
    required ArgParser globalOptionsParser,
  }) {
    if (_initialized) {
      return;
    }
    _initialized = true;
  }

  @override
  bool hasCommand(String name) => _commands.containsKey(name);

  @override
  CommandDefinition? getCommand(String name) => _commands[name];

  @override
  Map<String, CommandDefinition> getAllCommands() =>
      Map.unmodifiable(_commands);

  @override
  List<String> getCommandNames() => _commands.keys.toList();

  @override
  List<SubcommandDefinition> getSubcommands(String commandName) {
    final command = _commands[commandName];
    return command?.subcommands ?? [];
  }

  @override
  List<OptionDefinition> getGlobalOptions() =>
      List.unmodifiable(_globalOptions);

  @override
  Map<String, dynamic> toJson() => {
        'commands': _commands.map((k, v) => MapEntry(k, v.toJson())),
        'global_options': _globalOptions.map((o) => o.toJson()).toList(),
      };

  @override
  void clear() {
    _commands.clear();
    _globalOptions.clear();
    _initialized = false;
  }
}

/// Test command implementation for testing
class _TestCommand extends Command<int> {
  _TestCommand(this._name, this._description);

  final String _name;
  final String _description;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  ArgParser get argParser => ArgParser();

  @override
  Future<int> run() async => 0;
}

class _TestCommandWithOptions extends Command<int> {
  _TestCommandWithOptions(this._name, this._description, this._options);

  final String _name;
  final String _description;
  final List<OptionDefinition> _options;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  ArgParser get argParser {
    final parser = ArgParser();
    for (final option in _options) {
      if (option.type == OptionType.flag) {
        parser.addFlag(
          option.name,
          abbr: option.short,
          help: option.description,
        );
      } else {
        parser.addOption(
          option.name,
          abbr: option.short,
          help: option.description,
          allowed: option.allowedValues,
        );
      }
    }
    return parser;
  }

  @override
  Future<int> run() async => 0;
}

class _TestCommandWithSubcommands extends Command<int> {
  _TestCommandWithSubcommands(this._name, this._description, this._subcommands) {
    // Add subcommands to the command
    for (final subcommandDef in _subcommands) {
      addSubcommand(_TestCommand(subcommandDef.name, subcommandDef.description));
    }
  }

  final String _name;
  final String _description;
  final List<SubcommandDefinition> _subcommands;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  ArgParser get argParser => ArgParser();

  @override
  Future<int> run() async => 0;
}
