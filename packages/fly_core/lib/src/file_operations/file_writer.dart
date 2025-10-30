import 'dart:io';

/// Writer for file operations with atomic writes
/// 
/// Provides safe file writing with atomic operations to prevent
/// corruption during write failures.
class FileWriter {
  const FileWriter();

  /// Write content to a file atomically
  /// 
  /// Creates a temporary file, writes content, then renames to target.
  /// This ensures the target file is only modified if write succeeds.
  Future<bool> writeFileAtomic(File file, String content) async {
    try {
      // Ensure parent directory exists
      await file.parent.create(recursive: true);

      // Create temporary file
      final tempFile = File('${file.path}.tmp');
      
      // Write to temp file
      await tempFile.writeAsString(content);
      
      // Atomic rename
      await tempFile.rename(file.path);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Write content to a file (non-atomic)
  Future<bool> writeFile(File file, String content) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Write bytes to a file
  Future<bool> writeBytes(File file, List<int> bytes) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Append content to a file
  Future<bool> appendToFile(File file, String content) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(content, mode: FileMode.append);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Append bytes to a file
  Future<bool> appendBytes(File file, List<int> bytes) async {
    try {
      await file.parent.create(recursive: true);
      final sink = file.openWrite(mode: FileMode.append);
      sink.add(bytes);
      await sink.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Write to file with mode
  Future<bool> writeFileWithMode(File file, String content, FileMode mode) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(content, mode: mode);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stream content to a file
  Future<bool> streamToFile(File file, Stream<List<int>> content) async {
    try {
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      await content.forEach((chunk) {
        sink.add(chunk);
      });
      await sink.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Copy file contents to another file
  Future<bool> copyFile(File source, File destination, {bool preserveMetadata = false}) async {
    try {
      if (!await source.exists()) {
        return false;
      }

      await destination.parent.create(recursive: true);
      
      if (preserveMetadata) {
        await source.copy(destination.path);
      } else {
        final content = await source.readAsBytes();
        await destination.writeAsBytes(content);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Move a file
  Future<bool> moveFile(File source, File destination) async {
    try {
      if (!await source.exists()) {
        return false;
      }

      await destination.parent.create(recursive: true);
      await source.rename(destination.path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ensure parent directory exists
  Future<Directory> ensureParent(File file, {bool recursive = true}) async {
    return await file.parent.create(recursive: recursive);
  }
}

