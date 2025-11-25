import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';

/// Optional middleware for progress tracking during command execution
///
/// This middleware automatically manages progress indicators for commands:
/// - Starts progress tracking when execution begins
/// - Updates progress during long-running operations
/// - Completes progress tracking when execution finishes
///
/// Commands can use `context.executionContext?.progressTracker` to manually
/// update progress if needed.
class ProgressMiddleware implements CommandMiddleware {
  @override
  int get priority => 100; // Lower priority than mandatory middleware

  @override
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  ) async {
    final executionContext = context.executionContext;
    final progressTracker = executionContext?.progressTracker;

    // Start progress if tracker is available
    if (progressTracker != null && !progressTracker.isActive) {
      final commandName = context.argResults.command?.name ?? 'root';
      progressTracker.start('Executing $commandName...');
    }

    try {
      final result = await next();

      // Complete progress if successful
      if (progressTracker != null && progressTracker.isActive) {
        if (result != null && result.success) {
          progressTracker.complete('Completed successfully');
        } else if (result != null && !result.success) {
          progressTracker.stop('Failed: ${result.message}');
        }
      }

      return result;
    } catch (e) {
      // Stop progress on error
      if (progressTracker != null && progressTracker.isActive) {
        progressTracker.stop('Error: $e');
      }
      rethrow;
    }
  }
}
