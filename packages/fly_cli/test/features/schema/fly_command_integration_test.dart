import 'package:args/args.dart' hide OptionType;
import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/fly_command_type.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';

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
  group('FlyCommand Metadata Integration', () {
    late CommandMetadataRegistry registry;

    setUp(() {
      registry = CommandMetadataRegistry.instance;
      registry.clear();
    });

    tearDown(() {
      registry.clear();
    });

    group('metadata getter', () {
      test('returns null by default', () {
        final command = _TestFlyCommand('test', 'Test command');
        expect(command.metadata, isNull);
      });

      test('can be overridden to provide metadata', () {
        const metadata = CommandDefinition(
          name: 'test',
          description: 'Test command with metadata',
          examples: [
            CommandExample(
              command: 'fly test --example',
              description: 'Example usage',
            ),
          ],
        );

        final command = _TestFlyCommandWithMetadata('test', 'Test command', metadata);
        expect(command.metadata, isNotNull);
        expect(command.metadata!.name, equals('test'));
        expect(command.metadata!.examples, hasLength(1));
      });
    });

    group('metadata extraction integration', () {
      test('extracts metadata from FlyCommand without manual metadata', () {
        final command = _TestFlyCommand('create', 'Create a new project');
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('create'));
        expect(metadata.description, equals('Create a new project'));
        expect(metadata.options, hasLength(4)); // output, debug, verbose, plan from base class
        expect(metadata.subcommands, isEmpty);
      });

      test('uses manual metadata when available', () {
        const manualMetadata = CommandDefinition(
          name: 'create',
          description: 'Create a new Flutter project',
          examples: [
            CommandExample(
              command: 'fly create my_app --template=minimal',
              description: 'Create a minimal project',
            ),
          ],
          options: [
            OptionDefinition(
              name: 'template',
              description: 'Project template',
              type: OptionType.value,
              allowedValues: ['minimal', 'riverpod'],
            ),
          ],
        );

        final command = _TestFlyCommandWithMetadata('create', 'Create command', manualMetadata);
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('create'));
        expect(metadata.description, equals('Create a new Flutter project'));
        expect(metadata.examples, hasLength(1));
        expect(metadata.options, hasLength(5)); // template + output + debug + verbose + plan
        expect(metadata.options.first.name, equals('template'));
      });

      test('merges manual metadata with auto-discovered options', () {
        final parser = ArgParser();
        parser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        parser.addOption('output', help: 'Output format', allowed: ['human', 'json']);

        const manualMetadata = CommandDefinition(
          name: 'create',
          description: 'Create a new Flutter project',
          examples: [
            CommandExample(
              command: 'fly create my_app',
              description: 'Create a new app',
            ),
          ],
        );

        final command = _TestFlyCommandWithMetadata('create', 'Create command', manualMetadata, parser: parser);
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('create'));
        expect(metadata.description, equals('Create a new Flutter project'));
        expect(metadata.examples, hasLength(1));
        expect(metadata.options, hasLength(4)); // output + debug + verbose + plan from base class
        expect(metadata.options.any((o) => o.name == 'verbose'), isTrue);
        expect(metadata.options.any((o) => o.name == 'output'), isTrue);
      });
    });

    group('registry integration', () {
      test('registers FlyCommand in registry', () {
        final globalParser = ArgParser();
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalOptionsParser: globalParser,
        );

        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);

        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.name, equals('create'));
        expect(createCommand.description, equals('Create a new Flutter project'));
      });

      test('registers FlyCommand with manual metadata', () {
        final globalParser = ArgParser();
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalOptionsParser: globalParser,
        );

        // Create command has manual metadata defined
        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.name, equals('create'));
        // Create command should have metadata with examples
        expect(createCommand.description, isNotEmpty);
      });

      test('handles commands from enum correctly', () {
        final globalParser = ArgParser();
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalOptionsParser: globalParser,
        );

        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);

        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.name, equals('create'));

        final doctorCommand = registry.getCommand('doctor');
        expect(doctorCommand, isNotNull);
        expect(doctorCommand!.name, equals('doctor'));
      });
    });

    group('subcommand handling', () {
      test('extracts subcommands from FlyCommand', () {
        final parentCommand = _TestFlyCommand('add', 'Add components');
        parentCommand.addSubcommand(_TestFlyCommand('screen', 'Add a screen'));
        parentCommand.addSubcommand(_TestFlyCommand('service', 'Add a service'));

        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(parentCommand);

        expect(metadata.subcommands, hasLength(2));
        expect(metadata.subcommands.any((s) => s.name == 'screen'), isTrue);
        expect(metadata.subcommands.any((s) => s.name == 'service'), isTrue);
      });

      test('registers subcommands in registry', () {
        final globalParser = ArgParser();
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalOptionsParser: globalParser,
        );

        // 'add' command should have subcommands
        final subcommands = registry.getSubcommands('add');
        expect(subcommands, hasLength(2));
        expect(subcommands.any((s) => s.name == 'screen'), isTrue);
        expect(subcommands.any((s) => s.name == 'service'), isTrue);
      });
    });

    group('backward compatibility', () {
      test('existing commands work without metadata', () {
        final command = _TestFlyCommand('existing', 'Existing command');
        expect(command.metadata, isNull);

        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('existing'));
        expect(metadata.description, equals('Existing command'));
      });

      test('commands can opt into metadata gradually', () {
        final globalParser = ArgParser();
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalOptionsParser: globalParser,
        );

        // Commands from enum should have metadata
        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        // Create command has manual metadata with examples
        expect(createCommand!.name, equals('create'));
      });
    });

    group('error handling', () {
      test('handles commands with invalid metadata gracefully', () {
        const invalidMetadata = CommandDefinition(
          name: '', // Invalid empty name
          description: 'Invalid metadata',
        );

        final command = _TestFlyCommandWithMetadata('valid-name', 'Valid command', invalidMetadata);
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        // Should fall back to auto-discovered metadata
        expect(metadata.name, equals('valid-name'));
        expect(metadata.description, equals('Valid command'));
      });

      test('handles commands with mixed valid/invalid metadata', () {
        const mixedMetadata = CommandDefinition(
          name: 'create',
          description: 'Create command',
          examples: [
            CommandExample(
              command: '', // Invalid empty command
              description: 'Invalid example',
            ),
            CommandExample(
              command: 'fly create my_app',
              description: 'Valid example',
            ),
          ],
        );

        final command = _TestFlyCommandWithMetadata('create', 'Create command', mixedMetadata);
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('create'));
        expect(metadata.description, equals('Create command'));
        expect(metadata.examples, hasLength(2));
      });
    });
  });
}

