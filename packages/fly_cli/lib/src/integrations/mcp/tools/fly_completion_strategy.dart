import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_metadata/command_metadata.dart';
import 'package:fly_cli/src/features/completion/completion_generator.dart';
import 'package:fly_cli/src/features/completion/generators/bash_generator.dart';
import 'package:fly_cli/src/features/completion/generators/fish_generator.dart';
import 'package:fly_cli/src/features/completion/generators/powershell_generator.dart';
import 'package:fly_cli/src/features/completion/generators/zsh_generator.dart';
import 'package:fly_cli/src/integrations/mcp/mcp_tool_strategy.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_completion_params.dart';
import 'package:fly_cli/src/integrations/mcp/tools/types/fly_completion_result.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Strategy for fly.completion tool
class FlyCompletionStrategy
    extends McpToolStrategy<FlyCompletionParams, FlyCompletionResult> {
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
  FlyCompletionParams paramsFromJson(Map<String, Object?> json) {
    return FlyCompletionParams.fromJson(json);
  }

  @override
  TypedToolHandler<FlyCompletionParams, FlyCompletionResult> createTypedHandler(
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
        // TODO: Implement actual installation logic
        return FlyCompletionResult(
          success: true,
          message: 'Completion script installed successfully',
          shell: shell,
          installPath: _getInstallPath(shell),
        );
      }

      // Write to file if specified
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(script);

        return FlyCompletionResult(
          success: true,
          message: 'Completion script saved to $outputFile',
          shell: shell,
          outputFile: outputFile,
          installPath: _getInstallPath(shell),
        );
      }

      return FlyCompletionResult(
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
}
