import 'dart:convert';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';

/// Middleware for logging command execution
class LoggingMiddleware extends CommandMiddleware {
  LoggingMiddleware();

  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    final stopwatch = Stopwatch()..start();
    
    if (!context.quiet) {
      context.logger.info('🚀 Starting command execution...');
    }

    try {
      final result = await next();
      stopwatch.stop();
      
      if (!context.quiet) {
        context.logger.info('✅ Command completed in ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      
      if (!context.quiet) {
        context.logger.err('❌ Command failed after ${stopwatch.elapsedMilliseconds}ms');
        if (context.verbose) {
          context.logger.err('Error: $e');
          context.logger.err('Stack trace: $stackTrace');
        }
      }
      
      rethrow;
    }
  }

  @override
  int get priority => 100; // High priority for logging
}

/// Middleware for collecting performance metrics
class MetricsMiddleware extends CommandMiddleware {
  MetricsMiddleware();

  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await next();
      stopwatch.stop();
      
      // Store metrics in context for later analysis
      final metrics = context.config['metrics'] as Map<String, dynamic>? ?? {};
      metrics['execution_time_ms'] = stopwatch.elapsedMilliseconds;
      metrics['timestamp'] = DateTime.now().toIso8601String();
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Store error metrics
      final metrics = context.config['metrics'] as Map<String, dynamic>? ?? {};
      metrics['execution_time_ms'] = stopwatch.elapsedMilliseconds;
      metrics['error'] = e.toString();
      metrics['timestamp'] = DateTime.now().toIso8601String();
      
      rethrow;
    }
  }

  @override
  int get priority => 200;
}

/// Middleware for handling dry-run/plan mode
class DryRunMiddleware extends CommandMiddleware {
  DryRunMiddleware();

  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    // Check if we're in plan mode
    final args = context.config['args'] as Map<String, dynamic>? ?? {};
    final planMode = args['plan'] as bool? ?? false;
    
    if (planMode) {
      // Return a plan result instead of executing
      return CommandResult.success(
        command: context.config['command_name'] as String? ?? 'unknown',
        message: 'Execution plan generated',
        data: {
          'plan_mode': true,
          'estimated_duration_ms': 1000,
          'operations': _generatePlan(context),
        },
      );
    }
    
    return next();
  }

  List<Map<String, dynamic>> _generatePlan(CommandContext context) {
    // Generate a basic execution plan
    return [
      {
        'operation': 'validate_environment',
        'description': 'Check system prerequisites',
        'estimated_duration_ms': 200,
      },
      {
        'operation': 'execute_command',
        'description': 'Run command logic',
        'estimated_duration_ms': 500,
      },
      {
        'operation': 'cleanup',
        'description': 'Clean up temporary resources',
        'estimated_duration_ms': 100,
      },
    ];
  }

  @override
  int get priority => 50; // High priority to run early
}

/// Middleware for caching command results
class CachingMiddleware extends CommandMiddleware {
  CachingMiddleware();

  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    final cacheKey = _generateCacheKey(context);
    
    // Check if result is cached
    final cachedResult = _getCachedResult(cacheKey);
    if (cachedResult != null) {
      if (!context.quiet) {
        context.logger.info('📋 Using cached result');
      }
      return cachedResult;
    }
    
    // Execute command and cache result
    final result = await next();
    
    if (result != null && _shouldCache(result)) {
      _cacheResult(cacheKey, result);
    }
    
    return result;
  }

  String _generateCacheKey(CommandContext context) {
    final commandName = context.config['command_name'] as String? ?? 'unknown';
    final args = context.config['args'] as Map<String, dynamic>? ?? {};
    
    // Create a hash of command name and arguments
    final keyData = {
      'command': commandName,
      'args': args,
      'working_directory': context.workingDirectory,
    };
    
    return '${commandName}_${keyData.hashCode}';
  }

  CommandResult? _getCachedResult(String key) {
    // Simple in-memory cache - in production, use persistent storage
    return _cache[key];
  }

  void _cacheResult(String key, CommandResult result) {
    _cache[key] = result;
  }

  bool _shouldCache(CommandResult result) {
    // Only cache successful results
    return result.success;
  }

  static final Map<String, CommandResult> _cache = {};

  @override
  int get priority => 300;
}

/// Middleware for rate limiting
class RateLimitingMiddleware extends CommandMiddleware {
  RateLimitingMiddleware({
    this.maxRequestsPerMinute = 60,
  });

  final int maxRequestsPerMinute;

  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    final now = DateTime.now();
    final commandName = context.config['command_name'] as String? ?? 'unknown';
    
    // Clean old entries
    _cleanupOldEntries(now);
    
    // Check rate limit
    final recentRequests = _requestHistory[commandName]?.where(
      (timestamp) => now.difference(timestamp).inMinutes < 1,
    ).length ?? 0;
    
    if (recentRequests >= maxRequestsPerMinute) {
      return CommandResult.error(
        message: 'Rate limit exceeded',
        suggestion: 'Wait a moment before running this command again',
        metadata: {
          'rate_limit': maxRequestsPerMinute,
          'current_requests': recentRequests,
        },
      );
    }
    
    // Record this request
    _requestHistory.putIfAbsent(commandName, () => []).add(now);
    
    return next();
  }

  void _cleanupOldEntries(DateTime now) {
    for (final command in _requestHistory.keys) {
      _requestHistory[command]?.removeWhere(
        (timestamp) => now.difference(timestamp).inMinutes >= 1,
      );
    }
  }

  static final Map<String, List<DateTime>> _requestHistory = {};

  @override
  int get priority => 25; // Very high priority
}
