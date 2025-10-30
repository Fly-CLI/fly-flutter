import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';

/// Abstract base class for shell-specific completion generators
abstract class CompletionGenerator {
  const CompletionGenerator();

  /// Generate completion script for the specified shell
  String generate(CommandMetadataRegistry registry);

  /// Get the shell name this generator supports
  String get shellName;

  /// Escapes special characters for the shell
  String escape(String text);

  /// Quote text if necessary
  String quote(String text);

  /// Generate completion for a single command
  String generateCommandCompletion(CommandDefinition command);

  /// Generate completions for options
  String generateOptionsCompletion(List<OptionDefinition> options);

  /// Generate completions for subcommands
  String generateSubcommandsCompletion(List<SubcommandDefinition> subcommands);

  /// Generate completions for option values
  String generateOptionValuesCompletion(OptionDefinition option);
}

/// Helper utilities for completion generation
class CompletionUtils {
  /// Join strings with proper escaping
  static String joinCompletions(List<String> completions, String separator) =>
      completions.join(separator);

  /// Create option completion entry
  static String optionCompletion(String name, String description) =>
      description.isNotEmpty ? '$name\t$description' : name;

  /// Filter non-hidden commands
  static List<CommandDefinition> visibleCommands(
    Map<String, CommandDefinition> allCommands,
  ) =>
      allCommands.values.where((c) => !c.isHidden).toList();
}
