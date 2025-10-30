import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/completion_generator.dart';

/// PowerShell completion generator
class PowerShellCompletionGenerator extends CompletionGenerator {
  const PowerShellCompletionGenerator();

  @override
  String get shellName => 'powershell';

  @override
  String generate(CommandMetadataRegistry registry) {
    final buffer = StringBuffer()
      ..writeln('# Fly CLI PowerShell completion script')
      ..writeln()
      ..writeln(
          'Register-ArgumentCompleter -Native -CommandName fly -ScriptBlock {',)
      ..writeln(r'    param($commandName, $wordToComplete, $cursorPosition)')
      ..writeln('    ')
      ..writeln(r'    $completions = @()')
      ..writeln('    ')

      // Generate commands list - include top-level commands and subcommands
      ..writeln('    # Commands');
    final commandNamesList = <String>[]
    // Add all top-level commands and groups
    ..addAll(registry.getCommandNames());
    // Add subcommands from command groups
    final allCommands = registry.getAllCommands();
    for (final entry in allCommands.entries) {
      for (final subcommand in entry.value.subcommands) {
        commandNamesList.add(subcommand.name);
      }
    }
    final commandNames = commandNamesList.join("','");
    buffer
      ..writeln("    \$commands = @('$commandNames')")
      ..writeln('    ')

      // Generate global options
      ..writeln('    # Global options');
    final globalOptionsString =
        registry.getGlobalOptions().map((o) => "'--${o.name}'").join(',');
    buffer
      ..writeln('    \$globalOptions = @($globalOptionsString)')
      ..writeln('    ')
      ..writeln(r"    if ($wordToComplete -match '^[^-]') {")
      ..writeln('        # Complete commands')
      ..writeln(
          r'        $completions = $commands | Where-Object { $_ -like "$wordToComplete*" }',)
      ..writeln('    } else {')
      ..writeln('        # Complete options')
      ..writeln(
          r'        $completions = $globalOptions | Where-Object { $_ -like "$wordToComplete*" }',)
      ..writeln('    }')
      ..writeln('    ')
      ..writeln(r'    return $completions')
      ..writeln('}');

    return buffer.toString();
  }

  @override
  String escape(String text) =>
      text.replaceAll('`', '``').replaceAll("'", "''");

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
