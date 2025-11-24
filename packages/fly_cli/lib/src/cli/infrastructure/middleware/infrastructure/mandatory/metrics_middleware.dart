import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_execution_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/middleware_priority.dart';

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
    final executionContext = context.executionContext;

    try {
      final result = await next();
      stopwatch.stop();

      if (result != null) {
        // Record phase duration in execution context if available
        if (executionContext != null) {
          executionContext.recordPhaseDurationMs(
            ExecutionPhase.execution,
            stopwatch.elapsedMilliseconds,
          );
        }

        // Record metrics using MetricsCollector
        final tags = {
          'command': commandName,
          'success': result.success.toString(),
        };

        // Add execution phase to tags if available
        if (executionContext != null) {
          tags['phase'] = executionContext.currentPhase.name;
        }

        metricsCollector..recordDuration(
          'command.execution',
          stopwatch.elapsedMilliseconds,
          tags: tags,
        )

        ..incrementCounter(
          'command.executions',
          tags: {'command': commandName},
        );

        // Store in context for backward compatibility
        context..setData('execution_time_ms', stopwatch.elapsedMilliseconds)
        ..setData('command_name', commandName)
        ..setData('success', result.success);
      }

      return result;
    } catch (e) {
      stopwatch.stop();

      // Record phase duration in execution context if available
      if (executionContext != null) {
        executionContext.setPhase(ExecutionPhase.error);
        executionContext.recordPhaseDurationMs(
          ExecutionPhase.execution,
          stopwatch.elapsedMilliseconds,
        );
      }

      // Record error metrics
      final tags = {
        'command': commandName,
        'error_type': e.runtimeType.toString(),
      };

      // Add execution phase to tags if available
      if (executionContext != null) {
        tags['phase'] = executionContext.currentPhase.name;
      }

      metricsCollector.recordError(
        'command.execution',
        e.toString(),
        tags: tags,
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
