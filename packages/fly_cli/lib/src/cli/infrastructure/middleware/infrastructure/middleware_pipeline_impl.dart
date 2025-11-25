import 'package:fly_cli/src/cli/infrastructure/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/cli/infrastructure/middleware/domain/middleware_pipeline.dart';
import 'package:fly_cli/src/features/commands/domain/command_context.dart';
import 'package:fly_cli/src/features/commands/domain/command_result.dart';

/// Concrete implementation of MiddlewarePipeline.
///
/// Executes middleware in priority order following the Express.js/Koa.js pattern.
/// Middleware are sorted by priority (ascending) and executed in a chain.
class MiddlewarePipelineImpl implements MiddlewarePipeline {
  MiddlewarePipelineImpl({
    required List<CommandMiddleware> middleware,
  }) : _middleware = List.unmodifiable(middleware);

  final List<CommandMiddleware> _middleware;

  @override
  Future<CommandResult?> execute(
    CommandContext context,
    Future<CommandResult?> Function() commandExecute,
  ) async {
    // Sort middleware by priority (ascending - lower priority executes first)
    final sorted = List<CommandMiddleware>.from(_middleware)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    // Build the pipeline chain in reverse order (like Express.js)
    // The last middleware wraps commandExecute, each previous middleware wraps the next
    Future<CommandResult?> Function() next = commandExecute;

    for (var i = sorted.length - 1; i >= 0; i--) {
      final middleware = sorted[i];
      final previousNext = next;
      next = () => middleware.handle(context, previousNext);
    }

    // Execute the pipeline chain
    return next();
  }

  /// Get all middleware in execution order (sorted by priority)
  List<CommandMiddleware> get middleware {
    final sorted = List<CommandMiddleware>.from(_middleware)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return List.unmodifiable(sorted);
  }

  /// Get the number of middleware in the pipeline
  int get length => _middleware.length;
}
