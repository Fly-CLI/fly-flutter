import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/domain/completion_generator.dart';

/// Zsh shell completion generator
class ZshCompletionGenerator extends CompletionGenerator {
  const ZshCompletionGenerator();

  @override
  String get shellName => 'zsh';

  @override
  String generate(CommandMetadataRegistry registry) {
    final buffer = StringBuffer()
      ..writeln('#compdef fly')
      ..writeln()
      ..writeln('_fly() {')
      ..writeln('    local context state line')
      ..writeln('    typeset -A opt_args')
      ..writeln('    ')
      ..writeln(r'    _arguments -C \')
      ..writeln(r"        '1: :->command' \")
      ..writeln("        '*::arg:->args'");

    // Add global options
    final globalOptions = registry.getGlobalOptions();
    for (final option in globalOptions) {
      final desc =
          option.description.replaceAll('[', r'\[').replaceAll(']', r'\]');
      buffer.writeln(
          "        '--${option.name}${option.short != null ? "(-${option.short})" : ""}[$desc]' \\",);
    }

    buffer
      ..writeln('        && return 0')
      ..writeln('    ')
      ..writeln(r'    case $state in')
      ..writeln('        command)')
      ..writeln('            local commands=(');

    // Add all commands
    final allCommands = registry.getAllCommands();
    for (final entry in allCommands.entries) {
      if (!entry.value.isHidden) {
        final desc = entry.value.description.replaceAll(':', r'\:');
        buffer.writeln("                '${entry.key}:$desc'");
      }
    }

    buffer
      ..writeln('            )')
      ..writeln("            _describe 'commands' commands")
      ..writeln('            ;;')
      ..writeln('        args)')
      ..writeln(r'            case $line[1] in');

    // Add command-specific completions
    for (final entry in allCommands.entries) {
      if (entry.value.options.isNotEmpty ||
          entry.value.subcommands.isNotEmpty) {
        buffer
          ..writeln('                ${entry.key})')
          ..writeln('                    _fly_${entry.key}')
          ..writeln('                    ;;');
      }
    }

    buffer
      ..writeln('            esac')
      ..writeln('            ;;')
      ..writeln('    esac')
      ..writeln('}')
      ..writeln();

    // Generate helper functions for commands
    for (final entry in allCommands.entries) {
      if (entry.value.options.isNotEmpty ||
          entry.value.subcommands.isNotEmpty) {
        generateCommandFunction(buffer, entry.key, entry.value);
      }
    }

    buffer.writeln(r'_fly "$@"');

    return buffer.toString();
  }

  void generateCommandFunction(
      StringBuffer buffer, String commandName, CommandDefinition command,) {
    buffer
      ..writeln('_fly_$commandName() {')
      ..writeln(r'    _arguments \');

    // Add command options
    for (final option in command.options) {
      final desc =
          option.description.replaceAll('[', r'\[').replaceAll(']', r'\]');
      if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
        final values = option.allowedValues!.map((v) => '"$v"').join(' ');
        buffer.writeln("        '--${option.name}[$desc]: :($values)' \\");
      } else {
        buffer.writeln("        '--${option.name}[$desc]' \\");
      }
    }

    // Add subcommands
    if (command.subcommands.isNotEmpty) {
      buffer
        ..writeln("        '1: :->subcommand'")
        ..writeln('    ')
        ..writeln(r'    case $state in')
        ..writeln('        subcommand)')
        ..writeln('            local subcommands=(');
      for (final subcommand in command.subcommands) {
        final desc = subcommand.description.replaceAll(':', r'\:');
        buffer.writeln("                '${subcommand.name}:$desc'");
      }
      buffer
        ..writeln('            )')
        ..writeln("            _describe 'subcommands' subcommands")
        ..writeln('            ;;')
        ..writeln('    esac');
    }

    buffer.writeln('}');
    buffer.writeln();
  }

  @override
  String escape(String text) => text.replaceAll("'", "''");

  @override
  String quote(String text) => "'$text'";

  @override
  String generateCommandCompletion(CommandDefinition command) => command.name;

  @override
  String generateOptionsCompletion(List<OptionDefinition> options) =>
      options.map((o) => '--${o.name}').join(' ');

  @override
  String generateSubcommandsCompletion(
    List<SubcommandDefinition> subcommands,
  ) =>
      subcommands.map((s) => s.name).join(' ');

  @override
  String generateOptionValuesCompletion(OptionDefinition option) {
    if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
      return option.allowedValues!.join(' ');
    }
    return '';
  }
}
