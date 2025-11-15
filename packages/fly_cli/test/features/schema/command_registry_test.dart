import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/foundation/flags/global_flags_registry.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/metadata/command_metadata.dart';
import 'package:fly_cli/src/core/definitions/fly_command.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';

/// Helper to create a test context for registry initialization
CommandContext _createTestContext() =>
    CommandTestHelper.createMockCommandContext();

List<CliFlag> _testGlobalFlags() => GlobalFlagsRegistry.globalFlags;

/// Helper to create command instances from enum for testing
({
  Map<FlyCommand, Command<int>> commandInstances,
  Map<String, Command<int>> commandGroups,
}) _createCommandInstances(CommandContext context) {
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
  group('CommandMetadataRegistry', () {
    late CommandMetadataRegistry registry;

    setUp(() {
      registry = CommandMetadataRegistry.instance;
      registry.clear(); // Clear any existing state
    });

    tearDown(() {
      registry.clear();
    });

    group('singleton behavior', () {
      test('returns same instance', () {
        final instance1 = CommandMetadataRegistry.instance;
        final instance2 = CommandMetadataRegistry.instance;

        expect(instance1, same(instance2));
      });
    });

    group('initialization', () {
      test('is not initialized by default', () {
        expect(registry.isInitialized, isFalse);
      });

      test('initializes with instances-based approach', () {
        final context = _createTestContext();
        final globalFlags = _testGlobalFlags();
        final instances = _createCommandInstances(context);

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );

        expect(registry.isInitialized, isTrue);
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);
        expect(registry.getGlobalOptions().length,
            greaterThanOrEqualTo(3)); // verbose, quiet, output
      });

      test('does not reinitialize if already initialized', () {
        final context = _createTestContext();
        final globalFlags = _testGlobalFlags();
        final instances = _createCommandInstances(context);

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );

        expect(registry.isInitialized, isTrue);
        final initialCommands = registry.getAllCommands().keys.toList();

        // Try to initialize again
        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );

        // Should still have same commands
        expect(registry.isInitialized, isTrue);
        expect(
            registry.getAllCommands().keys.toList(), equals(initialCommands));
      });
    });

    group('command queries', () {
      setUp(() {
        final context = _createTestContext();
        final globalFlags = _testGlobalFlags();
        final instances = _createCommandInstances(context);

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );
      });

      test('getCommand returns correct command', () {
        final projectCommand = registry.getCommand('create');
        expect(projectCommand, isNotNull);
        expect(projectCommand!.name, equals('project'));

        final doctorCommand = registry.getCommand('doctor');
        expect(doctorCommand, isNotNull);
        expect(doctorCommand!.name, equals('doctor'));
      });

      test('getCommand returns null for non-existent command', () {
        final nonExistent = registry.getCommand('non-existent');
        expect(nonExistent, isNull);
      });

      test('getAllCommands returns all commands', () {
        final allCommands = registry.getAllCommands();
        expect(allCommands, isNotEmpty);
        expect(
          allCommands.keys,
          containsAll(['version', 'doctor', 'completion', 'generate', 'ai', 'mcp']),
        );
      });

      test('getCommandNames returns all command names', () {
        final commandNames = registry.getCommandNames();
        expect(commandNames, isNotEmpty);
        expect(
          commandNames,
          containsAll(['version', 'doctor', 'completion', 'generate', 'ai', 'mcp']),
        );
      });

      test('hasCommand returns correct values', () {
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);
        expect(registry.hasCommand('version'), isTrue);
        expect(registry.hasCommand('non-existent'), isFalse);
      });

      test('getSubcommands returns subcommands for generate group', () {
        final subcommands = registry.getSubcommands('generate');
        expect(subcommands, hasLength(3));
        expect(
          subcommands.map((s) => s.name),
          containsAll(['project', 'screen', 'service']),
        );
      });

      test('getSubcommands returns empty list for command without subcommands',
          () {
        final subcommands = registry.getSubcommands('create');
        expect(subcommands, isEmpty);
      });

      test('getSubcommands returns empty list for non-existent command', () {
        final subcommands = registry.getSubcommands('non-existent');
        expect(subcommands, isEmpty);
      });
    });

    group('global options', () {
      setUp(() {
        final context = _createTestContext();
        final globalFlags = _testGlobalFlags();
        final instances = _createCommandInstances(context);

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );
      });

      test('getGlobalOptions returns all global options', () {
        final globalOptions = registry.getGlobalOptions();
        expect(globalOptions.length, greaterThanOrEqualTo(3));

        final verboseOption =
            globalOptions.firstWhere((o) => o.name == 'verbose');
        expect(verboseOption.type, equals(FlagType.boolean));
        expect(verboseOption.abbreviation, equals('v'));
        expect(verboseOption.isGlobal, isTrue);

        final outputOption =
            globalOptions.firstWhere((o) => o.name == 'format');
        expect(outputOption.type, equals(FlagType.singleValue));
        expect(outputOption.allowedValues, equals(['human', 'json', 'ai']));
        expect(outputOption.isGlobal, isTrue);
      });
    });

    group('JSON export', () {
      setUp(() {
        final context = _createTestContext();
        final globalFlags = _testGlobalFlags();
        final instances = _createCommandInstances(context);

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );
      });

      test('toJson exports complete metadata', () {
        final json = registry.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('commands'), isTrue);
        expect(json.containsKey('global_options'), isTrue);

        final commands = json['commands'] as Map<String, dynamic>;
        expect(commands.containsKey('version'), isTrue);

        final versionCommand = commands['version'] as Map<String, dynamic>;
        expect(versionCommand['name'], equals('version'));

        final globalOptions = json['global_options'] as List<dynamic>;
        expect(globalOptions.length, greaterThanOrEqualTo(3));

        final verboseOption = globalOptions
            .firstWhere((o) => o['name'] == 'verbose') as Map<String, dynamic>;
        expect(verboseOption['name'], equals('verbose'));
        expect(verboseOption['abbreviation'], equals('v'));
      });
    });

    group('clear', () {
      test('clears all metadata and resets initialization state', () {
        final context = _createTestContext();
        final globalFlags = _testGlobalFlags();
        final instances = _createCommandInstances(context);

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );

        expect(registry.isInitialized, isTrue);
        expect(registry.hasCommand('create'), isTrue);

        registry.clear();

        expect(registry.isInitialized, isFalse);
        // After clearing, need to initialize again
        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: globalFlags,
        );
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.isInitialized, isTrue);
      });
    });

    group('edge cases', () {
      test('handles initialization with minimal global options', () {
        final context = _createTestContext();
        final minimalFlags = const [GlobalHelpFlag()];
        final instances = _createCommandInstances(context);

        registry.initializeFromInstances(
          commandInstances: instances.commandInstances,
          commandGroups: instances.commandGroups,
          globalFlags: minimalFlags,
        );

        expect(registry.isInitialized, isTrue);
        expect(registry.getAllCommands(), isNotEmpty);
      });
    });
  });
}
