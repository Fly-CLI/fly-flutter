import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/completion_generator.dart';
// 
/// Bash shell completion generator
class BashCompletionGenerator extends CompletionGenerator {
  const BashCompletionGenerator();

  @override
  String get shellName => 'bash';

  @override
  String generate(CommandMetadataRegistry registry) {
    final buffer = StringBuffer()
      ..writeln('# Fly CLI bash completion script')
      ..writeln()
      ..writeln('_fly_completion() {')
      ..writeln('    local cur prev opts')
      ..writeln('    COMPREPLY=()')
      ..writeln(r'    cur="${COMP_WORDS[COMP_CWORD]}"')
      ..writeln(r'    prev="${COMP_WORDS[COMP_CWORD-1]}"')
      ..writeln()

      // Generate global options list
      ..writeln('    # Global options');
    final globalOpts =
        registry.getGlobalOptions().map((o) => '--${o.name}').join(' ');
    buffer
      ..writeln('    local global_opts="$globalOpts"')
      ..writeln()

      // Generate commands list
      ..writeln('    # Commands');
    final commandNames = registry.getCommandNames().join(' ');
    buffer
      ..writeln('    local commands="$commandNames"')
      ..writeln();

    // Generate per-command completions
    final allCommands = registry.getAllCommands();
    for (final entry in allCommands.entries) {
      buffer.writeln('    # ${entry.key} command');
      generateCommandCase(buffer, entry.key, entry.value);
      buffer.writeln();
    }

    buffer
      ..writeln('    # Default completion')
      ..writeln(r'    case "${prev}" in')
      ..writeln('        --output)')
      ..writeln(
          r'            COMPREPLY=( $(compgen -W "human json" -- "${cur}") )',)
      ..writeln('            return 0')
      ..writeln('            ;;')
      ..writeln('    esac')
      ..writeln('    ')
      ..writeln(r'    COMPREPLY=( $(compgen -W "${global_opts}" -- "${cur}") )')
      ..writeln('}')
      ..writeln()
      ..writeln('complete -F _fly_completion fly');

    return buffer.toString();
  }

  void generateCommandCase(
      StringBuffer buffer, String commandName, CommandDefinition command,) {
    // Generate command-specific options
    final options = command.options.map((o) => '--${o.name}').join(' ');
    final subcommands = command.subcommands.map((s) => s.name).join(' ');

    if (subcommands.isEmpty && options.isEmpty) {
      return;
    }

    buffer
      ..writeln(r'        case "${prev}" in')
      ..writeln('            $commandName)');

    if (subcommands.isNotEmpty) {
      buffer.writeln(
          r'                COMPREPLY=( $(compgen -W "' + subcommands + r'" -- "${cur}") )',);
    } else if (options.isNotEmpty) {
      buffer.writeln(
          r'                COMPREPLY=( $(compgen -W "' + options + r' $global_opts" -- "${cur}") )',);
    }

    if (subcommands.isNotEmpty || options.isNotEmpty) {
      buffer.writeln('                return 0');
    }

    buffer.writeln('                ;;');
    buffer.writeln('        esac');
  }

  @override
  String escape(String text) => text.replaceAll("'", r"'\''");

  @override
  String quote(String text) => "'$text'";

  @override
  String generateCommandCompletion(CommandDefinition command) => command.name;

  @override
  String generateOptionsCompletion(List<OptionDefinition> options) =>
      options.map((o) => '--${o.name}').join(' ');

  @override
  String generateSubcommandsCompletion(
          List<SubcommandDefinition> subcommands,) =>
      subcommands.map((s) => s.name).join(' ');

  @override
  String generateOptionValuesCompletion(OptionDefinition option) {
    if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
      return option.allowedValues!.join(' ');
    }
    return '';
  }
}
