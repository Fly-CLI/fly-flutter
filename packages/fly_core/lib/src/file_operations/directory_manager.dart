import 'dart:io';

/// Manager for directory operations
/// 
/// Provides utilities for creating, managing, and operating on directories
/// with proper error handling.
class DirectoryManager {
  const DirectoryManager();

  /// Ensure a directory exists, creating it if necessary
  Future<Directory> ensureExists(String path, {bool recursive = true}) async {
    final directory = Directory(path);
    
    if (await directory.exists()) {
      return directory;
    }
    
    if (recursive) {
      return await directory.create(recursive: true);
    }
    
    return await directory.create();
  }

  /// Ensure a directory exists synchronously
  Directory ensureExistsSync(String path, {bool recursive = true}) {
    final directory = Directory(path);
    
    if (directory.existsSync()) {
      return directory;
    }
    
    if (recursive) {
      directory.createSync(recursive: true);
    } else {
      directory.createSync();
    }
    
    return directory;
  }

  /// Check if a directory exists
  Future<bool> exists(String path) async {
    final directory = Directory(path);
    return await directory.exists();
  }

  /// Check if a directory exists synchronously
  bool existsSync(String path) {
    final directory = Directory(path);
    return directory.existsSync();
  }

  /// Delete a directory
  Future<void> delete(String path, {bool recursive = false}) async {
    final directory = Directory(path);
    await directory.delete(recursive: recursive);
  }

  /// Delete a directory synchronously
  void deleteSync(String path, {bool recursive = false}) {
    final directory = Directory(path);
    directory.deleteSync(recursive: recursive);
  }

  /// Get all files in a directory
  Future<List<File>> listFiles(String path, {bool recursive = false}) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return [];
    }

    final files = <File>[];
    
    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } else {
      await for (final entity in directory.list()) {
        if (entity is File) {
          files.add(entity);
        }
      }
    }
    
    return files;
  }

  /// Get all directories in a directory
  Future<List<Directory>> listDirectories(String path, {bool recursive = false}) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return [];
    }

    final directories = <Directory>[];
    
    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is Directory) {
          directories.add(entity);
        }
      }
    } else {
      await for (final entity in directory.list()) {
        if (entity is Directory) {
          directories.add(entity);
        }
      }
    }
    
    return directories;
  }

  /// Get the size of a directory and all its contents
  Future<int> getSize(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return 0;
    }

    var totalSize = 0;
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }

  /// Get the file count in a directory
  Future<int> getFileCount(String path, {bool recursive = false}) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return 0;
    }

    var count = 0;
    
    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          count++;
        }
      }
    } else {
      await for (final entity in directory.list()) {
        if (entity is File) {
          count++;
        }
      }
    }
    
    return count;
  }
}

