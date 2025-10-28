import 'dart:io';

/// Utility class for file operations with caching and streaming
class FileUtils {
  static final Map<String, String> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Read file content with caching
  static Future<String?> readFile(File file) async {
    final path = file.path;
    final now = DateTime.now();

    // Check cache first
    if (_cache.containsKey(path)) {
      final timestamp = _cacheTimestamps[path]!;
      if (now.difference(timestamp) < _cacheExpiry) {
        return _cache[path];
      } else {
        _cache.remove(path);
        _cacheTimestamps.remove(path);
      }
    }

    try {
      final content = await _readFileWithStreaming(file);
      if (content != null) {
        _cache[path] = content;
        _cacheTimestamps[path] = now;
      }
      return content;
    } catch (e) {
      return null;
    }
  }

  /// Read file content using streaming for large files
  static Future<String?> _readFileWithStreaming(File file) async {
    try {
      final stat = await file.stat();
      
      // For small files, read normally
      if (stat.size < 1024 * 1024) { // Less than 1MB
        return await file.readAsString();
      }

      // For larger files, use streaming
      final buffer = StringBuffer();
      final stream = file.openRead();
      
      await for (final chunk in stream) {
        buffer.write(String.fromCharCodes(chunk));
        
        // Prevent excessive memory usage
        if (buffer.length > 10 * 1024 * 1024) { // 10MB limit
          return null;
        }
      }
      
      return buffer.toString();
    } catch (e) {
      return null;
    }
  }

  /// Count lines in a file efficiently
  static Future<int> countLines(File file) async {
    try {
      final stat = await file.stat();
      
      // For small files, read normally
      if (stat.size < 1024 * 1024) { // Less than 1MB
        final content = await file.readAsString();
        return content.split('\n').length;
      }

      // For larger files, use streaming
      int lineCount = 0;
      final stream = file.openRead();
      
      await for (final chunk in stream) {
        final content = String.fromCharCodes(chunk);
        lineCount += content.split('\n').length - 1; // -1 because split creates extra element
      }
      
      return lineCount + 1; // +1 for the last line
    } catch (e) {
      return 0;
    }
  }

  /// Check if file exists and is readable
  static Future<bool> isReadable(File file) async {
    try {
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Clear the file cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cached_files': _cache.length,
      'cache_size_bytes': _cache.values.fold(0, (sum, content) => sum + content.length),
      'oldest_entry': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
    };
  }
}

/// Utility class for retry operations with exponential backoff
class RetryUtils {
  /// Execute a function with retry logic
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 50),
    Duration maxDelay = const Duration(seconds: 5),
    bool Function(Object)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries) {
          rethrow;
        }

        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // Exponential backoff with jitter
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(
            initialDelay.inMilliseconds,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }

    throw Exception('Retry operation failed after $maxRetries attempts');
  }

  /// Execute multiple operations in parallel with retry
  static Future<List<T?>> retryAll<T>(
    List<Future<T> Function()> operations, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
  }) async {
    final results = <T?>[];
    
    for (int i = 0; i < operations.length; i++) {
      try {
        final result = await retry(
          operations[i],
          maxRetries: maxRetries,
          initialDelay: initialDelay,
        );
        results.add(result);
      } catch (e) {
        results.add(null);
      }
    }
    
    return results;
  }
}

/// Utility class for consistent error handling
class ErrorHandler {
  /// Handle analyzer errors consistently
  static T handleAnalyzerError<T>(
    String analyzerName,
    Object error, {
    T? defaultValue,
    bool logError = true,
  }) {
    if (logError) {
      // In a real implementation, this would use a proper logger
      print('Error in $analyzerName: $error');
    }

    if (defaultValue != null) {
      return defaultValue;
    }

    throw AnalyzerException('$analyzerName failed: $error');
  }

  /// Handle file operation errors
  static T? handleFileError<T>(
    String operation,
    String filePath,
    Object error, {
    bool logError = true,
  }) {
    if (logError) {
      print('File $operation failed for $filePath: $error');
    }
    return null;
  }

  /// Handle network operation errors
  static T? handleNetworkError<T>(
    String operation,
    String url,
    Object error, {
    bool logError = true,
  }) {
    if (logError) {
      print('Network $operation failed for $url: $error');
    }
    return null;
  }
}

/// Custom exception for analyzer errors
class AnalyzerException implements Exception {
  final String message;
  final String? analyzerName;
  final Object? originalError;

  AnalyzerException(this.message, {this.analyzerName, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer('AnalyzerException');
    if (analyzerName != null) {
      buffer.write(' in $analyzerName');
    }
    buffer.write(': $message');
    if (originalError != null) {
      buffer.write(' (Original: $originalError)');
    }
    return buffer.toString();
  }
}
