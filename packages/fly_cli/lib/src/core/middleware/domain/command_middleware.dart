import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';

/// Represents a single step in the command processing pipeline.
///
/// Middleware follows the Express.js/Koa.js pattern - simple, composable, and powerful.
/// Each middleware can:
/// - Perform actions before or after the command's core logic
/// - Modify the context or result
/// - Short-circuit execution by returning early (not calling next)
///
/// **Usage Example:**
/// ```dart
/// class MyMiddleware implements CommandMiddleware {
///   @override
///   int get priority => MiddlewarePriority.defaultPriority;
///
///   @override
///   Future<CommandResult?> handle(
///     CommandContext context,
///     Future<CommandResult?> Function() next,
///   ) async {
///     // Pre-processing
///     context.logger.info('Before command execution');
///
///     // Execute next middleware or command
///     final result = await next();
///
///     // Post-processing
///     context.logger.info('After command execution');
///
///     return result;
///   }
/// }
/// ```
abstract class CommandMiddleware {
  /// Processes the command through this middleware.
  ///
  /// [context] - The command execution context with all dependencies
  /// [next] - Function to invoke the next middleware in the pipeline,
  ///          or the command's execute method if this is the last middleware
  ///
  /// Returns the [CommandResult] from the pipeline, or null if the pipeline
  /// should continue.
  ///
  /// **To short-circuit execution:** Return a result without calling [next].
  /// **To continue execution:** Call [next] and return its result (possibly modified).
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  );

  /// Priority for middleware execution (lower numbers execute first).
  ///
  /// Use constants from [MiddlewarePriority] for consistency.
  /// Middleware with the same priority are executed in the order they were added.
  int get priority => 0;
}
