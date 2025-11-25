import 'dart:io';

import 'package:fly_cli/src/generation/infrastructure/adapters/ifile_system_adapter.dart';
import 'package:path/path.dart' as path;

/// Implementation of IFileSystemAdapter using Dart's dart:io.
class FileSystemAdapter implements IFileSystemAdapter {
  const FileSystemAdapter();

  @override
  Future<bool> directoryExists(String path) async {
    return Directory(path).exists();
  }

  @override
  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }

  @override
  Future<void> createDirectory(String dirPath, {bool recursive = true}) async {
    await Directory(dirPath).create(recursive: recursive);
  }

  @override
  Future<String> readFile(String filePath) async {
    return File(filePath).readAsString();
  }

  @override
  Future<void> writeFile(String filePath, String contents) async {
    await File(filePath).writeAsString(contents);
  }

  @override
  Future<List<String>> listDirectory(
    String dirPath, {
    bool recursive = false,
  }) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return [];
    }

    if (!recursive) {
      return dir.list().map((entity) => entity.path).toList();
    }

    final files = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      files.add(entity.path);
    }
    return files;
  }

  @override
  Future<void> delete(String path, {bool recursive = false}) async {
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: recursive);
    } else if (entity == FileSystemEntityType.file) {
      await File(path).delete();
    }
  }

  @override
  String absolute(String filePath) {
    return path.absolute(filePath);
  }

  @override
  String join(String part1, String part2, [String? part3, String? part4]) {
    if (part4 != null) {
      return path.join(part1, part2, part3!, part4);
    } else if (part3 != null) {
      return path.join(part1, part2, part3);
    }
    return path.join(part1, part2);
  }

  @override
  String dirname(String filePath) {
    return path.dirname(filePath);
  }

  @override
  bool isAbsolute(String filePath) {
    return path.isAbsolute(filePath);
  }
}
