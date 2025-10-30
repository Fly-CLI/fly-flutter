import 'dart:io';

import 'package:fly_core/src/environment/env_var.dart';
import 'package:fly_core/src/environment/environment_manager.dart';

/// Builder for constructing command strings and arguments
/// 
/// Provides utilities for building commands with platform-aware
/// handling of shells and arguments.
class CommandBuilder {
  const CommandBuilder();

  /// Build command arguments with proper escaping
  List<String> buildArguments(List<String> baseArgs) {
    return List<String>.from(baseArgs);
  }

  /// Get shell to use for command execution
  String getShell() {
    const env = EnvironmentManager();
    final platform = Platform.operatingSystem;
    
    if (platform == 'windows') {
      return env.getString(EnvVar.comspec) ??
          env.getString(EnvVar.comSpec) ??
          'powershell.exe';
    } else {
      return env.getString(EnvVar.shell) ?? '/bin/bash';
    }
  }

  /// Detect the current shell type
  String detectShell() {
    const env = EnvironmentManager();
    final shell = env.getString(EnvVar.shell) ?? env.getString(EnvVar.comSpec);
    
    if (shell == null) {
      return 'unknown';
    }

    if (shell.contains('bash')) return 'bash';
    if (shell.contains('zsh')) return 'zsh';
    if (shell.contains('fish')) return 'fish';
    if (shell.contains('powershell') || shell.contains('pwsh')) {
      return 'powershell';
    }
    if (shell.contains('cmd')) return 'cmd';

    return 'unknown';
  }

  /// Check if running in CI environment
  bool get isCI {
    return Platform.environment.containsKey('CI') ||
        Platform.environment.containsKey('CONTINUOUS_INTEGRATION');
  }

  /// Check if should run commands in shell
  bool shouldRunInShell(String command, List<String> args) {
    // Shell execution is generally needed for:
    // - Complex pipes or redirects
    // - Wildcard expansion
    // - Environment variable expansion
    // For now, default to false unless explicitly needed
    return false;
  }

  /// Create a shell command string (for platforms that require it)
  String createShellCommand(String command, List<String> args) {
    final platform = Platform.operatingSystem;
    final shellType = detectShell();

    if (platform == 'windows') {
      if (shellType == 'powershell') {
        // PowerShell command format
        final escapedArgs = args.map((arg) => '"$arg"').join(', ');
        return '$command $escapedArgs';
      } else {
        // CMD format
        final escapedArgs = args.map((arg) => '"$arg"').join(' ');
        return '$command $escapedArgs';
      }
    } else {
      // Unix shell format
      final escapedArgs = args.map((arg) => _escapeShellArg(arg)).join(' ');
      return '$command $escapedArgs';
    }
  }

  /// Escape a shell argument for Unix shells
  String _escapeShellArg(String arg) {
    if (arg.contains(' ') || arg.contains('\'') || arg.contains('"')) {
      // Escape special characters
      return "'${arg.replaceAll("'", "'\\''")}'";
    }
    return arg;
  }

  /// Prepare environment variables for command execution
  Map<String, String> prepareEnvironment({
    Map<String, String>? additionalVars,
    bool includeSystemEnv = true,
  }) {
    final environment = <String, String>{};

    if (includeSystemEnv) {
      environment.addAll(Platform.environment);
    }

    if (additionalVars != null) {
      environment.addAll(additionalVars);
    }

    return environment;
  }

  /// Validate command before execution
  bool isValidCommand(String command) {
    if (command.isEmpty) return false;
    if (command.contains('\0')) return false; // Null bytes not allowed
    return true;
  }

  /// Create a command summary for logging
  String createCommandSummary(String command, List<String> args) {
    if (args.isEmpty) {
      return command;
    }
    return '$command ${args.join(' ')}';
  }
}

