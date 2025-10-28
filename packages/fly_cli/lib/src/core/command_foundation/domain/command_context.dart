import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/command_context_impl.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';
import 'package:fly_cli/src/core/command_foundation/infrastructure/interactive_prompt.dart';

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
  /// 
  /// This method enables middleware and commands to share execution metadata and state
  /// throughout the command lifecycle. Data set here persists for the duration of the
  /// command execution and can be accessed by any middleware or lifecycle hook that
  /// runs after the data is set.
  /// 
  /// **Usage Examples:**
  /// ```dart
  /// // In middleware - set execution metadata
  /// context.setData('execution_time_ms', stopwatch.elapsedMilliseconds);
  /// context.setData('command_name', context.argResults.command?.name ?? 'root');
  /// 
  /// // In lifecycle hooks - access shared data
  /// final executionTime = context.getData('execution_time_ms') as int?;
  /// ```
  /// 
  /// **Best Practices:**
  /// - Use descriptive keys with prefixes to avoid collisions (e.g., 'metrics.execution_time')
  /// - Store only serializable data types (String, int, bool, Map, List)
  /// - Consider thread-safety when accessing data from multiple middleware
  /// - Clean up sensitive data after use
  void setData(String key, dynamic value);

  /// Allows retrieving data set in the context.
  /// 
  /// Retrieves data previously stored using [setData]. Returns `null` if the key
  /// doesn't exist. Use type casting to convert the returned value to the expected type.
  /// 
  /// **Usage Examples:**
  /// ```dart
  /// // Retrieve and cast data
  /// final executionTime = context.getData('execution_time_ms') as int?;
  /// final commandName = context.getData('command_name') as String?;
  /// 
  /// // Safe retrieval with default value
  /// final timeout = context.getData('timeout_ms') as int? ?? 5000;
  /// ```
  /// 
  /// **Thread Safety:**
  /// This method is safe to call from any middleware or lifecycle hook, but be aware
  /// that data may be modified by other middleware running concurrently.
  dynamic getData(String key);
}

