import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/middleware/domain/middleware_priority.dart';

/// Mandatory metrics middleware that always runs.
///
/// Collects performance metrics for command execution using MetricsCollector.
class MetricsMiddleware implements CommandMiddleware {
  @override
  int get priority => MiddlewarePriority.metrics;

  @override
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  ) async {
    final stopwatch = Stopwatch()..start();
    final commandName = context.argResults.command?.name ?? 'root';
    final metricsCollector = context.metricsCollector;

    try {
      final result = await next();
      stopwatch.stop();

      if (result != null) {
        // Record metrics using MetricsCollector
        metricsCollector.recordDuration(
          'command.execution',
          stopwatch.elapsedMilliseconds,
          tags: {
            'command': commandName,
            'success': result.success.toString(),
          },
        );

        metricsCollector.incrementCounter(
          'command.executions',
          tags: {'command': commandName},
        );

        // Store in context for backward compatibility
        context.setData('execution_time_ms', stopwatch.elapsedMilliseconds);
        context.setData('command_name', commandName);
        context.setData('success', result.success);
      }

      return result;
    } catch (e, st) {
      stopwatch.stop();

      // Record error metrics
      metricsCollector.recordError(
        'command.execution',
        e.toString(),
        tags: {
          'command': commandName,
          'error_type': e.runtimeType.toString(),
        },
      );

      metricsCollector.incrementCounter(
        'command.errors',
        tags: {'command': commandName},
      );

      context.setData('execution_time_ms', stopwatch.elapsedMilliseconds);
      context.setData('error', e.toString());
      rethrow;
    }
  }
}
