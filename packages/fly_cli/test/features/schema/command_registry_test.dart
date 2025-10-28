import 'package:args/args.dart' hide OptionType;
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_metadata/infrastructure/command_context_factory.dart';
import 'package:test/test.dart';

/// Helper to create a test context for registry initialization
CommandContext _createTestContext() => CommandContextFactory.createForMetadataExtraction();

/// Helper to create a test global options parser
ArgParser _createTestGlobalOptionsParser() {
  final parser = ArgParser();
  parser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
  parser.addFlag('quiet', abbr: 'q', help: 'Suppress output');
  parser.addOption('output', help: 'Output format', allowed: ['human', 'json']);
  return parser;
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

      test('initializes with enum-based approach', () {
        final context = _createTestContext();
        final globalParser = _createTestGlobalOptionsParser();

        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );

        expect(registry.isInitialized, isTrue);
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);
        expect(registry.getGlobalOptions().length, greaterThanOrEqualTo(3)); // verbose, quiet, output
      });

      test('does not reinitialize if already initialized', () {
        final context = _createTestContext();
        final globalParser = _createTestGlobalOptionsParser();

        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );

        expect(registry.isInitialized, isTrue);
        final initialCommands = registry.getAllCommands().keys.toList();

        // Try to initialize again
        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );

        // Should still have same commands
        expect(registry.isInitialized, isTrue);
        expect(registry.getAllCommands().keys.toList(), equals(initialCommands));
      });
    });

    group('command queries', () {
      setUp(() {
        final context = _createTestContext();
        final globalParser = _createTestGlobalOptionsParser();

        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );
      });

      test('getCommand returns correct command', () {
        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.name, equals('create'));

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
        expect(allCommands.keys, containsAll(['create', 'doctor', 'version']));
      });

      test('getCommandNames returns all command names', () {
        final commandNames = registry.getCommandNames();
        expect(commandNames, isNotEmpty);
        expect(commandNames, containsAll(['create', 'doctor', 'version']));
      });

      test('hasCommand returns correct values', () {
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);
        expect(registry.hasCommand('version'), isTrue);
        expect(registry.hasCommand('non-existent'), isFalse);
      });

      test('getSubcommands returns subcommands for add command', () {
        final subcommands = registry.getSubcommands('add');
        expect(subcommands, hasLength(2));
        expect(subcommands.map((s) => s.name), containsAll(['screen', 'service']));
      });

      test('getSubcommands returns empty list for command without subcommands', () {
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
        final globalParser = _createTestGlobalOptionsParser();

        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );
      });

      test('getGlobalOptions returns all global options', () {
        final globalOptions = registry.getGlobalOptions();
        expect(globalOptions.length, greaterThanOrEqualTo(3));

        final verboseOption = globalOptions.firstWhere((o) => o.name == 'verbose');
        expect(verboseOption.type, equals(OptionType.flag));
        expect(verboseOption.short, equals('v'));
        expect(verboseOption.isGlobal, isTrue);

        final outputOption = globalOptions.firstWhere((o) => o.name == 'output');
        expect(outputOption.type, equals(OptionType.value));
        expect(outputOption.allowedValues, equals(['human', 'json']));
        expect(outputOption.isGlobal, isTrue);
      });
    });

    group('JSON export', () {
      setUp(() {
        final context = _createTestContext();
        final globalParser = _createTestGlobalOptionsParser();

        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );
      });

      test('toJson exports complete metadata', () {
        final json = registry.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('commands'), isTrue);
        expect(json.containsKey('global_options'), isTrue);

        final commands = json['commands'] as Map<String, dynamic>;
        expect(commands.containsKey('create'), isTrue);

        final createCommand = commands['create'] as Map<String, dynamic>;
        expect(createCommand['name'], equals('create'));

        final globalOptions = json['global_options'] as List<dynamic>;
        expect(globalOptions.length, greaterThanOrEqualTo(3));

        final verboseOption = globalOptions.firstWhere((o) => o['name'] == 'verbose') as Map<String, dynamic>;
        expect(verboseOption['name'], equals('verbose'));
        expect(verboseOption['short'], equals('v'));
      });
    });

    group('clear', () {
      test('clears all metadata and resets initialization state', () {
        final context = _createTestContext();
        final globalParser = _createTestGlobalOptionsParser();

        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );

        expect(registry.isInitialized, isTrue);
        expect(registry.hasCommand('create'), isTrue);

        registry.clear();

        expect(registry.isInitialized, isFalse);
        // After clearing, need to initialize again
        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: globalParser,
        );
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.isInitialized, isTrue);
      });
    });

    group('edge cases', () {
      test('handles initialization with minimal global options', () {
        final context = _createTestContext();
        final minimalParser = ArgParser();

        registry.initializeFromEnum(
          context: context,
          globalOptionsParser: minimalParser,
        );

        expect(registry.isInitialized, isTrue);
        expect(registry.getAllCommands(), isNotEmpty);
      });
    });
  });
}
