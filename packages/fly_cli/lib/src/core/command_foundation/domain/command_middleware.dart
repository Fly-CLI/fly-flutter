import 'command_context.dart';
import 'command_result.dart';

/// Represents a single step in the command processing pipeline.
/// Middleware can perform actions before or after the command's core logic,
/// modify the context, or even short-circuit execution.
abstract class CommandMiddleware {
  /// Processes the command.
  /// [context] provides access to command arguments, logger, etc.
  /// [next] is a function that invokes the next middleware in the pipeline, or the command's execute method if this is the last middleware.
  Future<CommandResult?> handle(CommandContext context, Future<CommandResult?> Function() next);

  /// Determines if this middleware should run for the given context and command.
  /// Default implementation returns true (runs for all commands).
  bool shouldRun(CommandContext context, String commandName) => true;

  /// Priority for middleware execution (lower numbers execute first).
  int get priority => 0;
}

/// Type alias for the next middleware function in the pipeline.
typedef NextMiddleware = Future<CommandResult?> Function();

/// Manages and executes a chain of [CommandMiddleware].
class MiddlewarePipeline {
  final List<CommandMiddleware> _middleware = [];

  /// Adds a middleware to the pipeline.
  void add(CommandMiddleware middleware) {
    _middleware.add(middleware);
  }

  /// Executes the pipeline with the given context and the command's core execution logic.
  Future<CommandResult?> execute(CommandContext context, Future<CommandResult?> Function() commandExecute) async {
    Future<CommandResult?> Function() next = commandExecute;

    // Build the pipeline in reverse order
    for (var i = _middleware.length - 1; i >= 0; i--) {
      final currentMiddleware = _middleware[i];
      final previousNext = next;
      next = () => currentMiddleware.handle(context, previousNext);
    }

    return next();
  }
}

/// Middleware for logging command execution details.
class LoggingMiddleware implements CommandMiddleware {
  @override
  int get priority => 10;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

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

/// Middleware for collecting performance metrics.
class MetricsMiddleware implements CommandMiddleware {
  @override
  int get priority => 20;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

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

/// Middleware to handle 'plan' mode (dry-run).
class DryRunMiddleware implements CommandMiddleware {
  @override
  int get priority => 5;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<CommandResult?> handle(CommandContext context, Future<CommandResult?> Function() next) async {
    if (context.planMode) {
      // Instead of executing the actual command, return a plan.
      return CommandResult.success(
        command: context.argResults.command?.name ?? 'unknown',
        message: 'Execution plan generated (dry-run)',
        data: {
          'plan_details': 'This command would normally execute with the given arguments. No changes were made.',
          'arguments': context.argResults.arguments,
          'options': context.argResults.options.map((e) => {e: context.argResults[e]}).toList(),
        },
        nextSteps: [
          NextStep(
            command: 'fly ${context.argResults.command?.name ?? 'command'} [args]',
            description: 'Run the command without --plan to execute',
          ),
        ],
      );
    }
    return next();
  }
}

/// Middleware for caching command results.
class CachingMiddleware implements CommandMiddleware {
  final Map<String, CommandResult> _cache = {};

  @override
  int get priority => 15;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<CommandResult?> handle(CommandContext context, Future<CommandResult?> Function() next) async {
    // Generate cache key based on command and arguments
    final cacheKey = _generateCacheKey(context);
    
    // Check if result is cached
    if (_cache.containsKey(cacheKey)) {
      context.logger.detail('Using cached result for command: ${context.argResults.command?.name}');
      return _cache[cacheKey]!;
    }
    
    // Execute command and cache result
    final result = await next();
    if (result != null) {
      _cache[cacheKey] = result;
    }
    
    return result;
  }

  String _generateCacheKey(CommandContext context) {
    final commandName = context.argResults.command?.name ?? 'root';
    final args = context.argResults.arguments.join(' ');
    return '$commandName:$args';
  }
}

/// Middleware for rate limiting commands.
class RateLimitingMiddleware implements CommandMiddleware {
  final Map<String, DateTime> _lastExecution = {};
  final Duration _rateLimit;

  RateLimitingMiddleware({Duration? rateLimit}) : _rateLimit = rateLimit ?? const Duration(seconds: 1);

  @override
  int get priority => 1;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<CommandResult?> handle(CommandContext context, Future<CommandResult?> Function() next) async {
    final commandName = context.argResults.command?.name ?? 'root';
    final now = DateTime.now();
    
    if (_lastExecution.containsKey(commandName)) {
      final lastExec = _lastExecution[commandName]!;
      if (now.difference(lastExec) < _rateLimit) {
        return CommandResult.error(
          message: 'Rate limit exceeded for command: $commandName',
          suggestion: 'Please wait ${_rateLimit.inSeconds} seconds before running this command again',
        );
      }
    }
    
    _lastExecution[commandName] = now;
    return next();
  }
}