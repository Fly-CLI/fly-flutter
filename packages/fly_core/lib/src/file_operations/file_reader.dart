import 'dart:io';

/// Reader for file operations with streaming support
/// 
/// Provides efficient file reading with streaming for large files
/// and automatic fallback to regular reading for small files.
class FileReader {
  /// Threshold for streaming (files larger than this use streaming)
  static const int streamingThreshold = 1024 * 1024; // 1MB

  /// Maximum size to read in memory
  static const int maxSize = 10 * 1024 * 1024; // 10MB

  const FileReader();

  /// Read file content as a string
  /// 
  /// Automatically chooses between streaming and regular reading
  /// based on file size.
  Future<String?> readFile(File file) async {
    try {
      final stat = await file.stat();
      
      // For small files, read normally
      if (stat.size < streamingThreshold) {
        return await file.readAsString();
      }

      // For larger files, use streaming
      return await _readFileWithStreaming(file);
    } catch (e) {
      return null;
    }
  }

  /// Read file content using streaming for large files
  Future<String?> _readFileWithStreaming(File file) async {
    try {
      final buffer = StringBuffer();
      final stream = file.openRead();
      
      await for (final chunk in stream) {
        buffer.write(String.fromCharCodes(chunk));
        
        // Prevent excessive memory usage
        if (buffer.length > maxSize) {
          return null;
        }
      }
      
      return buffer.toString();
    } catch (e) {
      return null;
    }
  }

  /// Count lines in a file efficiently
  Future<int> countLines(File file) async {
    try {
      final stat = await file.stat();
      
      // For small files, read normally
      if (stat.size < streamingThreshold) {
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
  Future<bool> isReadable(File file) async {
    try {
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Read file as bytes
  Future<List<int>?> readBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Read file with a maximum size limit
  Future<String?> readFileWithLimit(File file, int maxBytes) async {
    try {
      final bytes = await readBytes(file);
      if (bytes == null) return null;
      
      if (bytes.length > maxBytes) {
        return String.fromCharCodes(bytes.take(maxBytes));
      }
      
      return String.fromCharCodes(bytes);
    } catch (e) {
      return null;
    }
  }

  /// Stream file content in chunks
  Stream<List<int>> streamFile(File file) {
    try {
      return file.openRead();
    } catch (e) {
      return const Stream.empty();
    }
  }

  /// Get file metadata
  Future<FileMetadata?> getMetadata(File file) async {
    try {
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      return FileMetadata(
        path: file.path,
        size: stat.size,
        modified: stat.modified,
        accessed: stat.accessed,
        mode: stat.mode,
        type: stat.type,
      );
    } catch (e) {
      return null;
    }
  }
}

/// File metadata information
class FileMetadata {
  const FileMetadata({
    required this.path,
    required this.size,
    required this.modified,
    required this.accessed,
    required this.mode,
    required this.type,
  });

  final String path;
  final int size;
  final DateTime modified;
  final DateTime accessed;
  final int mode;
  final FileSystemEntityType type;
}

