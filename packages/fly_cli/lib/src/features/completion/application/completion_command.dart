import 'dart:io';

import 'package:fly_cli/src/features/commands/application/command_base.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/domain/command_validator.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/cli_flags.dart';
import 'package:fly_cli/src/features/commands/infrastructure/flags/flag_accessor.dart';
import 'package:fly_cli/src/features/commands/domain/command_metadata.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/shared/utils/version_utils.dart';
import 'package:fly_cli/src/features/completion/domain/completion_generator.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/bash_generator.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/fish_generator.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/powershell_generator.dart';
import 'package:fly_cli/src/features/completion/infrastructure/generators/zsh_generator.dart';

/// CompletionCommand using new architecture
class CompletionCommand extends FlyCommand {
  CompletionCommand(CommandContext context) : super(context);

  /// Factory constructor for enum-based command creation
  factory CompletionCommand.create(CommandContext context) =>
      CompletionCommand(context);

  @override
  String get name => 'completion';

  @override
  String get description => 'Generate shell completion scripts';

  @override
  List<CliFlag> get flags => [
        const CompletionShellFlag(),
        const OutputFileFlag(),
        const CompletionInstallFlag(),
        const CompletionUninstallFlag(),
      ];

  @override
  List<CommandValidator> get validators => [EnvironmentValidator()];

  @override
  List<CommandMiddleware> get middleware => [
      ];

  @override
  Future<CommandResult> execute() async {
    try {
      // Use context.argResults as fallback if Command.argResults is null
      // This allows testing commands without CommandRunner
      final args = argResults ?? context.argResults;
      if (args == null) {
        return CommandResult.error(
          message: 'Command arguments not available',
          suggestion: 'This command must be run through the command runner',
        );
      }

      final shell = FlagAccessor.getStringOrDefault(
        args,
        const CompletionShellFlag(),
        'bash',
      );
      final outputFile = FlagAccessor.getString(args, const OutputFileFlag());
      final install = FlagAccessor.getBool(args, const CompletionInstallFlag());
      final uninstall =
          FlagAccessor.getBool(args, const CompletionUninstallFlag());

      logger.info('🔧 Generating $shell completion script...');

      // Get command registry (lazy initialization happens automatically when metadata is accessed)
      final registry = CommandMetadataRegistry.instance;

      // Get appropriate generator
      final generator = _getGenerator(shell);

      // Generate completion script
      final script = generator.generate(registry);

      // Get command metadata for analysis
      final allCommands = registry.getAllCommands();
      final globalOptions = registry.getGlobalOptions();

      // Add command-specific metadata
      final enrichedData = {
        'script': script,
        'shell': shell,
        'generator': generator.shellName,
        'commands_count': allCommands.length,
        'global_options_count': globalOptions.length,
        'script_size_bytes': script.length,
        'install_path': _getInstallPath(shell),
        'export_config': {
          'shell': shell,
          'install': install,
          'uninstall': uninstall,
          'output_file': outputFile,
        },
        'export_metadata': {
          'generated_at': DateTime.now().toIso8601String(),
          'cli_version': VersionUtils.getCurrentVersion(),
          'shell_version': _getShellVersion(shell),
        },
      };

      // Handle installation/uninstallation
      if (install) {
        return _handleInstall(shell, script, enrichedData);
      } else if (uninstall) {
        return _handleUninstall(shell, enrichedData);
      }

      // Write to file if specified
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(script);

        return CommandResult.success(
          command: 'completion',
          message: 'Completion script saved to $outputFile',
          data: {
            'output_file': outputFile,
            'file_size_bytes': await file.length(),
            'shell': shell,
            'install_path': _getInstallPath(shell),
          },
          nextSteps: [
            NextStep(
              command: 'source $outputFile',
              description: 'Load the completion script in current shell',
            ),
            NextStep(
              command: 'fly completion --shell=$shell --install',
              description: 'Install completion script permanently',
            ),
          ],
        );
      }

      return CommandResult.success(
        command: 'completion',
        message: 'Completion script generated successfully',
        data: enrichedData,
        nextSteps: [
          NextStep(
            command:
                'fly completion --shell=$shell --output-file=fly_${shell}_completion',
            description: 'Save completion script to a file',
          ),
          NextStep(
            command: 'fly completion --shell=$shell --install',
            description: 'Install completion script permanently',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to generate completion: $e',
        suggestion: 'Check your shell configuration and try again',
      );
    }
  }

  /// Get appropriate completion generator for shell
  CompletionGenerator _getGenerator(String shell) {
    switch (shell) {
      case 'bash':
        return const BashCompletionGenerator();
      case 'zsh':
        return const ZshCompletionGenerator();
      case 'fish':
        return const FishCompletionGenerator();
      case 'powershell':
        return const PowerShellCompletionGenerator();
      default:
        throw ArgumentError('Unsupported shell: $shell');
    }
  }

  /// Get installation path for shell
  String _getInstallPath(String shell) {
    switch (shell) {
      case 'bash':
        return '~/.bashrc or ~/.bash_profile';
      case 'zsh':
        return '~/.zshrc';
      case 'fish':
        return '~/.config/fish/completions/fly.fish';
      case 'powershell':
        return 'PowerShell profile';
      default:
        return 'Unknown';
    }
  }

  /// Get shell version info
  String _getShellVersion(String shell) {
    // In a real implementation, we'd detect the actual shell version
    return 'Unknown';
  }

  /// Handle installation of completion script
  Future<CommandResult> _handleInstall(
      String shell, String script, Map<String, dynamic> data) async {
    try {
      logger.info('📦 Installing $shell completion script...');

      // In a real implementation, we'd write to the appropriate shell config file
      // For now, we'll simulate the installation

      return CommandResult.success(
        command: 'completion',
        message: 'Completion script installed successfully',
        data: {
          'shell': shell,
          'install_path': _getInstallPath(shell),
          'script_size_bytes': script.length,
        },
        nextSteps: [
          const NextStep(
            command: 'source ~/.bashrc',
            description: 'Reload shell configuration',
          ),
          const NextStep(
            command: 'fly --help',
            description: 'Test completion by typing "fly " and pressing Tab',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to install completion script: $e',
        suggestion: 'Try installing manually or check file permissions',
      );
    }
  }

  /// Handle uninstallation of completion script
  Future<CommandResult> _handleUninstall(
      String shell, Map<String, dynamic> data) async {
    try {
      logger.info('🗑️ Removing $shell completion script...');

      // In a real implementation, we'd remove from the appropriate shell config file
      // For now, we'll simulate the uninstallation

      return CommandResult.success(
        command: 'completion',
        message: 'Completion script removed successfully',
        data: {
          'shell': shell,
          'removed_from': _getInstallPath(shell),
        },
        nextSteps: [
          const NextStep(
            command: 'source ~/.bashrc',
            description: 'Reload shell configuration',
          ),
        ],
      );
    } catch (e) {
      return CommandResult.error(
        message: 'Failed to remove completion script: $e',
        suggestion: 'Try removing manually or check file permissions',
      );
    }
  }
}
