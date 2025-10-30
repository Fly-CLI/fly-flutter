import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Single source of truth for temporary filesystem used by tests.
///
/// Lifecycle:
/// - Call [initSuite] once (e.g., in setUpAll) to create the suite root.
/// - Call [beforeEach] before each test to create a clean per-test directory.
/// - Call [afterEach] after each test to clean up the per-test directory.
/// - Call [cleanupSuite] once (e.g., in tearDownAll) to remove the suite root.
class TestTempDir {
  Directory? _suiteRoot;
  Directory? _currentTestDir;
  int _testCounter = 0;

  /// Absolute path to the suite root directory.
  Directory get root {
    final dir = _suiteRoot;
    if (dir == null) {
      throw StateError('TestTempDir not initialized. Call initSuite() first.');
    }
    return dir;
  }

  /// Absolute path to the current test directory.
  Directory get currentTestDir {
    final dir = _currentTestDir;
    if (dir == null) {
      throw StateError('No current test directory. Call beforeEach() first.');
    }
    return dir;
  }

  /// Initialize the suite-scoped root directory.
  ///
  /// The root for all tests is `<project>/test_generated` to ensure
  /// a stable, repo-local location rather than OS temp paths.
  Future<void> initSuite() async {
    if (_suiteRoot != null) return;
    final projectRoot = Directory.current.path;
    final testRootPath = p.join(projectRoot, 'test_generated');
    final dir = Directory(testRootPath);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    _suiteRoot = dir;
  }

  /// Create a fresh per-test directory under the suite root.
  Future<void> beforeEach() async {
    if (_suiteRoot == null) {
      throw StateError('initSuite() must be called before beforeEach().');
    }
    _testCounter += 1;
    final name = 'test_${_testCounter.toString().padLeft(4, '0')}';
    final dir = Directory(p.join(root.path, name));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _currentTestDir = await dir.create(recursive: true);
  }

  /// Clean up the per-test directory.
  Future<void> afterEach() async {
    final dir = _currentTestDir;
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _currentTestDir = null;
  }

  /// Remove the entire suite root directory.
  Future<void> cleanupSuite() async {
    final dir = _suiteRoot;
    _currentTestDir = null;
    _suiteRoot = null;
    if (dir != null && await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Build an absolute path under the suite root from a relative path.
  String path(String relative) {
    return p.normalize(p.join(root.path, relative));
  }

  /// Build an absolute path under the current test directory from a relative path.
  String inCurrent(String relative) {
    return p.normalize(p.join(currentTestDir.path, relative));
  }

  /// Ensure a directory exists under the current test directory.
  Future<Directory> ensureDir(String relative) async {
    final dir = Directory(inCurrent(relative));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Reset the current test directory to an empty state.
  Future<void> resetCurrentTestDir() async {
    final dir = currentTestDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
  }

  /// Ensure a file exists under the current test directory.
  Future<File> ensureFile(String relative) async {
    final file = File(inCurrent(relative));
    await file.parent.create(recursive: true);
    if (!(await file.exists())) {
      await file.create(recursive: true);
    }
    return file;
  }

  /// Write text to a file under the current test directory.
  Future<void> writeText(String relative, String data) async {
    final file = await ensureFile(relative);
    await file.writeAsString(data);
  }

  /// Read text from a file under the current test directory.
  Future<String> readText(String relative) async {
    final file = File(inCurrent(relative));
    return file.readAsString();
  }

  /// Write JSON to a file under the current test directory.
  Future<void> writeJson(String relative, Object jsonObject) async {
    final file = await ensureFile(relative);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonObject));
  }

  /// Read JSON from a file and parse it using [parse].
  Future<T> readJson<T>(String relative, T Function(Object?) parse) async {
    final file = File(inCurrent(relative));
    final contents = await file.readAsString();
    final decoded = jsonDecode(contents);
    return parse(decoded);
  }

  /// Delete a file or directory under the current test directory.
  Future<void> delete(String relative) async {
    final targetPath = inCurrent(relative);
    final entityType = FileSystemEntity.typeSync(targetPath);
    if (entityType == FileSystemEntityType.notFound) return;
    if (entityType == FileSystemEntityType.directory) {
      final dir = Directory(targetPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } else {
      final file = File(targetPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}


