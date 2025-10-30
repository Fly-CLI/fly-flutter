import 'dart:io';
import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';

/// Environment information for command execution
class Environment {
  const Environment({
    required this.isWindows,
    required this.isMacOS,
    required this.isLinux,
    required this.isUnix,
    required this.pathSeparator,
    required this.homeDirectory,
    required this.tempDirectory,
  });

  final bool isWindows;
  final bool isMacOS;
  final bool isLinux;
  final bool isUnix;
  final String pathSeparator;
  final String homeDirectory;
  final String tempDirectory;

  factory Environment.current() {
    return Environment(
      isWindows: Platform.isWindows,
      isMacOS: Platform.isMacOS,
      isLinux: Platform.isLinux,
      isUnix: Platform.isLinux || Platform.isMacOS,
      pathSeparator: Platform.pathSeparator,
      homeDirectory: Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '',
      tempDirectory: Directory.systemTemp.path,
    );
  }
}

/// Concrete implementation of CommandContext
class CommandContextImpl implements CommandContext {
   CommandContextImpl({
    required this.argResults,
    required this.logger,
    required this.templateManager,
    required this.systemChecker,
    required this.interactivePrompt,
    required this.pathResolver,
    required this.config,
    required this.environment,
    required this.workingDirectory,
    required this.verbose,
    required this.quiet,
  });

  @override
  final ArgResults argResults;

  @override
  final Logger logger;

  @override
  final TemplateManager templateManager;

  @override
  final SystemChecker systemChecker;

  @override
  final InteractivePrompt interactivePrompt;

  @override
  final PathResolver pathResolver;

  @override
  final Map<String, dynamic> config;

  @override
  final Environment environment;

  @override
  final String workingDirectory;

  @override
  final bool verbose;

  @override
  final bool quiet;

  final Map<String, dynamic> _data = {};

  @override
  bool get jsonOutput => argResults['output'] == 'json';

  @override
  bool get aiOutput => argResults['output'] == 'ai';

  @override
  bool get planMode {
    try {
      return argResults['plan'] == true;
    } catch (e) {
      return false;
    }
  }


  @override
  String getErrorSuggestion(Object error) => _getErrorSuggestion(error);

  @override
  void setData(String key, dynamic value) {
    _data[key] = value;
  }

  @override
  dynamic getData(String key) {
    return _data[key];
  }

  String _getErrorSuggestion(Object error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('permission')) {
      return 'Try running with elevated permissions or check file permissions';
    } else if (errorString.contains('network')) {
      return 'Check your internet connection and try again';
    } else if (errorString.contains('not found')) {
      return 'Make sure Flutter is installed and in your PATH';
    } else if (errorString.contains('template')) {
      return 'Run "fly doctor" to check your setup or try a different template';
    }
    return 'Run "fly doctor" to diagnose system issues';
  }
}
