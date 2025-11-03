import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/middleware/domain/middleware_priority.dart';

/// Optional middleware for caching command results.
///
/// Can be added to commands that benefit from result caching.
class CachingMiddleware implements CommandMiddleware {
  CachingMiddleware();

  final Map<String, CommandResult> _cache = {};

  @override
  int get priority => MiddlewarePriority.caching;

  @override
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  ) async {
    // Generate cache key based on command and arguments
    final cacheKey = _generateCacheKey(context);

    // Check if result is cached
    if (_cache.containsKey(cacheKey)) {
      context.logger.detail(
          'Using cached result for command: ${context.argResults.command?.name}');
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

  /// Clear the cache (useful for testing)
  void clear() {
    _cache.clear();
  }
}