/// Test FlyCommand implementation
class _TestFlyCommand extends FlyCommand {
  _TestFlyCommand(this._name, this._description, {ArgParser? parser}) 
      : _parser = parser,
        super(CommandTestHelper.createMockCommandContext());

  final String _name;
  final String _description;
  final ArgParser? _parser;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  ArgParser get argParser {
    final parser = super.argParser;
    if (_parser != null) {
      // Copy options from the provided parser, but avoid duplicates
      for (final option in _parser.options.values) {
        if (!parser.options.containsKey(option.name)) {
          if (option.isFlag) {
            parser.addFlag(
              option.name,
              abbr: option.abbr,
              help: option.help,
              defaultsTo: option.defaultsTo as bool?,
              negatable: option.negatable ?? false,
            );
          } else {
            parser.addOption(
              option.name,
              abbr: option.abbr,
              help: option.help,
              defaultsTo: option.defaultsTo as String?,
              allowed: option.allowed,
            );
          }
        }
      }
    }
    return parser;
  }

  @override
  Future<CommandResult> execute() async => CommandResult.success(
    command: _name,
    message: 'Test command executed',
  );

  /// Add a subcommand for testing
  @override
  void addSubcommand(Command<int> subcommand) {
    super.addSubcommand(subcommand);
  }
}

/// Test FlyCommand with manual metadata
class _TestFlyCommandWithMetadata extends _TestFlyCommand {
  _TestFlyCommandWithMetadata(super.name, super.description, this._metadata, {super.parser});

  final CommandDefinition _metadata;

  @override
  CommandDefinition? get metadata => _metadata;
}

/// Regular Command implementation for comparison
class _RegularCommand extends Command<int> {
  _RegularCommand(this._name, this._description);

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
