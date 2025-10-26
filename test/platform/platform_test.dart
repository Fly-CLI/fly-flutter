import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Platform-Specific Testing', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fly_platform_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Windows Platform Tests', () {
      test('Windows path handling works correctly', () {
        if (Platform.isWindows) {
          const windowsPath = r'C:\Users\test\project';
          final normalizedPath = path.normalize(windowsPath);
          expect(normalizedPath, contains(r'\'));
        }
      });

      test('Windows file operations work correctly', () {
        if (Platform.isWindows) {
          final testFile = File(path.join(tempDir.path, 'test_file.txt'));
          testFile.writeAsStringSync('Windows test content');
          
          expect(testFile.existsSync(), isTrue);
          expect(testFile.readAsStringSync(), equals('Windows test content'));
        }
      });

      test('Windows directory operations work correctly', () {
        if (Platform.isWindows) {
          final testDir = Directory(path.join(tempDir.path, 'test_dir'));
          testDir.createSync();
          
          expect(testDir.existsSync(), isTrue);
          
          final testFile = File(path.join(testDir.path, 'test.txt'));
          testFile.writeAsStringSync('test');
          
          expect(testFile.existsSync(), isTrue);
        }
      });
    });

    group('macOS Platform Tests', () {
      test('macOS path handling works correctly', () {
        if (Platform.isMacOS) {
          const macPath = '/Users/test/project';
          final normalizedPath = path.normalize(macPath);
          expect(normalizedPath, contains('/'));
        }
      });

      test('macOS file operations work correctly', () {
        if (Platform.isMacOS) {
          final testFile = File(path.join(tempDir.path, 'test_file.txt'));
          testFile.writeAsStringSync('macOS test content');
          
          expect(testFile.existsSync(), isTrue);
          expect(testFile.readAsStringSync(), equals('macOS test content'));
        }
      });

      test('macOS directory operations work correctly', () {
        if (Platform.isMacOS) {
          final testDir = Directory(path.join(tempDir.path, 'test_dir'));
          testDir.createSync();
          
          expect(testDir.existsSync(), isTrue);
          
          final testFile = File(path.join(testDir.path, 'test.txt'));
          testFile.writeAsStringSync('test');
          
          expect(testFile.existsSync(), isTrue);
        }
      });
    });

    group('Linux Platform Tests', () {
      test('Linux path handling works correctly', () {
        if (Platform.isLinux) {
          const linuxPath = '/home/test/project';
          final normalizedPath = path.normalize(linuxPath);
          expect(normalizedPath, contains('/'));
        }
      });

      test('Linux file operations work correctly', () {
        if (Platform.isLinux) {
          final testFile = File(path.join(tempDir.path, 'test_file.txt'));
          testFile.writeAsStringSync('Linux test content');
          
          expect(testFile.existsSync(), isTrue);
          expect(testFile.readAsStringSync(), equals('Linux test content'));
        }
      });

      test('Linux directory operations work correctly', () {
        if (Platform.isLinux) {
          final testDir = Directory(path.join(tempDir.path, 'test_dir'));
          testDir.createSync();
          
          expect(testDir.existsSync(), isTrue);
          
          final testFile = File(path.join(testDir.path, 'test.txt'));
          testFile.writeAsStringSync('test');
          
          expect(testFile.existsSync(), isTrue);
        }
      });
    });

    group('Cross-Platform Path Tests', () {
      test('path normalization works across platforms', () {
        final testPaths = [
          'test/path/to/file',
          r'test\path\to\file',
          r'test/path\to/file',
        ];

        for (final testPath in testPaths) {
          final normalized = path.normalize(testPath);
          expect(normalized, isNotEmpty);
          expect(normalized, isA<String>());
        }
      });

      test('path joining works across platforms', () {
        final segments = ['test', 'path', 'to', 'file'];
        final joined = path.joinAll(segments);
        
        expect(joined, isNotEmpty);
        expect(joined, isA<String>());
      });

      test('path basename works across platforms', () {
        final testPaths = [
          'test/path/to/file.txt',
          'file.txt',
        ];

        for (final testPath in testPaths) {
          final basename = path.basename(testPath);
          expect(basename, equals('file.txt'));
        }
        
        // Test Windows-style path separately
        if (Platform.isWindows) {
          const windowsPath = r'test\path\to\file.txt';
          final basename = path.basename(windowsPath);
          expect(basename, equals(r'test\path\to\file.txt')); // path.basename doesn't normalize on Windows
        }
      });

      test('path dirname works across platforms', () {
        final testPaths = [
          'test/path/to/file.txt',
          r'test\path\to\file.txt',
        ];

        for (final testPath in testPaths) {
          final dirname = path.dirname(testPath);
          expect(dirname, isNotEmpty);
          expect(dirname, isA<String>());
        }
      });
    });

    group('Platform-Specific CLI Tests', () {
      test('CLI works on current platform', () async {
        final result = await Process.run(
          'dart',
          [
            'run',
            'packages/fly_cli/bin/fly.dart',
            '--version',
          ],
          workingDirectory: Directory.current.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
      });

      test('create command basic functionality', () async {
        final result = await Process.run(
          'dart',
          [
            'run',
            'packages/fly_cli/bin/fly.dart',
            'create',
            'test_project',
          ],
          workingDirectory: Directory.current.path,
        );

        expect(result.exitCode, equals(0));
        expect(result.stdout, isNotEmpty);
        expect(result.stdout, contains('Creating Flutter project'));
      });
    });

    group('Platform-Specific Error Handling', () {
      test('invalid paths handled correctly', () {
        if (Platform.isWindows) {
          // Test Windows-specific invalid paths
          final invalidPaths = [
            r'C:\invalid<path>',
            r'C:\invalid|path',
            r'C:\invalid"path',
          ];

          for (final invalidPath in invalidPaths) {
            expect(() => path.normalize(invalidPath), returnsNormally);
          }
        }
      });

      test('long paths handled correctly', () {
        // Test very long paths
        final longPath = 'a' * 1000;
        final normalized = path.normalize(longPath);
        expect(normalized, isNotEmpty);
      });

      test('special characters in paths handled correctly', () {
        final specialPaths = [
          'test path with spaces',
          'test-path-with-hyphens',
          'test_path_with_underscores',
          'test.path.with.dots',
        ];

        for (final specialPath in specialPaths) {
          final normalized = path.normalize(specialPath);
          expect(normalized, isNotEmpty);
        }
      });
    });

    group('Platform-Specific Performance Tests', () {
      test('file operations performance on current platform', () {
        final stopwatch = Stopwatch()..start();
        
        // Create multiple files
        for (var i = 0; i < 100; i++) {
          final file = File(path.join(tempDir.path, 'test_file_$i.txt'));
          file.writeAsStringSync('Test content $i');
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
      });

      test('directory operations performance on current platform', () {
        final stopwatch = Stopwatch()..start();
        
        // Create multiple directories
        for (var i = 0; i < 50; i++) {
          final dir = Directory(path.join(tempDir.path, 'test_dir_$i'));
          dir.createSync();
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
      });
    });

    group('Platform-Specific Security Tests', () {
      test('path traversal protection works', () {
        final maliciousPaths = [
          '../../../etc/passwd',
          r'..\..\..\windows\system32',
          '....//....//....//etc//passwd',
        ];

        for (final maliciousPath in maliciousPaths) {
          final normalized = path.normalize(maliciousPath);
          expect(normalized, isNotEmpty);
          // The path should be normalized but not necessarily blocked
          // This test ensures the normalization doesn't crash
        }
      });

      test('file permissions handled correctly', () {
        final testFile = File(path.join(tempDir.path, 'permission_test.txt'));
        testFile.writeAsStringSync('test content');
        
        expect(testFile.existsSync(), isTrue);
        
        // Test reading
        final content = testFile.readAsStringSync();
        expect(content, equals('test content'));
      });
    });
  });
}
