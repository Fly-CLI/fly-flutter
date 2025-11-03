import 'package:fly_cli/src/core/command/foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command/foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/middleware/domain/command_middleware.dart';
import 'package:fly_cli/src/core/middleware/domain/middleware_priority.dart';

/// Optional middleware for rate limiting commands.
///
/// Can be added to commands that need rate limiting protection.
class RateLimitingMiddleware implements CommandMiddleware {
  RateLimitingMiddleware({Duration? rateLimit})
      : _rateLimit = rateLimit ?? const Duration(seconds: 1);

  final Map<String, DateTime> _lastExecution = {};
  final Duration _rateLimit;

  @override
  int get priority => MiddlewarePriority.rateLimiting;

  @override
  Future<CommandResult?> handle(
    CommandContext context,
    Future<CommandResult?> Function() next,
  ) async {
    final commandName = context.argResults.command?.name ?? 'root';
    final now = DateTime.now();

    if (_lastExecution.containsKey(commandName)) {
      final lastExec = _lastExecution[commandName]!;
      if (now.difference(lastExec) < _rateLimit) {
        return CommandResult.error(
          message: 'Rate limit exceeded for command: $commandName',
          suggestion:
              'Please wait ${_rateLimit.inSeconds} seconds before running this command again',
        );
      }
    }

    _lastExecution[commandName] = now;
    return next();
  }

  /// Clear rate limit tracking (useful for testing)
  void clear() {
    _lastExecution.clear();
  }
}
