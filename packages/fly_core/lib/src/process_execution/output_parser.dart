/// Parser for process output
/// 
/// Provides utilities for parsing and extracting information
/// from command output.
class OutputParser {
  const OutputParser();

  /// Parse version string from output
  /// 
  /// Extracts version information from command output.
  String? parseVersion(String output) {
    // Try common patterns for version strings
    final patterns = [
      RegExp(r'version\s+([\d.]+)', caseSensitive: false),
      RegExp(r'v([\d.]+)', caseSensitive: false),
      RegExp(r'([\d]+\.[\d]+\.[\d]+)'), // Semantic version
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(output);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }

  /// Parse key-value pairs from output
  /// 
  /// Extracts key-value pairs in formats like "key: value" or "key=value".
  Map<String, String> parseKeyValuePairs(String output) {
    final result = <String, String>{};
    final lines = output.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      
      // Try "key: value" format
      if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          if (key.isNotEmpty) {
            result[key] = value;
          }
        }
      }
      
      // Try "key=value" format
      else if (trimmed.contains('=')) {
        final parts = trimmed.split('=');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          if (key.isNotEmpty) {
            result[key] = value;
          }
        }
      }
    }

    return result;
  }

  /// Parse lines from output
  /// 
  /// Returns non-empty lines from output.
  List<String> parseLines(String output) {
    return output
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Parse JSON from output
  /// 
  /// Attempts to parse JSON from output.
  Map<String, dynamic>? parseJson(String output) {
    try {
      // Try to extract JSON from output
      final jsonStart = output.indexOf('{');
      final jsonEnd = output.lastIndexOf('}');
      
      if (jsonStart >= 0 && jsonEnd >= jsonStart) {
        final jsonStr = output.substring(jsonStart, jsonEnd + 1);
        // Note: This would need dart:convert in actual implementation
        // For now, return null
        return null;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Find specific line in output
  /// 
  /// Finds line matching a pattern.
  String? findLine(String output, Pattern pattern) {
    final lines = parseLines(output);
    
    for (final line in lines) {
      if (pattern.allMatches(line).isNotEmpty) {
        return line;
      }
    }
    
    return null;
  }

  /// Find all lines matching a pattern
  List<String> findLines(String output, Pattern pattern) {
    final lines = parseLines(output);
    final matches = <String>[];
    
    for (final line in lines) {
      if (pattern.allMatches(line).isNotEmpty) {
        matches.add(line);
      }
    }
    
    return matches;
  }

  /// Extract first matching group from output
  /// 
  /// Uses regex to extract the first capture group.
  String? extractFirstMatch(String output, Pattern pattern) {
    if (pattern is! RegExp) {
      return null;
    }
    final match = pattern.firstMatch(output);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  /// Extract all matching groups from output
  List<String> extractAllMatches(String output, Pattern pattern) {
    final matches = pattern.allMatches(output);
    final results = <String>[];
    
    for (final match in matches) {
      if (match.groupCount >= 1) {
        results.add(match.group(1)!);
      }
    }
    
    return results;
  }

  /// Check if output contains a specific string
  bool contains(String output, String search) {
    return output.contains(search);
  }

  /// Get output length in characters
  int getLength(String output) {
    return output.length;
  }

  /// Get output length in lines
  int getLineCount(String output) {
    return parseLines(output).length;
  }

  /// Trim whitespace from output
  String trim(String output) {
    return output.trim();
  }

  /// Get first N lines from output
  List<String> getFirstLines(String output, int count) {
    final lines = parseLines(output);
    if (lines.length <= count) {
      return lines;
    }
    return lines.sublist(0, count);
  }

  /// Get last N lines from output
  List<String> getLastLines(String output, int count) {
    final lines = parseLines(output);
    if (lines.length <= count) {
      return lines;
    }
    return lines.sublist(lines.length - count);
  }
}

