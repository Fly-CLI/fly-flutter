import 'package:args/args.dart' hide OptionType;
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/features/schema/domain/command_definition.dart';
import 'package:fly_cli/src/features/schema/domain/command_registry.dart';
import 'package:test/test.dart';

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

      test('initializes with CommandRunner', () {
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.argParser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        
        final command = _TestCommand('create', 'Create a new project');
        runner.addCommand(command);

        registry.initialize(runner);

        expect(registry.isInitialized, isTrue);
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.getGlobalOptions(), hasLength(2)); // help, verbose
      });

      test('does not reinitialize if already initialized', () {
        final runner1 = CommandRunner<int>('test1', 'Test runner 1');
        runner1.addCommand(_TestCommand('create', 'Create command'));
        
        final runner2 = CommandRunner<int>('test2', 'Test runner 2');
        runner2.addCommand(_TestCommand('doctor', 'Doctor command'));

        registry.initialize(runner1);
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isFalse);

        registry.initialize(runner2);
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isFalse);
      });
    });

    group('command queries', () {
      setUp(() {
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.argParser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        runner.argParser.addOption('output', help: 'Output format', allowed: ['human', 'json']);
        
        runner.addCommand(_TestCommand('create', 'Create a new project'));
        runner.addCommand(_TestCommand('doctor', 'Check system setup'));
        runner.addCommand(_TestCommand('version', 'Show version'));

        registry.initialize(runner);
      });

      test('getCommand returns correct command', () {
        final createCommand = registry.getCommand('create');
        expect(createCommand, isNotNull);
        expect(createCommand!.name, equals('create'));
        expect(createCommand.description, equals('Create a new project'));

        final doctorCommand = registry.getCommand('doctor');
        expect(doctorCommand, isNotNull);
        expect(doctorCommand!.name, equals('doctor'));
        expect(doctorCommand.description, equals('Check system setup'));
      });

      test('getCommand returns null for non-existent command', () {
        final nonExistent = registry.getCommand('non-existent');
        expect(nonExistent, isNull);
      });

      test('getAllCommands returns all commands', () {
        final allCommands = registry.getAllCommands();
        expect(allCommands, hasLength(4)); // help, create, doctor, version
        expect(allCommands.keys, containsAll(['create', 'doctor', 'version']));
      });

      test('getCommandNames returns all command names', () {
        final commandNames = registry.getCommandNames();
        expect(commandNames, hasLength(4)); // help, create, doctor, version
        expect(commandNames, containsAll(['create', 'doctor', 'version']));
      });

      test('hasCommand returns correct values', () {
        expect(registry.hasCommand('create'), isTrue);
        expect(registry.hasCommand('doctor'), isTrue);
        expect(registry.hasCommand('version'), isTrue);
        expect(registry.hasCommand('non-existent'), isFalse);
      });

      test('getSubcommands returns subcommands for command', () {
        final runner = CommandRunner<int>('test', 'Test runner');
        final addCommand = _TestCommand('add', 'Add components');
        addCommand.addSubcommand(_TestCommand('screen', 'Add a screen'));
        addCommand.addSubcommand(_TestCommand('service', 'Add a service'));
        runner.addCommand(addCommand);

        registry.clear();
        registry.initialize(runner);

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
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.argParser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        runner.argParser.addFlag('quiet', abbr: 'q', help: 'Suppress output');
        runner.argParser.addOption('output', help: 'Output format', allowed: ['human', 'json']);
        runner.argParser.addOption('plan', help: 'Show execution plan');

        registry.initialize(runner);
      });

      test('getGlobalOptions returns all global options', () {
        final globalOptions = registry.getGlobalOptions();
        expect(globalOptions, hasLength(5)); // help, verbose, quiet, output, plan

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
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.argParser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        
        final command = _TestCommand('create', 'Create a new project');
        runner.addCommand(command);

        registry.initialize(runner);
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
        expect(createCommand['description'], equals('Create a new project'));

        final globalOptions = json['global_options'] as List<dynamic>;
        expect(globalOptions, hasLength(2)); // help, verbose

        final verboseOption = globalOptions.firstWhere((o) => o['name'] == 'verbose') as Map<String, dynamic>;
        expect(verboseOption['name'], equals('verbose'));
        expect(verboseOption['short'], equals('v'));
      });
    });

    group('clear', () {
      test('clears all metadata and resets initialization state', () {
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.addCommand(_TestCommand('create', 'Create command'));
        registry.initialize(runner);

        expect(registry.isInitialized, isTrue);
        expect(registry.hasCommand('create'), isTrue);

        registry.clear();

        expect(registry.isInitialized, isFalse);
        expect(registry.hasCommand('create'), isFalse);
        expect(registry.getAllCommands(), isEmpty);
        expect(registry.getGlobalOptions(), isEmpty);
      });
    });

    group('edge cases', () {
      test('handles CommandRunner with no commands', () {
        final runner = CommandRunner<int>('test', 'Test runner');
        registry.initialize(runner);

        expect(registry.isInitialized, isTrue);
        expect(registry.getAllCommands(), hasLength(1)); // help command is always added
        expect(registry.getCommandNames(), hasLength(1));
      });

      test('handles CommandRunner with no global options', () {
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.addCommand(_TestCommand('create', 'Create command'));
        registry.initialize(runner);

        expect(registry.getGlobalOptions(), hasLength(1)); // help is always added
      });

      test('handles commands with complex option configurations', () {
        final parser = ArgParser();
        parser.addFlag('flag1', abbr: 'f', help: 'Flag option');
        parser.addOption('option1', abbr: 'o', help: 'Option with allowed values', allowed: ['a', 'b', 'c']);
        parser.addOption('option2', help: 'Option with default', defaultsTo: 'default');
        parser.addMultiOption('multi', help: 'Multi-value option');

        final command = _TestCommand('complex', 'Complex command', parser: parser);
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.addCommand(command);
        registry.initialize(runner);

        final metadata = registry.getCommand('complex');
        expect(metadata, isNotNull);
        expect(metadata!.options, hasLength(5)); // flag1, option1, option2, multi, help

        final flagOption = metadata.options.firstWhere((o) => o.name == 'flag1');
        expect(flagOption.type, equals(OptionType.flag));
        expect(flagOption.short, equals('f'));

        final option1 = metadata.options.firstWhere((o) => o.name == 'option1');
        expect(option1.type, equals(OptionType.value));
        expect(option1.allowedValues, equals(['a', 'b', 'c']));

        final option2 = metadata.options.firstWhere((o) => o.name == 'option2');
        expect(option2.defaultValue, equals('default'));

        final multiOption = metadata.options.firstWhere((o) => o.name == 'multi');
        expect(multiOption.type, equals(OptionType.value)); // ArgParser doesn't distinguish multi-options
      });
    });
  });
}

/// Test command implementation for testing
class _TestCommand extends Command<int> {
  _TestCommand(this._name, this._description, {ArgParser? parser}) : _parser = parser;

  final String _name;
  final String _description;
  final ArgParser? _parser;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  ArgParser get argParser => _parser ?? ArgParser();

  @override
  Future<int> run() async => 0;
}
