import 'package:fly_cli/src/core/command/foundation/flags/cli_flag_extensions.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/metadata/command_metadata.dart';
import 'package:fly_cli/src/features/schema/export_format.dart';

import 'schema_exporter.dart';

/// Custom CLI specification exporter
class CliSpecExporter extends SchemaExporter {
  CliSpecExporter();

  @override
  ExportFormat get format => ExportFormat.cliSpec;

  @override
  String get contentType => 'application/json';

  @override
  String export(CommandMetadataRegistry registry, ExportConfig config) {
    final commands = SchemaExportUtils.filterCommands(registry, config);
    final globalOptions = SchemaExportUtils.getGlobalOptions(registry, config);

    final spec = <String, dynamic>{
      'version': '1.0.0',
      'name': 'fly',
      'description': 'Fly CLI - Flutter development tool',
      'globalOptions':
          globalOptions.map((flag) => _buildOptionSpec(flag, isGlobal: true)).toList(),
      'commands': <String, dynamic>{},
    };

    // Add each command
    for (final entry in commands.entries) {
      final commandName = entry.key;
      final command = entry.value;

      spec['commands'][commandName] = _buildCommandSpec(command, config);
    }

    return SchemaExportUtils.formatJson(spec, prettyPrint: config.prettyPrint);
  }

  @override
  String exportCommand(CommandDefinition command, ExportConfig config) {
    final spec = <String, dynamic>{
      'version': '1.0.0',
      'name': 'fly',
      'command': _buildCommandSpec(command, config),
    };

    return SchemaExportUtils.formatJson(spec, prettyPrint: config.prettyPrint);
  }

  /// Build CLI spec for a single command
  Map<String, dynamic> _buildCommandSpec(
      CommandDefinition command, ExportConfig config) {
    final spec = <String, dynamic>{
      'name': command.name,
      'description': command.description,
      'hidden': command.isHidden,
    };

    // Add arguments
    if (command.arguments.isNotEmpty) {
      spec['arguments'] = command.arguments.map(_buildArgumentSpec).toList();
    }

    // Add options
    if (command.options.isNotEmpty) {
      spec['options'] = command.options.map(_buildOptionSpec).toList();
    }

    // Add subcommands
    if (command.subcommands.isNotEmpty) {
      spec['subcommands'] =
          command.subcommands.map(_buildSubcommandSpec).toList();
    }

    // Add examples
    if (config.includeExamples && command.examples.isNotEmpty) {
      spec['examples'] = command.examples
          .map(
            (e) => {
              'command': e.command,
              'description': e.description,
            },
          )
          .toList();
    }

    // Add completion hints
    spec['completion'] = _buildCompletionSpec(command);

    return spec;
  }

  /// Build argument specification
  Map<String, dynamic> _buildArgumentSpec(ArgumentDefinition arg) {
    final spec = <String, dynamic>{
      'name': arg.name,
      'description': arg.description,
      'type': 'string', // Arguments are always strings
      'required': arg.required,
    };

    if (arg.allowedValues != null && arg.allowedValues!.isNotEmpty) {
      spec['allowedValues'] = arg.allowedValues;
    }

    if (arg.defaultValue != null) {
      spec['defaultValue'] = arg.defaultValue;
    }

    return spec;
  }

  /// Build option specification
  Map<String, dynamic> _buildOptionSpec(CliFlag flag, {bool isGlobal = false}) {
    final option = flag.toOptionDefinition(isGlobalOverride: isGlobal);
    final spec = <String, dynamic>{
      'name': option.name,
      'description': option.description,
      'type': option.type.name,
      'global': option.isGlobal,
    };

    if (option.short != null) {
      spec['short'] = option.short;
    }

    if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
      spec['allowedValues'] = option.allowedValues;
    }

    if (option.defaultValue != null) {
      spec['defaultValue'] = option.defaultValue;
    }

    return spec;
  }

  /// Build subcommand specification
  Map<String, dynamic> _buildSubcommandSpec(SubcommandDefinition subcommand) =>
      {
        'name': subcommand.name,
        'description': subcommand.description,
      };

  /// Build completion specification
  Map<String, dynamic> _buildCompletionSpec(CommandDefinition command) {
    final completion = <String, dynamic>{
      'command': command.name,
    };

    // Add argument completions
    if (command.arguments.isNotEmpty) {
      completion['arguments'] = command.arguments
          .map(
            (a) => {
              'name': a.name,
              'type': 'string', // Arguments are always strings
              if (a.allowedValues != null) 'values': a.allowedValues,
            },
          )
          .toList();
    }

    // Add option completions
    if (command.options.isNotEmpty) {
      completion['options'] = command.options
          .map(
            (flag) => {
              'name': flag.name,
              'type': _mapFlagType(flag.type),
              if (flag.abbreviation != null) 'short': flag.abbreviation,
              if (flag.allowedValues != null) 'values': flag.allowedValues,
            },
          )
          .toList();
    }

    // Add subcommand completions
    if (command.subcommands.isNotEmpty) {
      completion['subcommands'] =
          command.subcommands.map((s) => s.name).toList();
    }

    return completion;
  }

  String _mapFlagType(FlagType type) => switch (type) {
        FlagType.boolean => 'flag',
        FlagType.singleValue => 'value',
        FlagType.multiValue => 'multiple',
      };
}
