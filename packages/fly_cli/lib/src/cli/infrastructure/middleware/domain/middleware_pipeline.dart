import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'command_middleware.dart';

/// Interface for middleware pipeline execution.
///
/// The pipeline orchestrates middleware execution in priority order,
/// following the Express.js/Koa.js middleware pattern.
abstract class MiddlewarePipeline {
  /// Executes the middleware pipeline with the given context.
  ///
  /// [context] - The command execution context
  /// [commandExecute] - The command's core execution logic (called after all middleware)
  ///
  /// Returns the final [CommandResult] from the pipeline.
  ///
  /// **Execution Flow:**
  /// 1. Sort all middleware by priority (ascending)
  /// 2. Execute each middleware in order
  /// 3. Each middleware calls [next] to continue to the next middleware
  /// 4. Last middleware calls [commandExecute] to run the command
  /// 5. Results bubble back through middleware (reverse order)
  Future<CommandResult?> execute(
    CommandContext context,
    Future<CommandResult?> Function() commandExecute,
  );
}
