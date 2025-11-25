import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/middleware_priority.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';
import 'package:fly_cli/src/features/commands/infrastructure/command_context_impl.dart';

/// Mandatory dry-run middleware that always runs first.
///
/// Short-circuits execution when plan mode (--plan flag) is active,
/// returning a simulated execution plan instead of running the command.
class DryRunMiddleware implements CommandMiddleware {
  @override
  int get priority => MiddlewarePriority.dryRun;

  @override
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  ) async {
    // Check if plan mode is enabled
    final planMode = context.planMode;

    // Also check if --plan flag is in the raw arguments as a fallback
    final hasPlanFlag = context.argResults.arguments.contains('--plan');

    if (planMode || hasPlanFlag) {
      // Get command name from argResults or fallback
      final cmdName =
          context.argResults.command?.name ??
          (context is CommandContextImpl ? context.commandName : null) ??
          'unknown';

      // Short-circuit ALL subsequent operations when plan mode is active
      return CommandResult.success(
        command: cmdName,
        message:
            'Execution plan generated (dry-run) - showing estimated files and duration',
        data: {
          'estimated_files': _estimateFiles(context),
          'estimated_duration_ms': _estimateDuration(context),
          'plan_details':
              'This command would normally execute with the given arguments. No changes were made.',
          'arguments': context.argResults.arguments,
          'options': context.argResults.options
              .map((e) => {e: context.argResults[e]})
              .toList(),
          'dry_run': true,
        },
        nextSteps: [
          NextStep(
            command: 'fly $cmdName [args]',
            description: 'Run the command without --plan to execute',
          ),
        ],
      );
    }

    // Continue to next middleware
    return next();
  }

  /// Estimate number of files that would be generated
  int _estimateFiles(CommandContext context) {
    final commandName = context.argResults.command?.name ?? '';

    switch (commandName) {
      case 'create':
        return 15; // Typical Flutter project
      case 'screen':
        return 3; // Screen + optional viewmodel + test
      case 'service':
        return 2; // Service + optional test
      case 'widget':
        return 2; // Widget + optional test
      default:
        return 1;
    }
  }

  /// Estimate duration in milliseconds
  int _estimateDuration(CommandContext context) {
    final commandName = context.argResults.command?.name ?? '';

    switch (commandName) {
      case 'create':
        return 5000; // 5 seconds for project creation
      case 'screen':
        return 1000; // 1 second for screen generation
      case 'service':
        return 800; // 0.8 seconds for service generation
      case 'widget':
        return 600; // 0.6 seconds for widget generation
      default:
        return 500;
    }
  }
}
