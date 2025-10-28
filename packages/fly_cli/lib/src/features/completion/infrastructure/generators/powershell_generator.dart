import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/domain/completion_generator.dart';

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

      // Generate commands list
      ..writeln('    # Commands');
    final commandNames = registry.getCommandNames().join("','");
    buffer
      ..writeln("    \$commands = @('$commandNames')")
      ..writeln('    ')

      // Generate global options
      ..writeln('    # Global options');
    final globalOptions =
        registry.getGlobalOptions().map((o) => "'--${o.name}'").join(',');
    buffer
      ..writeln('    \$globalOptions = @($globalOptions)')
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
