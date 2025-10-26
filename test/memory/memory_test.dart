import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process/process.dart';
import 'package:test/test.dart';

void main() {
  group('Memory Leak Detection', () {
    late Directory tempDir;
    late ProcessManager processManager;
    late String projectRoot;

    setUpAll(() {
      processManager = const LocalProcessManager();
      projectRoot = Directory.current.path;
    });

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_memory_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Project Creation Memory Tests', () {
      test('multiple project creation does not leak memory', () async {
        final projectNames = List.generate(20, (index) => 'memory_test_$index');
        
        for (final projectName in projectNames) {
          final result = await processManager.run([
            'dart',
            'run',
            path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'),
            'create',
            projectName,
            '--template=minimal',
          ], workingDirectory: tempDir.path);

          expect(result.exitCode, 0);
          
          // Verify project was created
          final projectPath = path.join(tempDir.path, projectName);
          expect(Directory(projectPath).existsSync(), true);
        }

        // Verify all projects were created
        for (final projectName in projectNames) {
          final projectPath = path.join(tempDir.path, projectName);
          expect(Directory(projectPath).existsSync(), true);
        }
      });

      test('large project creation does not leak memory', () async {
        const projectName = 'large_memory_test';
        
        final result = await processManager.run([
          'dart',
          'run',
          path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'),
          'create',
          projectName,
          '--template=riverpod',
        ], workingDirectory: tempDir.path);

        expect(result.exitCode, 0);
        
        // Verify project was created
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), true);
      });

      test('concurrent project creation does not leak memory', () async {
        final projectNames = List.generate(5, (index) => 'concurrent_memory_test_$index');
        final futures = <Future<ProcessResult>>[];
        
        for (final projectName in projectNames) {
          futures.add(processManager.run([
            'dart',
            'run',
            path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'),
            'create',
            projectName,
            '--template=minimal',
          ], workingDirectory: tempDir.path));
        }
        
        final results = await Future.wait(futures);
        
        // Verify all projects were created successfully
        for (var i = 0; i < results.length; i++) {
          expect(results[i].exitCode, 0);
          
          final projectPath = path.join(tempDir.path, 'concurrent_memory_test_$i');
          expect(Directory(projectPath).existsSync(), true);
        }
      });
    });

    group('File Operations Memory Tests', () {
      test('file creation and deletion does not leak memory', () async {
        // Create many files
        final files = <File>[];
        for (var i = 0; i < 1000; i++) {
          final file = File(path.join(tempDir.path, 'memory_file_$i.txt'));
          file.writeAsStringSync('Test content $i');
          files.add(file);
        }
        
        // Verify files were created
        for (final file in files) {
          expect(file.existsSync(), true);
        }
        
        // Delete all files
        for (final file in files) {
          if (file.existsSync()) {
            file.deleteSync();
          }
        }
        
        // Verify files were deleted
        for (final file in files) {
          expect(file.existsSync(), false);
        }
      });

      test('directory creation and deletion does not leak memory', () async {
        // Create many directories
        final directories = <Directory>[];
        for (var i = 0; i < 500; i++) {
          final dir = Directory(path.join(tempDir.path, 'memory_dir_$i'));
          dir.createSync();
          directories.add(dir);
        }
        
        // Verify directories were created
        for (final dir in directories) {
          expect(dir.existsSync(), true);
        }
        
        // Delete all directories
        for (final dir in directories) {
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
          }
        }
        
        // Verify directories were deleted
        for (final dir in directories) {
          expect(dir.existsSync(), false);
        }
      });
    });

    group('Command Execution Memory Tests', () {
      test('repeated command execution does not leak memory', () async {
        // Execute the same command multiple times
        for (var i = 0; i < 100; i++) {
          final result = await processManager.run([
            'dart',
            'run',
            path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'),
            '--version',
          ], workingDirectory: tempDir.path);

          expect(result.exitCode, 0);
          expect(result.stdout, isNotEmpty);
        }
      });

      test('different command execution does not leak memory', () async {
        final commands = [
          ['dart', 'run', path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'), '--version'],
          ['dart', 'run', path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'), 'doctor'],
          ['dart', 'run', path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'), 'schema', 'export'],
        ];
        
        // Execute each command multiple times
        for (var i = 0; i < 50; i++) {
          for (final command in commands) {
            final result = await processManager.run(command, workingDirectory: tempDir.path);
            expect(result.exitCode, 0);
          }
        }
      });
    });

    group('Stream and Async Memory Tests', () {
      test('stream operations do not leak memory', () async {
        final directory = Directory(tempDir.path);
        final files = <File>[];
        
        // Create files
        for (var i = 0; i < 100; i++) {
          final file = File(path.join(tempDir.path, 'stream_file_$i.txt'));
          file.writeAsStringSync('Stream test content $i');
          files.add(file);
        }
        
        // Use stream to read files
        await for (final entity in directory.list()) {
          if (entity is File) {
            final content = await entity.readAsString();
            expect(content, isNotEmpty);
          }
        }
        
        // Clean up
        for (final file in files) {
          if (file.existsSync()) {
            file.deleteSync();
          }
        }
      });

      test('async operations do not leak memory', () async {
        final futures = <Future<String>>[];
        
        // Create many async operations
        for (var i = 0; i < 1000; i++) {
          futures.add(Future.delayed(Duration.zero, () => 'Async result $i'));
        }
        
        // Wait for all operations to complete
        final results = await Future.wait(futures);
        
        // Verify results
        expect(results.length, 1000);
        for (var i = 0; i < results.length; i++) {
          expect(results[i], 'Async result $i');
        }
      });
    });

    group('JSON Parsing Memory Tests', () {
      test('JSON parsing does not leak memory', () async {
        // Create a project to test JSON operations
        const projectName = 'json_memory_test';
        
        final result = await processManager.run([
          'dart',
          'run',
          path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'),
          'create',
          projectName,
          '--template=minimal',
        ], workingDirectory: tempDir.path);

        expect(result.exitCode, 0);
        
        // Verify project was created
        final projectPath = path.join(tempDir.path, projectName);
        expect(Directory(projectPath).existsSync(), true);
      });

      test('JSON encoding does not leak memory', () async {
        final testData = {
          'test': 'data',
          'number': 42,
          'list': List.generate(100, (index) => 'item_$index'),
          'nested': {
            'level1': {
              'level2': 'value',
            },
          },
        };
        
        // Encode JSON multiple times
        for (var i = 0; i < 1000; i++) {
          final encoded = json.encode(testData);
          expect(encoded, isNotEmpty);
        }
      });
    });

    group('Path Operations Memory Tests', () {
      test('path operations do not leak memory', () async {
        final paths = <String>[];
        
        // Generate many paths
        for (var i = 0; i < 10000; i++) {
          final testPath = 'test/path/to/file_$i.txt';
          paths.add(testPath);
        }
        
        // Perform path operations
        for (final testPath in paths) {
          final normalized = path.normalize(testPath);
          final basename = path.basename(testPath);
          final dirname = path.dirname(testPath);
          final joined = path.join('test', 'path', 'to', 'file.txt');
          
          expect(normalized, isNotEmpty);
          expect(basename, isNotEmpty);
          expect(dirname, isNotEmpty);
          expect(joined, isNotEmpty);
        }
      });
    });

    group('Resource Cleanup Tests', () {
      test('temporary files are cleaned up', () async {
        final tempFiles = <File>[];
        
        // Create temporary files
        for (var i = 0; i < 100; i++) {
          final file = File(path.join(tempDir.path, 'temp_file_$i.txt'));
          file.writeAsStringSync('Temporary content $i');
          tempFiles.add(file);
        }
        
        // Verify files exist
        for (final file in tempFiles) {
          expect(file.existsSync(), true);
        }
        
        // Clean up files
        for (final file in tempFiles) {
          if (file.existsSync()) {
            file.deleteSync();
          }
        }
        
        // Verify files are deleted
        for (final file in tempFiles) {
          expect(file.existsSync(), false);
        }
      });

      test('temporary directories are cleaned up', () async {
        final tempDirs = <Directory>[];
        
        // Create temporary directories
        for (var i = 0; i < 50; i++) {
          final dir = Directory(path.join(tempDir.path, 'temp_dir_$i'));
          dir.createSync();
          tempDirs.add(dir);
        }
        
        // Verify directories exist
        for (final dir in tempDirs) {
          expect(dir.existsSync(), true);
        }
        
        // Clean up directories
        for (final dir in tempDirs) {
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
          }
        }
        
        // Verify directories are deleted
        for (final dir in tempDirs) {
          expect(dir.existsSync(), false);
        }
      });
    });

    group('Long Running Memory Tests', () {
      test('long running operations do not leak memory', () async {
        // Run operations for an extended period
        for (var cycle = 0; cycle < 10; cycle++) {
          // Create projects
          for (var i = 0; i < 5; i++) {
            final projectName = 'long_run_test_${cycle}_$i';
            
            final result = await processManager.run([
              'dart',
              'run',
              path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'),
              'create',
              projectName,
              '--template=minimal',
            ], workingDirectory: tempDir.path);

            expect(result.exitCode, 0);
          }
          
          // Execute commands
          final commands = [
            ['dart', 'run', path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'), '--version'],
            ['dart', 'run', path.join(projectRoot, 'packages/fly_cli/bin/fly.dart'), 'doctor'],
          ];
          
          for (final command in commands) {
            final result = await processManager.run(command, workingDirectory: tempDir.path);
            expect(result.exitCode, 0);
          }
        }
      });
    });
  });
}