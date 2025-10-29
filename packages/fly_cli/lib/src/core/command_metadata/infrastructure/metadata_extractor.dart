import 'package:args/args.dart' hide OptionType;
import 'package:args/command_runner.dart';

import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command_metadata/domain/command_definition.dart';

/// Extracts command metadata from Command instances and ArgParser
class MetadataExtractor {
  /// Creates a new MetadataExtractor instance
  const MetadataExtractor();

  /// Extract metadata from a command instance
  CommandDefinition extractMetadata(Command<int> command,
      [List<OptionDefinition> globalOptions = const [],]) {
    // Extract basic info
    final name = command.name;
    final description = command.description;

    // Extract options from ArgParser
    final options = _extractOptions(command.argParser);

    // Extract subcommands
    final subcommands = _extractSubcommands(command);

    // If command has manual metadata, use it and merge
    if (command is FlyCommand) {
      final manualMetadata = command.metadata;
      if (manualMetadata != null && manualMetadata.isValid()) {
        return manualMetadata.copyWith(
          options: [...manualMetadata.options, ...options],
          globalOptions: [...globalOptions, ...options],
        );
      }
    }

    // Return auto-discovered metadata
    return CommandDefinition(
      name: name,
      description: description,
      options: options,
      subcommands: subcommands,
      globalOptions: globalOptions,
    );
  }

  /// Extract options from an ArgParser
  List<OptionDefinition> _extractOptions(
    ArgParser parser, {
    bool isGlobal = false,
  }) {
    final options = <OptionDefinition>[];

    for (final option in parser.options.values) {
      options.add(
        OptionDefinition(
          name: option.name,
          description: option.help ?? '',
          short: option.abbr,
          type: option.isFlag ? OptionType.flag : OptionType.value,
          allowedValues: option.allowed?.toList(),
          defaultValue: option.defaultsTo,
          isGlobal: isGlobal,
        ),
      );
    }

    return options;
  }

  /// Extract subcommands from a command
  List<SubcommandDefinition> _extractSubcommands(Command<int> command) {
    final subcommands = <SubcommandDefinition>[];

    for (final entry in command.subcommands.entries) {
      final subcommand = entry.value;
      subcommands.add(SubcommandDefinition(
        name: entry.key,
        description: subcommand.description,
      ),);
    }

    return subcommands;
  }

  /// Extract global options from ArgParser
  List<OptionDefinition> extractGlobalOptions(ArgParser parser) =>
      _extractOptions(parser, isGlobal: true);
}

