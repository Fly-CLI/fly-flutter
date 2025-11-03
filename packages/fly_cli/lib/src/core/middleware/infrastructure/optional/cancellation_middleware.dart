import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_core/fly_core.dart';
import 'package:fly_mcp/fly_mcp.dart';

/// Optional middleware for cancellation support during command execution
///
/// This middleware:
/// - Checks for cancellation before and during execution
/// - Propagates cancellation status through the execution pipeline
/// - Returns a cancelled result if cancellation was requested
/// - Handles graceful cleanup on cancellation
class CancellationMiddleware implements CommandMiddleware {
  @override
  int get priority => 50; // Medium priority - run before execution but after metrics

  @override
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  ) async {
    final executionContext = context.executionContext;

    // Check for cancellation before starting
    if (executionContext != null && executionContext.isCancelled) {
      return CommandResult.error(
        message: 'Command execution was cancelled',
        suggestion: 'The command was cancelled before execution started',
        executionDurationMs: executionContext.elapsedMs,
        executionPhase: executionContext.currentPhase,
        wasCancelled: true,
      );
    }

    try {
      final result = await next();

      // Check for cancellation after execution
      if (executionContext != null && executionContext.isCancelled) {
        // Return cancelled result if execution completed but was cancelled
        return result?.copyWith(
              wasCancelled: true,
            ) ??
            CommandResult.error(
              message: 'Command execution was cancelled',
              suggestion: 'The command was cancelled during execution',
              executionDurationMs: executionContext.elapsedMs,
              executionPhase: executionContext.currentPhase,
              wasCancelled: true,
            );
      }

      return result;
    } catch (e) {
      // If exception is CancellationException, handle gracefully
      if (e is CancellationException) {
        if (executionContext != null) {
          return CommandResult.error(
            message: 'Command execution was cancelled: ${e.message}',
            suggestion: 'The operation was cancelled by the user',
            executionDurationMs: executionContext.elapsedMs,
            executionPhase: executionContext.currentPhase,
            wasCancelled: true,
          );
        }
      }

      // Re-throw other exceptions
      rethrow;
    }
  }
}

