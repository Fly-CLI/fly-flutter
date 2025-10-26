import 'package:fly_cli/src/features/schema/domain/command_definition.dart';
import 'package:fly_cli/src/features/schema/domain/command_registry.dart';
import 'package:fly_cli/src/features/completion/domain/completion_generator.dart';

/// Fish shell completion generator
class FishCompletionGenerator extends CompletionGenerator {
  const FishCompletionGenerator();

  @override
  String get shellName => 'fish';

  @override
  String generate(CommandMetadataRegistry registry) {
    final buffer = StringBuffer()

    ..writeln('# Fly CLI fish completion script')
    ..writeln()
    ..writeln('complete -c fly -f')
    ..writeln();

    // Generate commands
    final allCommands = registry.getAllCommands();
    for (final entry in allCommands.entries) {
      if (!entry.value.isHidden) {
        buffer.writeln(
            'complete -c fly -n "__fish_use_subcommand" -a "${entry.key}" -d "${entry.value.description}"',);
      }
    }
    buffer.writeln();

    // Generate global options
    final globalOptions = registry.getGlobalOptions();
    for (final option in globalOptions) {
      final flags = option.short != null
          ? '-s ${option.short} -l ${option.name}'
          : '-l ${option.name}';
      buffer.writeln('complete -c fly $flags -d "${option.description}"');

      if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
        final values = option.allowedValues!.map((v) => "'$v'").join(' ');
        buffer.writeln('complete -c fly $flags -a "$values"');
      }
    }
    buffer.writeln();

    // Generate command-specific completions
    for (final entry in allCommands.entries) {
      generateCommandCompletions(buffer, entry.key, entry.value);
    }

    return buffer.toString();
  }

  void generateCommandCompletions(
      StringBuffer buffer, String commandName, CommandDefinition command,) {
    final condition = '__fish_seen_subcommand_from $commandName';

    // Add command options
    for (final option in command.options) {
      final flags = option.short != null
          ? '-n "$condition" -s ${option.short} -l ${option.name}'
          : '-n "$condition" -l ${option.name}';
      buffer.writeln('complete -c fly $flags -d "${option.description}"');

      if (option.allowedValues != null && option.allowedValues!.isNotEmpty) {
        final values = option.allowedValues!.map((v) => "'$v'").join(' ');
        buffer.writeln('complete -c fly $flags -a "$values"');
      }
    }

    // Add subcommands
    if (command.subcommands.isNotEmpty) {
      buffer.writeln();
      for (final subcommand in command.subcommands) {
        buffer.writeln(
            'complete -c fly -n "$condition" -a "${subcommand.name}" -d "${subcommand.description}"',);
      }
    }

    buffer.writeln();
  }

  @override
  String escape(String text) => text.replaceAll("'", r"\'");

  @override
  String quote(String text) => '"$text"';

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
