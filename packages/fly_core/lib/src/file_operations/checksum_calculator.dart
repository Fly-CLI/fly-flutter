import 'dart:convert';
import 'dart:io';

/// Calculator for file checksums
/// 
/// Provides utilities for calculating checksums of files and data
/// to ensure data integrity.
class ChecksumCalculator {
  const ChecksumCalculator();

  /// Calculate a simple checksum for a string
  /// 
  /// Returns a deterministic hash based on the content.
  String calculateForString(String content) {
    return content.hashCode.toString();
  }

  /// Calculate checksum for a list of strings
  /// 
  /// Combines the strings and calculates a checksum.
  String calculateForList(List<String> items) {
    final combined = items.join(',');
    return combined.hashCode.toString();
  }

  /// Calculate checksum for a file
  /// 
  /// Uses the file's modification time and size as a simple checksum.
  /// For production, consider using a proper hash algorithm.
  Future<String> calculateForFile(File file) async {
    try {
      if (!await file.exists()) {
        return '';
      }

      final stat = await file.stat();
      final content = await file.readAsString();
      
      // Combine size, modification time, and content hash
      return '${stat.size}-${stat.modified.millisecondsSinceEpoch}-${content.hashCode}';
    } catch (e) {
      return '';
    }
  }

  /// Calculate checksum for a map/object data
  String calculateForMap(Map<String, dynamic> data) {
    // Sort keys to ensure deterministic output
    final sortedKeys = data.keys.toList()..sort();
    final sortedData = {
      for (final key in sortedKeys)
        key: data[key],
    };
    
    return json.encode(sortedData).hashCode.toString();
  }

  /// Validate that two checksums match
  bool validate(String expected, String actual) {
    return expected == actual;
  }
}

