import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';

/// Middleware that cannot be skipped and always runs
/// 
/// This interface ensures that certain middleware (like DryRun)
/// always executes regardless of command configuration.
abstract class MandatoryMiddleware extends CommandMiddleware {
  @override
  bool shouldRun(CommandContext context, String commandName) => true; // Sealed - cannot be overridden
}

/// Middleware pipeline that ALWAYS executes mandatory middleware
class MandatoryMiddlewarePipeline {
  MandatoryMiddlewarePipeline({
    required this.optional,
  });

  /// Core middleware that cannot be skipped
  List<MandatoryMiddleware> get mandatory => [
    DryRunMandatoryMiddleware(),  // Always first to check plan mode
    LoggingMandatoryMiddleware(),
    MetricsMandatoryMiddleware(),
  ];

  /// Command-specific optional middleware
  final List<CommandMiddleware> optional;

  /// Get all middleware in execution order
  List<CommandMiddleware> getAllMiddleware() {
    final all = <CommandMiddleware>[];
    all.addAll(mandatory);
    all.addAll(optional);
    return all;
  }

  /// Validate that required mandatory middleware are present
  void validate() {
    final mandatoryTypes = mandatory.map((m) => m.runtimeType).toSet();
    final requiredTypes = {
      DryRunMandatoryMiddleware,
      LoggingMandatoryMiddleware,
      MetricsMandatoryMiddleware,
    };

    for (final requiredType in requiredTypes) {
      if (!mandatoryTypes.contains(requiredType)) {
        throw InvalidMiddlewarePipelineException(
          'Missing required mandatory middleware: $requiredType'
        );
      }
    }
  }
}

/// Exception thrown when middleware pipeline is invalid
class InvalidMiddlewarePipelineException implements Exception {
  const InvalidMiddlewarePipelineException(this.message);
  final String message;

  @override
  String toString() => 'InvalidMiddlewarePipelineException: $message';
}

/// Mandatory dry-run middleware that always runs first
class DryRunMandatoryMiddleware extends MandatoryMiddleware {
  @override
  int get priority => -100; // Run before everything

  @override
  Future<CommandResult?> handle(CommandContext context, Future<CommandResult?> Function() next) async {
    // Check if plan mode is enabled
    final planMode = context.planMode;
    
    // Also check if --plan flag is in the raw arguments as a fallback
    final hasPlanFlag = context.argResults.arguments.contains('--plan') || 
                       context.argResults.options.contains('plan');
    
    if (planMode || hasPlanFlag) {
      // Short-circuit ALL subsequent operations when plan mode is active
      return CommandResult.success(
        command: context.argResults.command?.name ?? 'unknown',
        message: 'Execution plan generated (dry-run) - showing estimated files and duration',
        data: {
          'estimated_files': _estimateFiles(context),
          'estimated_duration_ms': _estimateDuration(context),
          'plan_details': 'This command would normally execute with the given arguments. No changes were made.',
          'arguments': context.argResults.arguments,
          'options': context.argResults.options.map((e) => {e: context.argResults[e]}).toList(),
          'dry_run': true,
        },
        nextSteps: [
          NextStep(
            command: 'fly ${context.argResults.command?.name ?? 'command'} [args]',
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

/// Mandatory logging middleware
class LoggingMandatoryMiddleware extends MandatoryMiddleware {
  @override
  int get priority => 10;

  @override
  Future<CommandResult?> handle(CommandContext context, Future<CommandResult?> Function() next) async {
    final stopwatch = Stopwatch()..start();
    context.logger.detail('Executing command: ${context.argResults.command?.name ?? 'root'} with args: ${context.argResults.arguments}');

    try {
      final result = await next();
      stopwatch.stop();
      if (result != null) {
        context.logger.detail('Command ${context.argResults.command?.name ?? 'root'} completed in ${stopwatch.elapsedMilliseconds}ms with status: ${result.success ? 'SUCCESS' : 'FAILURE'}');
      }
      return result;
    } catch (e, st) {
      stopwatch.stop();
      context.logger.err('Command ${context.argResults.command?.name ?? 'root'} failed in ${stopwatch.elapsedMilliseconds}ms with error: $e');
      context.logger.detail(st.toString());
      rethrow;
    }
  }
}

/// Mandatory metrics middleware
class MetricsMandatoryMiddleware extends MandatoryMiddleware {
  @override
  int get priority => 20;

  @override
  Future<CommandResult?> handle(CommandContext context, Future<CommandResult?> Function() next) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await next();
      stopwatch.stop();
      
      if (result != null) {
        // Store metrics in context for later use
        context.setData('execution_time_ms', stopwatch.elapsedMilliseconds);
        context.setData('command_name', context.argResults.command?.name ?? 'root');
        context.setData('success', result.success);
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      context.setData('execution_time_ms', stopwatch.elapsedMilliseconds);
      context.setData('error', e.toString());
      rethrow;
    }
  }
}
