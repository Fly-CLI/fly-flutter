import 'dart:collection';
import 'dart:convert';

/// Log resource provider for logs://run and logs://build
class LogResourceProvider {
  // In-memory log storage (bounded buffers)
  final _runLogs = <String, Queue<String>>{};
  final _buildLogs = <String, Queue<String>>{};
  
  static const maxLogSize = 100 * 1024; // 100KB per log
  static const maxLogEntries = 1000;
  
  /// Store a log entry for a run
  void storeRunLog(String processId, String logEntry) {
    _storeLog(_runLogs, processId, logEntry);
  }
  
  /// Store a log entry for a build
  void storeBuildLog(String buildId, String logEntry) {
    _storeLog(_buildLogs, buildId, logEntry);
  }
  
  /// Store log entry with size and entry limits
  void _storeLog(Map<String, Queue<String>> store, String id, String entry) {
    if (!store.containsKey(id)) {
      store[id] = Queue<String>();
    }
    
    final queue = store[id]!;
    queue.add(entry);
    
    // Trim if too many entries
    while (queue.length > maxLogEntries) {
      queue.removeFirst();
    }
    
    // Check total size and trim if needed
    var totalSize = 0;
    for (final log in queue) {
      totalSize += utf8.encode(log).length;
    }
    
    while (totalSize > maxLogSize && queue.isNotEmpty) {
      final removed = queue.removeFirst();
      totalSize -= utf8.encode(removed).length;
    }
  }
  
  /// List available log resources
  Map<String, Object?> listLogs({
    String? prefix,
    int? page,
    int? pageSize,
  }) {
    final allLogs = <Map<String, Object?>>[];
    
    final prefixFilter = prefix ?? '';
    final pageNum = page ?? 0;
    final pageSizeNum = pageSize ?? 100;
    
    // Add run logs
    for (final entry in _runLogs.entries) {
      if (prefixFilter.isEmpty || entry.key.startsWith(prefixFilter)) {
        final totalSize = entry.value.fold<int>(
          0,
          (sum, log) => sum + utf8.encode(log).length,
        );
        allLogs.add({
          'uri': 'logs://run/${entry.key}',
          'size': totalSize,
          'entries': entry.value.length,
        });
      }
    }
    
    // Add build logs
    for (final entry in _buildLogs.entries) {
      if (prefixFilter.isEmpty || entry.key.startsWith(prefixFilter)) {
        final totalSize = entry.value.fold<int>(
          0,
          (sum, log) => sum + utf8.encode(log).length,
        );
        allLogs.add({
          'uri': 'logs://build/${entry.key}',
          'size': totalSize,
          'entries': entry.value.length,
        });
      }
    }
    
    // Sort and paginate
    allLogs.sort((a, b) => (a['uri'] as String).compareTo(b['uri'] as String));
    final start = pageNum * pageSizeNum;
    final end = (start + pageSizeNum) > allLogs.length ? allLogs.length : (start + pageSizeNum);
    final slice = start < allLogs.length ? allLogs.sublist(start, end) : <Map<String, Object?>>[];
    
    return {
      'items': slice,
      'total': allLogs.length,
      'page': pageNum,
      'pageSize': pageSizeNum,
    };
  }
  
  /// Read a log resource
  Map<String, Object?> readLog(String uri, {int? start, int? length}) {
    if (uri.startsWith('logs://run/')) {
      final processId = uri.replaceFirst('logs://run/', '');
      final logs = _runLogs[processId];
      if (logs == null) {
        throw StateError('Run log not found: $processId');
      }
      return _readLog(logs, start: start, length: length);
    } else if (uri.startsWith('logs://build/')) {
      final buildId = uri.replaceFirst('logs://build/', '');
      final logs = _buildLogs[buildId];
      if (logs == null) {
        throw StateError('Build log not found: $buildId');
      }
      return _readLog(logs, start: start, length: length);
    } else {
      throw StateError('Invalid log URI: $uri');
    }
  }
  
  Map<String, Object?> _readLog(Queue<String> logs, {int? start, int? length}) {
    // Convert queue to list for slicing
    final logList = logs.toList();
    final logText = logList.join('\n');
    final logBytes = utf8.encode(logText);
    
    final startPos = (start ?? 0).clamp(0, logBytes.length);
    final endPos = length != null 
        ? (startPos + length).clamp(startPos, logBytes.length)
        : logBytes.length;
    
    final sliced = logBytes.sublist(startPos, endPos);
    final content = utf8.decode(sliced, allowMalformed: true);
    
    return {
      'content': content,
      'encoding': 'utf-8',
      'total': logBytes.length,
      'start': startPos,
      'length': sliced.length,
    };
  }
  
  /// Clear old logs (cleanup)
  void clearOldLogs({Duration? maxAge}) {
    // Simple implementation: just clear all if maxAge is provided
    // In production, you'd track timestamps and remove old entries
    if (maxAge != null) {
      _runLogs.clear();
      _buildLogs.clear();
    }
  }
}

