import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../../features/doctor/domain/system_checker.dart';
import '../../templates/template_manager.dart';
import '../../utils/interactive_prompt.dart';

/// Command execution context providing access to dependencies and configuration
abstract class CommandContext {
  /// The parsed arguments for the current command.
  ArgResults get argResults;

  /// Logger instance for command output
  Logger get logger;
  
  /// Template manager for code generation
  TemplateManager get templateManager;
  
  /// System checker for environment validation
  SystemChecker get systemChecker;
  
  /// Interactive prompt for user input
  InteractivePrompt get interactivePrompt;
  
  /// Configuration map for command-specific settings
  Map<String, dynamic> get config;
  
  /// Current environment information
  Environment get environment;
  
  /// Working directory for command execution
  String get workingDirectory;
  
  /// Whether command is running in verbose mode
  bool get verbose;
  
  /// Whether command is running in quiet mode
  bool get quiet;

  /// Whether the command is running in JSON output mode.
  bool get jsonOutput;

  /// Whether the command is running in AI-optimized output mode.
  bool get aiOutput;

  /// Whether the command is running in plan mode (dry-run).
  bool get planMode;

  /// Provides helpful suggestions for common errors.
  String getErrorSuggestion(Object error);

  /// Allows setting data that can be accessed by subsequent middleware or lifecycle hooks.
  void setData(String key, dynamic value);

  /// Allows retrieving data set in the context.
  dynamic getData(String key);
}

