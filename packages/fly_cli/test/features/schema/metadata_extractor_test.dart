import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/metadata/command_metadata.dart';
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
        final command = _TestCommand(
          'test',
          'Test command',
          flags: [
            const GlobalVerboseFlag(),
            GlobalFormatFlag(),
          ],
        );
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('test'));
        expect(metadata.description, equals('Test command'));
        expect(metadata.options, hasLength(2));

        final verboseFlag =
            metadata.options.firstWhere((flag) => flag.name == 'verbose');
        expect(verboseFlag.description, contains('Verbose'));
        expect(verboseFlag.abbreviation, equals('v'));

        final formatFlag =
            metadata.options.firstWhere((flag) => flag.name == 'format');
        expect(formatFlag.description, contains('Output format'));
        expect(formatFlag.abbreviation, equals('f'));
        expect(formatFlag.allowedValues, equals(['human', 'json', 'ai']));
      });

      test('extracts command with subcommands', () {
        final command = _TestCommand('test', 'Test command');
        command
          ..addSubcommand(_TestCommand('sub1', 'First subcommand'))
          ..addSubcommand(_TestCommand('sub2', 'Second subcommand'));

        final metadata = extractor.extractMetadata(command);

        expect(metadata.subcommands, hasLength(2));

        final sub1 = metadata.subcommands.firstWhere((s) => s.name == 'sub1');
        expect(sub1.description, equals('First subcommand'));

        final sub2 = metadata.subcommands.firstWhere((s) => s.name == 'sub2');
        expect(sub2.description, equals('Second subcommand'));
      });

      test('merges with global options', () {
        final globalOptions = [
          const GlobalVerboseFlag(),
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

        final command =
            _TestCommandWithMetadata('test', 'Test command', manualMetadata);
        final metadata = extractor.extractMetadata(command);

        expect(metadata.name, equals('test'));
        expect(
          metadata.description,
          equals('Manual metadata'),
        ); // Manual metadata is used
        expect(metadata.examples, hasLength(1));
        expect(
          metadata.examples.first.command,
          equals('fly test --example'),
        );
        expect(
          metadata.globalOptions,
          isEmpty,
        ); // Manual metadata doesn't have global options
      });
    });

    group('_extractSubcommands', () {
      test('extracts subcommands', () {
        final command = _TestCommand('parent', 'Parent command');
        command
          ..addSubcommand(_TestCommand('child1', 'First child'))
          ..addSubcommand(_TestCommand('child2', 'Second child'));

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

  });
}

/// Test command implementation for testing
class _TestCommand extends FlyCommand {
  _TestCommand(
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
}

/// Test command with manual metadata for testing
class _TestCommandWithMetadata extends FlyCommand {
  _TestCommandWithMetadata(
    this._name,
    this._description,
    this._metadata, {
    List<CliFlag>? flags,
  })  : _flags = flags ?? const [],
        super(CommandTestHelper.createMockCommandContext());

  final String _name;
  final String _description;
  final List<CliFlag> _flags;
  final CommandDefinition _metadata;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  List<CliFlag> get flags => _flags;

  @override
  CommandDefinition? get metadata => _metadata;

  @override
  Future<CommandResult> execute() async => CommandResult.success(
        command: _name,
        message: 'Test command executed',
      );
}
