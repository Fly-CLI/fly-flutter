import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/global_flags_registry.dart';
import 'package:fly_cli/src/features/commands/application/command_base.dart'
    as base show FlyCommand;
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/domain/command_metadata.dart';
import 'package:fly_cli/src/features/commands/domain/fly_command.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';

/// Helper to create command instances from enum for testing
({
  Map<FlyCommand, Command<int>> commandInstances,
  Map<String, Command<int>> commandGroups,
}) _createCommandInstances() {
  final context = CommandTestHelper.createMockCommandContext();
  final commandInstances = <FlyCommand, Command<int>>{};

  // Create instances for all command types
  for (final commandType in FlyCommand.values) {
    commandInstances[commandType] = commandType.createInstance(context);
  }

  // Build command groups dynamically
  final commandGroups = <String, Command<int>>{};
  final groupMap = <String, List<FlyCommand>>{};
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

        final command =
            _TestFlyCommandWithMetadata('test', 'Test command', metadata);
        expect(command.metadata, isNotNull);
        expect(command.metadata!.name, equals('test'));
        expect(command.metadata!.examples, hasLength(1));
      });
    });

    group('metadata extraction integration', () {
      test('extracts metadata from FlyCommand without manual metadata', () {
        final command = _TestFlyCommand(
          'create',
          'Create a new project',
          flags: const [CreateTemplateFlag()],
        );
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('create'));
        expect(metadata.description, equals('Create a new project'));
        expect(metadata.options, hasLength(1));
        expect(metadata.options.first.name, equals('template'));
        expect(metadata.globalOptions, isNotEmpty);
        expect(metadata.subcommands, isEmpty);
      });

      test('uses manual metadata when available', () {
        const manualMetadata = CommandDefinition(
          name: 'create',
          description: 'Create a new Flutter project',
          examples: [
            CommandExample(
              command: 'fly create my_app --template=fly_foundation',
              description: 'Create a fly_foundation project',
            ),
          ],
          options: [
            CreateTemplateFlag(),
          ],
        );

        final command = _TestFlyCommandWithMetadata(
          'create',
          'Create command',
          manualMetadata,
          flags: const [CreateOrganizationFlag()],
        );
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('create'));
        expect(metadata.description, equals('Create a new Flutter project'));
        expect(metadata.examples, hasLength(1));
        expect(metadata.options, hasLength(2));
        expect(metadata.options.any((o) => o.name == 'template'), isTrue);
        expect(metadata.options.any((o) => o.name == 'organization'), isTrue);
      });

      test('merges manual metadata with command flags', () {
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

        final command = _TestFlyCommandWithMetadata(
          'create',
          'Create command',
          manualMetadata,
          flags: const [
            CreateTemplateFlag(),
            CreateOrganizationFlag(),
          ],
        );
        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('create'));
        expect(metadata.description, equals('Create a new Flutter project'));
        expect(metadata.examples, hasLength(1));
        expect(metadata.options, hasLength(2));
        expect(metadata.options.where((o) => o.name == 'template'), hasLength(1));
        expect(metadata.options.any((o) => o.name == 'organization'), isTrue);
      });
    });

    group('registry integration', () {
      test('registers FlyCommand in registry', () {
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: GlobalFlagsRegistry.globalFlags,
        );

        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);

        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.name, equals('create'));
        expect(
            createCommand.description, equals('Create a new Flutter project'));
      });

      test('registers FlyCommand with manual metadata', () {
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: GlobalFlagsRegistry.globalFlags,
        );

        // Create command has manual metadata defined
        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.name, equals('create'));
        // Create command should have metadata with examples
        expect(createCommand.description, isNotEmpty);
      });

      test('handles commands from enum correctly', () {
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: GlobalFlagsRegistry.globalFlags,
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
        final parentCommand = _TestFlyCommand('generate', 'Generate components');
        parentCommand.addSubcommand(_TestFlyCommand('screen', 'Generate a screen'));
        parentCommand
            .addSubcommand(_TestFlyCommand('service', 'Generate a service'));

        const extractor = MetadataExtractor();
        final metadata = extractor.extractMetadata(parentCommand);

        expect(metadata.subcommands, hasLength(2));
        expect(metadata.subcommands.any((s) => s.name == 'screen'), isTrue);
        expect(metadata.subcommands.any((s) => s.name == 'service'), isTrue);
      });

      test('registers subcommands in registry', () {
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: GlobalFlagsRegistry.globalFlags,
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
        final instances = _createCommandInstances();

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: GlobalFlagsRegistry.globalFlags,
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

        final command = _TestFlyCommandWithMetadata(
            'valid-name', 'Valid command', invalidMetadata);
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

        final command = _TestFlyCommandWithMetadata(
            'create', 'Create command', mixedMetadata);
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
class _TestFlyCommand extends base.FlyCommand {
  _TestFlyCommand(
    this._name,
    this._description, {
    List<CliFlag>? flags,
  })  : _flags = flags ?? const [],
        super(CommandTestHelper.createMockCommandContext());

  final String _name;
  final String _description;
  final List<CliFlag> _flags;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  List<CliFlag> get flags => _flags;

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
  _TestFlyCommandWithMetadata(
    super.name,
    super.description,
    this._metadata, {
    super.flags,
  });

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
