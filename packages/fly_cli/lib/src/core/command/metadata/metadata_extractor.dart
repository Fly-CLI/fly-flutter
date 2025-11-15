import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/command/foundation/application/command_base.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/metadata/command_definition.dart';

/// Extracts command metadata from Command instances and ArgParser
class MetadataExtractor {
  /// Creates a new MetadataExtractor instance
  const MetadataExtractor();

  /// Extract metadata from a command instance
  CommandDefinition extractMetadata(
    Command<int> command, [
    List<CliFlag> globalOptions = const [],
  ]) {
    // Extract basic info
    final name = command.name;
    final description = command.description;

    final options = _extractFlags(command);

    // Extract subcommands
    final subcommands = _extractSubcommands(command);

    // If command has manual metadata, use it and merge
    if (command is FlyCommand) {
      final manualMetadata = command.metadata;
      if (manualMetadata != null && manualMetadata.isValid()) {
        return manualMetadata.copyWith(
          options: _mergeFlags(manualMetadata.options, options),
          globalOptions: _mergeFlags(manualMetadata.globalOptions, globalOptions),
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

  List<CliFlag> _extractFlags(Command<int> command) {
    if (command is FlyCommand) {
      return command.flags;
    }
    return const [];
  }

  /// Extract subcommands from a command
  List<SubcommandDefinition> _extractSubcommands(Command<int> command) {
    final subcommands = <SubcommandDefinition>[];

    for (final entry in command.subcommands.entries) {
      final subcommand = entry.value;
      subcommands.add(
        SubcommandDefinition(
          name: entry.key,
          description: subcommand.description,
        ),
      );
    }

    return subcommands;
  }

  List<CliFlag> _mergeFlags(List<CliFlag> base, List<CliFlag> additional) {
    if (additional.isEmpty) {
      return List<CliFlag>.unmodifiable(base);
    }

    final seen = <String>{};
    final merged = <CliFlag>[];

    for (final flag in base) {
      merged.add(flag);
      seen.add(flag.name);
    }

    for (final flag in additional) {
      if (seen.add(flag.name)) {
        merged.add(flag);
      }
    }

    return List<CliFlag>.unmodifiable(merged);
  }
}
