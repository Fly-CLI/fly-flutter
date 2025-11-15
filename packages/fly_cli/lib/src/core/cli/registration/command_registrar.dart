import 'package:args/command_runner.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/core/command/foundation/flags/cli_flags.dart';
import 'package:fly_cli/src/core/command/metadata/command_registry.dart';
import 'package:fly_cli/src/core/command/metadata/command_wrappers.dart';
import 'package:fly_cli/src/core/definitions/fly_command.dart';

/// Handles command registration for the CLI
///
/// This class separates command registration logic from the command runner,
/// making it easier to test and extend.
class CommandRegistrar {
  /// Create a command registrar
  ///
  /// [contextFactory] - Factory for creating command contexts
  CommandRegistrar(this.contextFactory);

  final IContextFactory contextFactory;

  /// Register all commands with the command runner
  ///
  /// Registers all commands, their aliases, and command groups
  /// using the command metadata registry.
  ///
  /// [commandRunner] - The command runner to register commands with
  /// [globalFlags] - List of available global flags
  void registerCommands(
    CommandRunner<int> commandRunner,
    List<CliFlag> globalFlags,
  ) {
    // Create a registration context with empty args for command setup
    // This context is used only during registration, not for execution
    final context = contextFactory.createRegistrationContext();

    // Delegate command creation to registry
    final registrationData =
        CommandMetadataRegistry.instance.createAndInitialize(
      context: context,
      globalFlags: globalFlags,
    );

    // Register top-level commands
    for (final entry in registrationData.topLevelCommands.entries) {
      final commandType = entry.key;
      final commandInstance = entry.value;

      // Register top-level command
      commandRunner.addCommand(commandInstance);

      // Register aliases for top-level commands
      for (final alias in commandType.aliases) {
        commandRunner.addCommand(AliasCommand(alias, commandInstance));
      }
    }

    // Register all command groups
    registrationData.commandGroups.values.forEach(commandRunner.addCommand);
  }
}
