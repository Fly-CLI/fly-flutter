import 'dart:io';

import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/completion_generator.dart';
import 'package:fly_cli/src/features/completion/generators/bash_generator.dart';
import 'package:fly_cli/src/features/completion/generators/fish_generator.dart';
import 'package:fly_cli/src/features/completion/generators/powershell_generator.dart';
import 'package:fly_cli/src/features/completion/generators/zsh_generator.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/completion_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/completion_result.dart';
import 'package:fly_mcp/fly_mcp.dart';
import 'package:path/path.dart' as path;

/// Strategy for fly.completion tool
class ShellCompletionStrategy
    extends McpToolStrategy<CompletionParams, CompletionResult> {
  @override
  String get name => 'fly.completion';

  @override
  String get description => 'Generate shell completion scripts';

  @override
  ObjectSchema get paramsSchema => ObjectSchema(
        properties: {
          'shell':
              Schema.string(enumValues: ['bash', 'zsh', 'fish', 'powershell']),
          'outputFile': Schema.string(),
          'install': Schema.bool(),
        },
        additionalProperties: false,
      );

  @override
  ObjectSchema get resultSchema => ObjectSchema(
        properties: {
          'success': Schema.bool(),
          'message': Schema.string(),
          'shell': Schema.string(),
          'outputFile': Schema.string(),
          'installPath': Schema.string(),
        },
        required: ['success', 'message'],
      );

  @override
  bool get readOnly => true;

  @override
  bool get writesToDisk => true;

  @override
  bool get requiresConfirmation => false;

  @override
  bool get idempotent => true;

  @override
  Duration? get timeout => const Duration(seconds: 30);

  @override
  CompletionParams paramsFromJson(Map<String, Object?> json) {
    return CompletionParams.fromJson(json);
  }

  @override
  TypedToolHandler<CompletionParams, CompletionResult> createTypedHandler(
    CommandContext context,
    ResourceRegistry resourceRegistry,
  ) {
    return (params, {cancelToken, progressNotifier}) async {
      cancelToken?.throwIfCancelled();

      final shell = params.shell ?? 'bash';
      final outputFile = params.outputFile;
      final install = params.install ?? false;

      await progressNotifier?.notify(
          message: 'Generating $shell completion script...', percent: 10);

      // Get command registry
      final registry = CommandMetadataRegistry.instance;

      // Get appropriate generator
      final generator = _getGenerator(shell);

      await progressNotifier?.notify(
          message: 'Generating script...', percent: 50);

      // Generate completion script
      final script = generator.generate(registry);

      cancelToken?.throwIfCancelled();

      // Handle installation
      if (install) {
        final installPath = await _installCompletion(shell, script);
        return CompletionResult(
          success: true,
          message: 'Completion script installed successfully to $installPath',
          shell: shell,
          installPath: installPath,
        );
      }

      // Write to file if specified
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(script);

        return CompletionResult(
          success: true,
          message: 'Completion script saved to $outputFile',
          shell: shell,
          outputFile: outputFile,
          installPath: _getInstallPath(shell),
        );
      }

      return CompletionResult(
        success: true,
        message: 'Completion script generated successfully',
        shell: shell,
        installPath: _getInstallPath(shell),
      );
    };
  }

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

  String _getInstallPath(String shell) {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    switch (shell) {
      case 'bash':
      // Try .bashrc first, then .bash_profile
        final bashrc = path.join(homeDir, '.bashrc');
        final bashProfile = path.join(homeDir, '.bash_profile');
        if (File(bashrc).existsSync()) {
          return bashrc;
        }
        return bashProfile;
      case 'zsh':
        return path.join(homeDir, '.zshrc');
      case 'fish':
        return path.join(homeDir, '.config', 'fish', 'completions', 'fly.fish');
      case 'powershell':
      // PowerShell profile location varies by platform
        if (Platform.isWindows) {
          return path.join(
            Platform.environment['USERPROFILE'] ?? '',
            'Documents',
            'PowerShell',
            'Microsoft.PowerShell_profile.ps1',
          );
        } else {
          return path.join(homeDir, '.config', 'powershell', 'profile.ps1');
        }
      default:
        return 'Unknown';
    }
  }

  /// Install completion script to the appropriate location
  Future<String> _installCompletion(String shell, String script) async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';

    switch (shell) {
      case 'bash':
        return await _installBash(homeDir, script);
      case 'zsh':
        return await _installZsh(homeDir, script);
      case 'fish':
        return await _installFish(homeDir, script);
      case 'powershell':
        return await _installPowerShell(homeDir, script);
      default:
        throw ArgumentError('Unsupported shell: $shell');
    }
  }

  /// Install bash completion
  Future<String> _installBash(String homeDir, String script) async {
    // Try .bashrc first, then .bash_profile
    final bashrc = File(path.join(homeDir, '.bashrc'));
    final bashProfile = File(path.join(homeDir, '.bash_profile'));

    final configFile = bashrc.existsSync() ? bashrc : bashProfile;
    if (!await configFile.exists()) {
      await configFile.create(recursive: true);
    }

    // Check if already installed
    final existingContent = await configFile.readAsString();
    if (existingContent.contains('fly completion')) {
      // Already installed, update it
      final lines = existingContent.split('\n');
      final updatedLines = lines.where((line) =>
      !line.contains('fly completion') &&
          !line.contains('source <(fly completion')).toList()
      ..add('# Fly CLI completion')
      ..add('source <(fly completion bash)');
      await configFile.writeAsString(updatedLines.join('\n'));
    } else {
      // Append installation
      await configFile.writeAsString(
        '$existingContent\n# Fly CLI completion\nsource <(fly completion bash)\n',
        mode: FileMode.append,
      );
    }

    return configFile.path;
  }

  /// Install zsh completion
  Future<String> _installZsh(String homeDir, String script) async {
    final zshrc = File(path.join(homeDir, '.zshrc'));
    if (!await zshrc.exists()) {
      await zshrc.create(recursive: true);
    }

    final existingContent = await zshrc.readAsString();
    if (existingContent.contains('fly completion')) {
      // Already installed, update it
      final lines = existingContent.split('\n');
      final updatedLines = lines.where((line) =>
      !line.contains('fly completion') &&
          !line.contains('source <(fly completion')).toList()
      ..add('# Fly CLI completion')
      ..add('source <(fly completion zsh)');
      await zshrc.writeAsString(updatedLines.join('\n'));
    } else {
      await zshrc.writeAsString(
        '$existingContent\n# Fly CLI completion\nsource <(fly completion zsh)\n',
        mode: FileMode.append,
      );
    }

    return zshrc.path;
  }

  /// Install fish completion
  Future<String> _installFish(String homeDir, String script) async {
    final completionsDir = Directory(
      path.join(homeDir, '.config', 'fish', 'completions'),
    );
    if (!await completionsDir.exists()) {
      await completionsDir.create(recursive: true);
    }

    final completionFile = File(path.join(completionsDir.path, 'fly.fish'));
    await completionFile.writeAsString(script);

    return completionFile.path;
  }

  /// Install PowerShell completion
  Future<String> _installPowerShell(String homeDir, String script) async {
    String profilePath;
    if (Platform.isWindows) {
      profilePath = path.join(
        Platform.environment['USERPROFILE'] ?? homeDir,
        'Documents',
        'PowerShell',
        'Microsoft.PowerShell_profile.ps1',
      );
    } else {
      profilePath = path.join(homeDir, '.config', 'powershell', 'profile.ps1');
    }

    final profileFile = File(profilePath);
    final profileDir = profileFile.parent;
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    if (!await profileFile.exists()) {
      await profileFile.create(recursive: true);
    }

    final existingContent = await profileFile.readAsString();
    if (existingContent.contains('fly completion')) {
      // Already installed, update it
      final lines = existingContent.split('\n');
      final updatedLines = lines.where((line) =>
      !line.contains('fly completion') &&
          !line.contains('fly_Completion')).toList()
      ..add('# Fly CLI completion')
      ..add(script);
      await profileFile.writeAsString(updatedLines.join('\n'));
    } else {
      await profileFile.writeAsString(
        '$existingContent\n# Fly CLI completion\n$script\n',
        mode: FileMode.append,
      );
    }

    return profileFile.path;
  }
}

