import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/middleware_priority.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';

/// Mandatory logging middleware that always runs.
///
/// Logs command execution start, completion, and errors with timing information.
class LoggingMiddleware implements CommandMiddleware {
  @override
  int get priority => MiddlewarePriority.logging;

  @override
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  ) async {
    final stopwatch = Stopwatch()..start();
    final commandName = context.argResults.command?.name ?? 'root';

    context.logger.detail(
      'Executing command: $commandName with args: ${context.argResults.arguments}',
    );

    try {
      final result = await next();
      stopwatch.stop();

      if (result != null) {
        context.logger.detail(
          'Command $commandName completed in ${stopwatch.elapsedMilliseconds}ms with status: ${result.success ? 'SUCCESS' : 'FAILURE'}',
        );
      }

      return result;
    } catch (e, st) {
      stopwatch.stop();
      context.logger.err(
        'Command $commandName failed in ${stopwatch.elapsedMilliseconds}ms with error: $e',
      );
      context.logger.detail(st.toString());
      rethrow;
    }
  }
}
