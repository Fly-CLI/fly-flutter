import 'dart:async';
import 'dart:collection';
import 'package:fly_cli/src/core/dependency_injection/domain/service_container.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_result.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_middleware.dart';
import 'package:fly_cli/src/core/command_foundation/application/command_base.dart';
import 'package:fly_cli/src/core/templates/template_manager.dart';

import '../../features/doctor/domain/system_checker.dart';

/// Performance metrics collector
class PerformanceMetrics {
  PerformanceMetrics();

  final Map<String, List<int>> _executionTimes = {};
  final Map<String, int> _executionCounts = {};
  final Map<String, List<String>> _errors = {};

  /// Record command execution time
  void recordExecutionTime(String commandName, int milliseconds) {
    _executionTimes.putIfAbsent(commandName, () => []).add(milliseconds);
    _executionCounts[commandName] = (_executionCounts[commandName] ?? 0) + 1;
  }

  /// Record command error
  void recordError(String commandName, String error) {
    _errors.putIfAbsent(commandName, () => []).add(error);
  }

  /// Get average execution time for a command
  double getAverageExecutionTime(String commandName) {
    final times = _executionTimes[commandName];
    if (times == null || times.isEmpty) return 0.0;
    
    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get execution count for a command
  int getExecutionCount(String commandName) {
    return _executionCounts[commandName] ?? 0;
  }

  /// Get error count for a command
  int getErrorCount(String commandName) {
    return _errors[commandName]?.length ?? 0;
  }

  /// Get all metrics
  Map<String, dynamic> getAllMetrics() {
    final metrics = <String, dynamic>{};
    
    for (final command in _executionTimes.keys) {
      metrics[command] = {
        'execution_count': getExecutionCount(command),
        'average_time_ms': getAverageExecutionTime(command),
        'error_count': getErrorCount(command),
        'success_rate': _calculateSuccessRate(command),
      };
    }
    
    return metrics;
  }

  double _calculateSuccessRate(String commandName) {
    final total = getExecutionCount(commandName);
    final errors = getErrorCount(commandName);
    if (total == 0) return 1.0;
    return (total - errors) / total;
  }

  /// Clear all metrics
  void clear() {
    _executionTimes.clear();
    _executionCounts.clear();
    _errors.clear();
  }
}

/// Lazy loading service container
class LazyServiceContainer extends ServiceContainer {
  LazyServiceContainer();

  final Map<Type, dynamic> _lazyInstances = {};
  final Map<Type, Future<dynamic>> _loadingPromises = {};

  /// Preload a service type
  Future<void> preload<T>() async {
    if (!_lazyInstances.containsKey(T)) {
      try {
        final instance = super.get<T>();
        _lazyInstances[T] = instance;
      } catch (e) {
        // Service not registered or failed to create
        return;
      }
    }
  }

  /// Preload multiple services in parallel
  Future<void> preloadServices<T1, T2>() async {
    await Future.wait([
      preload<T1>(),
      preload<T2>(),
    ]);
  }
}

/// Command result cache
class CommandResultCache {
  CommandResultCache({this.maxSize = 100, this.ttlSeconds = 300});

  final int maxSize;
  final int ttlSeconds;
  final Map<String, _CacheEntry> _cache = {};

  /// Get cached result
  CommandResult? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check TTL
    if (DateTime.now().difference(entry.timestamp).inSeconds > ttlSeconds) {
      _cache.remove(key);
      return null;
    }

    return entry.result;
  }

  /// Cache result
  void put(String key, CommandResult result) {
    // Remove oldest entries if cache is full
    if (_cache.length >= maxSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = _CacheEntry(
      result: result,
      timestamp: DateTime.now(),
    );
  }

  /// Generate cache key from command context
  String generateKey(CommandContext context, Map<String, dynamic> args) {
    final commandName = context.config['command_name'] as String? ?? 'unknown';
    final keyData = {
      'command': commandName,
      'args': args,
      'working_directory': context.workingDirectory,
    };
    
    return '${commandName}_${keyData.hashCode}';
  }

  /// Clear cache
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'max_size': maxSize,
      'ttl_seconds': ttlSeconds,
      'keys': _cache.keys.toList(),
    };
  }
}

class _CacheEntry {
  _CacheEntry({required this.result, required this.timestamp});
  
  final CommandResult result;
  final DateTime timestamp;
}

/// Performance optimizer for command execution
class CommandPerformanceOptimizer {
  CommandPerformanceOptimizer({
    this.enableCaching = true,
    this.enableLazyLoading = true,
    this.enableMetrics = true,
  });

  final bool enableCaching;
  final bool enableLazyLoading;
  final bool enableMetrics;

  late final PerformanceMetrics _metrics = PerformanceMetrics();
  late final CommandResultCache _cache = CommandResultCache();
  late final LazyServiceContainer _container = LazyServiceContainer();

