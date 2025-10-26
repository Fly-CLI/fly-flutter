import 'package:args/args.dart' hide OptionType;
import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/features/schema/domain/command_definition.dart';
import 'package:fly_cli/src/features/schema/infrastructure/metadata_extractor.dart';
import 'package:test/test.dart';

import '../../helpers/command_test_helper.dart';


void main() {
  group('MetadataExtractor', () {
    late MetadataExtractor extractor;

    setUp(() {
      extractor = const MetadataExtractor();
    });

    group('extractMetadata', () {
      test('extracts basic command metadata', () {
        final command = _TestCommand('test', 'Test command');
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('test'));
        expect(metadata.description, equals('Test command'));
        expect(metadata.options, isEmpty);
        expect(metadata.subcommands, isEmpty);
        expect(metadata.globalOptions, isEmpty);
      });

      test('extracts command with options', () {
        final parser = ArgParser();
        parser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        parser.addOption('output', abbr: 'o', help: 'Output format', allowed: ['human', 'json']);

        final command = _TestCommand('test', 'Test command', parser: parser);
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('test'));
        expect(metadata.description, equals('Test command'));
        expect(metadata.options, hasLength(3)); // verbose, output, help

        final verboseOption = metadata.options.firstWhere((o) => o.name == 'verbose');
        expect(verboseOption.description, equals('Enable verbose output'));
        expect(verboseOption.short, equals('v'));
        expect(verboseOption.type, equals(OptionType.flag));

        final outputOption = metadata.options.firstWhere((o) => o.name == 'output');
        expect(outputOption.description, equals('Output format'));
        expect(outputOption.short, equals('o'));
        expect(outputOption.type, equals(OptionType.value));
        expect(outputOption.allowedValues, equals(['human', 'json']));
      });

      test('extracts command with subcommands', () {
        final command = _TestCommand('test', 'Test command');
        command.addSubcommand(_TestCommand('sub1', 'First subcommand'));
        command.addSubcommand(_TestCommand('sub2', 'Second subcommand'));

        final metadata = extractor.extractMetadata(command);

        expect(metadata.subcommands, hasLength(2));

        final sub1 = metadata.subcommands.firstWhere((s) => s.name == 'sub1');
        expect(sub1.description, equals('First subcommand'));

        final sub2 = metadata.subcommands.firstWhere((s) => s.name == 'sub2');
        expect(sub2.description, equals('Second subcommand'));
      });

      test('merges with global options', () {
        final globalOptions = [
          const OptionDefinition(
            name: 'verbose',
            description: 'Global verbose option',
            isGlobal: true,
          ),
        ];

        final command = _TestCommand('test', 'Test command');
        final metadata = extractor.extractMetadata(command, globalOptions);

        expect(metadata.globalOptions, hasLength(1));
        expect(metadata.globalOptions.first.name, equals('verbose'));
        expect(metadata.globalOptions.first.isGlobal, isTrue);
      });

      test('handles command with manual metadata', () {
        const manualMetadata = CommandDefinition(
          name: 'test',
          description: 'Manual metadata',
          examples: [
            CommandExample(
              command: 'fly test --example',
              description: 'Example usage',
            ),
          ],
        );

        final command = _TestCommandWithMetadata('test', 'Test command', manualMetadata);
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('test'));
        expect(metadata.description, equals('Manual metadata')); // Manual metadata is used
        expect(metadata.examples, hasLength(1));
        expect(metadata.examples.first.command, equals('fly test --example'));
        expect(metadata.globalOptions, isEmpty); // Manual metadata doesn't have global options
      });
    });

    group('_extractOptions', () {
      test('extracts flag options', () {
        final parser = ArgParser();
        parser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        parser.addFlag('quiet', help: 'Suppress output');

        final command = _TestCommand('test', 'Test command', parser: parser);
        final metadata = extractor.extractMetadata(command);
        final options = metadata.options;

        expect(options, hasLength(3)); // verbose, quiet, help

        final verboseOption = options.firstWhere((o) => o.name == 'verbose');
        expect(verboseOption.type, equals(OptionType.flag));
        expect(verboseOption.short, equals('v'));
        expect(verboseOption.description, equals('Enable verbose output'));

        final quietOption = options.firstWhere((o) => o.name == 'quiet');
        expect(quietOption.type, equals(OptionType.flag));
        expect(quietOption.short, isNull);
        expect(quietOption.description, equals('Suppress output'));
      });

      test('extracts value options', () {
        final parser = ArgParser();
        parser.addOption('output', abbr: 'o', help: 'Output format', allowed: ['human', 'json']);
        parser.addOption('template', help: 'Project template', defaultsTo: 'minimal');

        final command = _TestCommand('test', 'Test command', parser: parser);
        final metadata = extractor.extractMetadata(command);
        final options = metadata.options;

        expect(options, hasLength(3)); // output, template, help

        final outputOption = options.firstWhere((o) => o.name == 'output');
        expect(outputOption.type, equals(OptionType.value));
        expect(outputOption.short, equals('o'));
        expect(outputOption.allowedValues, equals(['human', 'json']));

        final templateOption = options.firstWhere((o) => o.name == 'template');
        expect(templateOption.type, equals(OptionType.value));
        expect(templateOption.defaultValue, equals('minimal'));
      });

      test('handles options without help text', () {
        final parser = ArgParser();
        parser.addFlag('no-help');

        final command = _TestCommand('test', 'Test command', parser: parser);
        final metadata = extractor.extractMetadata(command);
        final options = metadata.options;

        expect(options, hasLength(2)); // no-help, help

        final noHelpOption = options.firstWhere((o) => o.name == 'no-help');
        expect(noHelpOption.description, equals(''));
      });
    });

    group('_extractSubcommands', () {
      test('extracts subcommands', () {
        final command = _TestCommand('parent', 'Parent command');
        command.addSubcommand(_TestCommand('child1', 'First child'));
        command.addSubcommand(_TestCommand('child2', 'Second child'));

        final metadata = extractor.extractMetadata(command);
        final subcommands = metadata.subcommands;

        expect(subcommands, hasLength(2));

        final child1 = subcommands.firstWhere((s) => s.name == 'child1');
        expect(child1.description, equals('First child'));

        final child2 = subcommands.firstWhere((s) => s.name == 'child2');
        expect(child2.description, equals('Second child'));
      });

      test('handles command without subcommands', () {
        final command = _TestCommand('test', 'Test command');
        final metadata = extractor.extractMetadata(command);
        final subcommands = metadata.subcommands;

        expect(subcommands, isEmpty);
      });
    });

    group('extractGlobalOptions', () {
      test('extracts global options from CommandRunner', () {
        final runner = CommandRunner<int>('test', 'Test runner');
        runner.argParser.addFlag('verbose', abbr: 'v', help: 'Enable verbose output');
        runner.argParser.addOption('output', help: 'Output format', allowed: ['human', 'json']);

        final globalOptions = extractor.extractGlobalOptions(runner);

        expect(globalOptions, hasLength(3)); // help, verbose, output

        final verboseOption = globalOptions.firstWhere((o) => o.name == 'verbose');
        expect(verboseOption.type, equals(OptionType.flag));
        expect(verboseOption.short, equals('v'));

        final outputOption = globalOptions.firstWhere((o) => o.name == 'output');
        expect(outputOption.type, equals(OptionType.value));
        expect(outputOption.allowedValues, equals(['human', 'json']));
      });

      test('handles CommandRunner without global options', () {
        final runner = CommandRunner<int>('test', 'Test runner');
        final globalOptions = extractor.extractGlobalOptions(runner);

        expect(globalOptions, hasLength(1)); // help is always added
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

/// Test command with manual metadata for testing
class _TestCommandWithMetadata extends FlyCommand {
  _TestCommandWithMetadata(this._name, this._description, this._metadata, {ArgParser? parser}) 
      : _parser = parser,
        super(CommandTestHelper.createMockCommandContext());

  final String _name;
  final String _description;
  final ArgParser? _parser;
  final CommandDefinition _metadata;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  ArgParser get argParser => _parser ?? ArgParser();

  @override
  CommandDefinition? get metadata => _metadata;

  @override
  Future<CommandResult> execute() async => CommandResult.success(
    command: _name,
    message: 'Test command executed',
  );
}
