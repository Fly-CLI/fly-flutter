import 'package:args/args.dart';
import 'package:fly_cli/src/core/cli/interfaces/i_context_factory.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_execution_context.dart';
import 'package:fly_cli/src/core/command/foundation/infrastructure/command_context_impl.dart';
import 'package:fly_cli/src/core/command/foundation/infrastructure/interactive_prompt.dart';
import 'package:fly_cli/src/core/diagnostics/system_checker.dart';
import 'package:fly_cli/src/core/path_management/path_resolver.dart';
import 'package:fly_cli/src/core/telemetry/domain/metrics_collector.dart';
import 'package:fly_cli/src/core/generation/template/template_manager.dart';
import 'package:mason_logger/mason_logger.dart';

/// Command execution context providing access to dependencies and configuration
///
/// ## Context Lifecycle
///
/// CommandContext instances have two distinct phases:
///
/// 1. **Registration Phase**: Context created during command setup with empty args.
///    Used only for command initialization, not execution.
///
/// 2. **Execution Phase**: Context updated with actual command arguments at runtime.
///    Used by validators, middleware, and command logic.
///
/// See [CommandContextImpl] for detailed lifecycle documentation.
abstract class CommandContext {
  /// The parsed arguments for the current command.
  ///
  /// **Note**: This field is immutable after context creation. Contexts are created
  /// with the appropriate args for their lifecycle phase:
  /// - Registration contexts: Created with empty args for command setup only
  /// - Execution contexts: Created with actual parsed args, immutable from creation
  ArgResults get argResults;

  /// Logger instance for command output
  Logger get logger;

  /// Template manager for code generation
  TemplateManager get templateManager;

  /// System checker for environment validation
  SystemChecker get systemChecker;

  /// Interactive prompt for user input
  InteractivePrompt get interactivePrompt;

  /// Path resolver for all path operations
  PathResolver get pathResolver;

  /// Metrics collector for performance telemetry
  MetricsCollector get metricsCollector;

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

  /// Context factory for creating new contexts with different arguments.
  ///
  /// This factory allows commands to create new execution contexts
  /// with actual parsed arguments during command execution.
  IContextFactory get factory;

  /// Get a service from the service container.
  ///
  /// This method provides access to services registered in the DI container.
  /// It delegates to the factory's service container.
  ///
  /// [T] - The type of service to retrieve
  ///
  /// Returns the service instance, or throws if not registered.
  T getService<T>();

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

  /// Get the command execution context (if available)
  ///
  /// Returns the [CommandExecutionContext] associated with the current command execution,
  /// which provides structured tracking of execution state including:
  /// - Phase transitions (validation → middleware → execution → completion)
  /// - Duration tracking per phase
  /// - Cancellation support
  /// - Execution metadata
  ///
  /// Returns `null` if no execution context has been set. The execution context is typically
  /// created at the start of command execution and stored via [setData]('execution_context', context).
  ///
  /// **Usage Examples:**
  /// ```dart
  /// final executionContext = context.executionContext;
  /// if (executionContext != null) {
  ///   // Check if cancelled
  ///   if (executionContext.isCancelled) {
  ///     return CommandResult.error(message: 'Operation was cancelled');
  ///   }
  ///
  ///   // Track phase transitions
  ///   executionContext.setPhase(ExecutionPhase.middleware);
  ///
  ///   // Get execution duration
  ///   final elapsed = executionContext.elapsed;
  /// }
  /// ```
  ///
  /// **Best Practices:**
  /// - Always check for null before using execution context
  /// - Use execution context for structured tracking instead of scattered setData calls
  /// - Respect cancellation token for long-running operations
  CommandExecutionContext? get executionContext;
}