  /// Optimize command execution
  Future<CommandResult> optimizeExecution<T extends FlyCommand>(
    T command,
    Future<CommandResult> Function() execution,
  ) async {
    final stopwatch = Stopwatch()..start();
    final commandName = command.name;

    try {
      // Check cache first
      if (enableCaching) {
        final cacheKey = _cache.generateKey(command.context, {
          'args': command.argResults?.arguments ?? {},
        });
        
        final cachedResult = _cache.get(cacheKey);
        if (cachedResult != null) {
          _recordMetrics(commandName, stopwatch.elapsedMilliseconds);
          return cachedResult;
        }
      }

      // Execute command
      final result = await execution();
      
      // Cache successful results
      if (enableCaching && result.success) {
        final cacheKey = _cache.generateKey(command.context, {
          'args': command.argResults?.arguments ?? {},
        });
        _cache.put(cacheKey, result);
      }

      _recordMetrics(commandName, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      _metrics.recordError(commandName, e.toString());
      _recordMetrics(commandName, stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }

  void _recordMetrics(String commandName, int milliseconds) {
    if (enableMetrics) {
      _metrics.recordExecutionTime(commandName, milliseconds);
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getMetrics() {
    return _metrics.getAllMetrics();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _cache.getStats();
  }

  /// Clear all optimization data
  void clear() {
    _metrics.clear();
    _cache.clear();
  }

  /// Preload critical services
  Future<void> preloadCriticalServices() async {
    if (enableLazyLoading) {
      await _container.preloadServices<Logger, TemplateManager>();
      await _container.preload<SystemChecker>();
    }
  }
}

/// Benchmark utility for measuring performance improvements
class CommandBenchmark {
  CommandBenchmark();

  final Map<String, List<BenchmarkResult>> _results = {};

  /// Run benchmark for a command
  Future<BenchmarkResult> benchmark<T extends FlyCommand>(
    T command,
    Future<CommandResult> Function() execution, {
    int iterations = 10,
  }) async {
    final times = <int>[];
    final errors = <String>[];

    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      
      try {
        await execution();
        stopwatch.stop();
        times.add(stopwatch.elapsedMilliseconds);
      } catch (e) {
        stopwatch.stop();
        errors.add(e.toString());
      }
    }

    final result = BenchmarkResult(
      commandName: command.name,
      iterations: iterations,
      averageTime: times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length,
      minTime: times.isEmpty ? 0 : times.reduce((a, b) => a < b ? a : b),
      maxTime: times.isEmpty ? 0 : times.reduce((a, b) => a > b ? a : b),
      errorCount: errors.length,
      successRate: times.length / iterations,
    );

    _results.putIfAbsent(command.name, () => []).add(result);
    return result;
  }

  /// Compare benchmark results
  Map<String, dynamic> compareResults(String commandName) {
    final commandResults = _results[commandName];
    if (commandResults == null || commandResults.length < 2) {
      return {'error': 'Need at least 2 benchmark runs to compare'};
    }

    final latest = commandResults.last;
    final previous = commandResults[commandResults.length - 2];

    return {
      'command': commandName,
      'latest': latest.toJson(),
      'previous': previous.toJson(),
      'improvement': {
        'average_time_ms': latest.averageTime - previous.averageTime,
        'average_time_percent': ((latest.averageTime - previous.averageTime) / previous.averageTime) * 100,
        'success_rate': latest.successRate - previous.successRate,
      },
    };
  }

  /// Get all benchmark results
  Map<String, dynamic> getAllResults() {
    final results = <String, dynamic>{};
    
    for (final entry in _results.entries) {
      results[entry.key] = entry.value.map((r) => r.toJson()).toList();
    }
    
    return results;
  }
}

class BenchmarkResult {
  BenchmarkResult({
    required this.commandName,
    required this.iterations,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.errorCount,
    required this.successRate,
  });

  final String commandName;
  final int iterations;
  final double averageTime;
  final int minTime;
  final int maxTime;
  final int errorCount;
  final double successRate;

  Map<String, dynamic> toJson() => {
    'command_name': commandName,
    'iterations': iterations,
    'average_time_ms': averageTime,
    'min_time_ms': minTime,
    'max_time_ms': maxTime,
    'error_count': errorCount,
    'success_rate': successRate,
  };
}

/// Performance monitoring middleware
class PerformanceMonitoringMiddleware extends CommandMiddleware {
  PerformanceMonitoringMiddleware(this._optimizer);

  final CommandPerformanceOptimizer _optimizer;

  @override
  Future<CommandResult?> handle(CommandContext context, NextMiddleware next) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await next();
      stopwatch.stop();
      
      // Record performance metrics
      _optimizer._recordMetrics(
        context.config['command_name'] as String? ?? 'unknown',
        stopwatch.elapsedMilliseconds,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Record error metrics
      _optimizer._metrics.recordError(
        context.config['command_name'] as String? ?? 'unknown',
        e.toString(),
      );
      
      rethrow;
    }
  }

  @override
  int get priority => 1000; // Low priority to run last
}
