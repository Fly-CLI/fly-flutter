/// Interface for file system operations adapter.
///
/// Abstracts file system operations, allowing for easier testing
/// and potential future replacements (e.g., in-memory file system).
abstract class IFileSystemAdapter {
  /// Check if a directory exists.
  Future<bool> directoryExists(String path);

  /// Check if a file exists.
  Future<bool> fileExists(String path);

  /// Create a directory (and parent directories if needed).
  Future<void> createDirectory(String path, {bool recursive = true});

  /// Read file contents as string.
  Future<String> readFile(String path);

  /// Write file contents.
  Future<void> writeFile(String path, String contents);

  /// List directory contents.
  Future<List<String>> listDirectory(String path, {bool recursive = false});

  /// Delete a file or directory.
  Future<void> delete(String path, {bool recursive = false});

  /// Get absolute path.
  String absolute(String path);

  /// Join path segments.
  String join(String part1, String part2, [String? part3, String? part4]);

  /// Get directory name from path.
  String dirname(String path);

  /// Check if path is absolute.
  bool isAbsolute(String path);
}
