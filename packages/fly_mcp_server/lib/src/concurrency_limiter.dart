import 'dart:async';

/// Limits concurrent execution of operations
class ConcurrencyLimiter {
  /// Creates a concurrency limiter with optional configuration
  ConcurrencyLimiter({
    int maxConcurrency = 10,
    Map<String, int>? perToolLimits,
  })  : _maxConcurrency = maxConcurrency,
        _perToolLimits = perToolLimits ?? <String, int>{};

  final int _maxConcurrency;
  final Map<String, int> _toolConcurrency = {};
  final Map<String, int> _perToolLimits;

  /// Current total concurrent operations
  int get currentConcurrency {
    return _toolConcurrency.values.fold(0, (sum, count) => sum + count);
  }

  /// Current concurrent operations for a specific tool
  int getToolConcurrency(String toolName) {
    return _toolConcurrency[toolName] ?? 0;
  }

  /// Check if a new operation can start
  ///
  /// Returns true if both global and per-tool limits allow the operation.
  bool canStart(String toolName) {
    // Check global limit
    if (currentConcurrency >= _maxConcurrency) {
      return false;
    }

    // Check per-tool limit
    final toolLimit = _perToolLimits[toolName];
    if (toolLimit != null && getToolConcurrency(toolName) >= toolLimit) {
      return false;
    }

    return true;
  }

  /// Register that an operation started
  void start(String toolName) {
    _toolConcurrency[toolName] = (getToolConcurrency(toolName)) + 1;
  }

  /// Register that an operation completed
  void complete(String toolName) {
    final current = getToolConcurrency(toolName);
    if (current > 0) {
      _toolConcurrency[toolName] = current - 1;
      if (_toolConcurrency[toolName] == 0) {
        _toolConcurrency.remove(toolName);
      }
    }
  }

  /// Execute a function with concurrency limiting
  Future<T> execute<T>(
    String toolName,
    Future<T> Function() computation,
  ) async {
    if (!canStart(toolName)) {
      throw ConcurrencyLimitException(
        'Maximum concurrency reached for tool: $toolName',
        toolName: toolName,
        current: getToolConcurrency(toolName),
        limit: _perToolLimits[toolName] ?? _maxConcurrency,
      );
    }

    start(toolName);
    try {
      return await computation();
    } finally {
      complete(toolName);
    }
  }
}

/// Exception thrown when concurrency limit is exceeded
class ConcurrencyLimitException implements Exception {
  /// Creates a concurrency limit exception
  ConcurrencyLimitException(
    this.message, {
    required this.toolName,
    required this.current,
    required this.limit,
  });

  /// Error message
  final String message;

  /// Tool name that exceeded the limit
  final String toolName;

  /// Current number of concurrent operations for this tool
  final int current;

  /// Maximum allowed concurrent operations for this tool
  final int limit;

  @override
  String toString() => message;
}
