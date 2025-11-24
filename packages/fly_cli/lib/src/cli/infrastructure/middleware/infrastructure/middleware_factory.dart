import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/middleware_pipeline.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/infrastructure/middleware_pipeline_impl.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/infrastructure/mandatory/dry_run_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/infrastructure/mandatory/logging_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/infrastructure/mandatory/metrics_middleware.dart';

/// Factory for creating middleware pipelines.
///
/// Follows the factory pattern like MetricsFactory, creating configured
/// pipelines with mandatory middleware and optional command-specific middleware.
class MiddlewareFactory {
  /// Creates a middleware pipeline with mandatory middleware and optional middleware.
  ///
  /// [context] - The command execution context (used for context-aware middleware)
  /// [optional] - Optional command-specific middleware to include
  ///
  /// Returns a configured [MiddlewarePipeline] ready for execution.
  static MiddlewarePipeline create({
    required CommandContext context,
    List<CommandMiddleware> optional = const [],
  }) {
    // Mandatory middleware always included (sorted by priority)
    final mandatory = [
      DryRunMiddleware(), // Priority -100 (runs first)
      LoggingMiddleware(), // Priority 20
      MetricsMiddleware(), // Priority 30
    ];

    // Combine mandatory and optional middleware
    final allMiddleware = <CommandMiddleware>[
      ...mandatory,
      ...optional,
    ];

    return MiddlewarePipelineImpl(middleware: allMiddleware);
  }

  /// Creates a minimal pipeline with only mandatory middleware.
  ///
  /// Useful for testing or when no optional middleware is needed.
  static MiddlewarePipeline createMinimal(CommandContext context) {
    return create(context: context, optional: []);
  }
}
