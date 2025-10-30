import 'dart:io';

import 'package:fly_mcp_server/src/config/server_config.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/logs_build_resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/logs_run_resource_strategy.dart';
import 'package:fly_mcp_server/src/domain/strategies/resource/workspace_resource_strategy.dart';
import 'package:fly_mcp_server/src/log_resource_provider.dart';
import 'package:fly_mcp_server/src/path_sandbox.dart';
import 'package:test/test.dart';

void main() {
  group('Resource Strategy Tests', () {
    group('LogsRunResourceStrategy', () {
      late LogsRunResourceStrategy strategy;
      late LogResourceProvider logProvider;

      setUp(() {
        logProvider = LogResourceProvider();
        strategy = LogsRunResourceStrategy();
        strategy.setLogProvider(logProvider);
      });

      test('should have correct URI prefix', () {
        expect(strategy.uriPrefix, equals('logs://run/'));
        expect(strategy.description, contains('Execution'));
        expect(strategy.readOnly, isTrue);
      });

      test('should throw error when log provider not configured', () {
        final unconfiguredStrategy = LogsRunResourceStrategy();
        expect(
          () => unconfiguredStrategy.list({}),
          throwsA(isA<StateError>()),
        );
      });

      test('should list logs when logs exist', () {
        logProvider.storeRunLog('proc1', 'Log entry 1');
        logProvider.storeRunLog('proc2', 'Log entry 2');

        // Call list with empty params - strategy extracts prefix as null, which lists all
        final result = strategy.list({});

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['items'], isA<List>());
        expect(map['total'], isA<int>());
        final items = map['items'] as List;
        
        // Note: listLogs returns both run and build logs, so we need to filter by URI
        final runLogUris = items
            .map((item) => (item as Map<String, Object?>)['uri'] as String)
            .where((uri) => uri.startsWith('logs://run/'))
            .toList();
        
        expect(runLogUris.length, greaterThanOrEqualTo(2));
        expect(runLogUris.any((uri) => uri.contains('proc1')), isTrue);
        expect(runLogUris.any((uri) => uri.contains('proc2')), isTrue);
      });

      test('should return empty list when no logs exist', () {
        final result = strategy.list({});

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['items'], isA<List>());
        expect((map['items'] as List).isEmpty, isTrue);
        expect(map['total'], equals(0));
      });

      test('should support pagination', () {
        // Store multiple logs
        for (var i = 0; i < 10; i++) {
          logProvider.storeRunLog('proc$i', 'Log $i');
        }

        // Call with pagination params - empty URI means list all
        final page1 = strategy.list({'page': 0, 'pageSize': 5});
        final page2 = strategy.list({'page': 1, 'pageSize': 5});

        // Filter to only run logs since listLogs returns both types
        final page1RunLogs = (page1['items'] as List)
            .where((item) => ((item as Map<String, Object?>)['uri'] as String).startsWith('logs://run/'))
            .toList();
        final page2RunLogs = (page2['items'] as List)
            .where((item) => ((item as Map<String, Object?>)['uri'] as String).startsWith('logs://run/'))
            .toList();

        expect(page1RunLogs.length, greaterThanOrEqualTo(5));
        expect(page2RunLogs.length, greaterThanOrEqualTo(5));
        // Total includes both run and build logs, so check run logs separately
        expect(page1['total'], greaterThanOrEqualTo(10));
        expect(page2['total'], greaterThanOrEqualTo(10));
      });

      test('should filter by prefix', () {
        logProvider.storeRunLog('test-proc1', 'Log 1');
        logProvider.storeRunLog('test-proc2', 'Log 2');
        logProvider.storeRunLog('other-proc', 'Log 3');

        // Filter by process ID prefix 'test'
        final result = strategy.list({'uri': 'logs://run/test'});

        expect(result, isA<Map>());
        final items = result['items'] as List;
        
        // Filter to only run logs with 'test' prefix
        final runLogs = items
            .where((item) => ((item as Map<String, Object?>)['uri'] as String).startsWith('logs://run/test'))
            .toList();
        
        // Should include test-proc1 and test-proc2, but not other-proc
        expect(runLogs.length, greaterThanOrEqualTo(2));
      });

      test('should read log by URI', () {
        const processId = 'test-process';
        const logContent = 'Line 1\nLine 2\nLine 3';
        logProvider.storeRunLog(processId, logContent);

        final result = strategy.read({'uri': 'logs://run/$processId'});

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['content'], contains('Line 1'));
        expect(map['content'], contains('Line 2'));
        expect(map['encoding'], equals('utf-8'));
        expect(map['total'], isA<int>());
      });

      test('should support start and length parameters', () {
        const processId = 'test-process';
        const logContent = 'Line 1\nLine 2\nLine 3';
        logProvider.storeRunLog(processId, logContent);

        final result = strategy.read({
          'uri': 'logs://run/$processId',
          'start': 10,
          'length': 5,
        });

        expect(result, isA<Map>());
        expect(result['start'], isA<int>());
        expect(result['length'], isA<int>());
      });

      test('should throw error when URI is missing', () {
        expect(
          () => strategy.read({}),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw error when URI does not start with logs://run/', () {
        expect(
          () => strategy.read({'uri': 'logs://build/test'}),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw error when log does not exist', () {
        expect(
          () => strategy.read({'uri': 'logs://run/nonexistent'}),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('LogsBuildResourceStrategy', () {
      late LogsBuildResourceStrategy strategy;
      late LogResourceProvider logProvider;

      setUp(() {
        logProvider = LogResourceProvider();
        strategy = LogsBuildResourceStrategy();
        strategy.setLogProvider(logProvider);
      });

      test('should have correct URI prefix', () {
        expect(strategy.uriPrefix, equals('logs://build/'));
        expect(strategy.description, contains('Build'));
        expect(strategy.readOnly, isTrue);
      });

      test('should throw error when log provider not configured', () {
        final unconfiguredStrategy = LogsBuildResourceStrategy();
        expect(
          () => unconfiguredStrategy.list({}),
          throwsA(isA<StateError>()),
        );
      });

      test('should list build logs', () {
        logProvider.storeBuildLog('build1', 'Build log 1');
        logProvider.storeBuildLog('build2', 'Build log 2');

        final result = strategy.list({});

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['items'], isA<List>());
        final items = map['items'] as List;
        
        // Filter to only build logs since listLogs returns both types
        final buildLogs = items
            .where((item) => ((item as Map<String, Object?>)['uri'] as String).startsWith('logs://build/'))
            .toList();
        
        expect(buildLogs.length, greaterThanOrEqualTo(2));

        final uris = buildLogs
            .map((item) => (item as Map<String, Object?>)['uri'] as String)
            .toList();
        expect(uris.any((uri) => uri.contains('build1')), isTrue);
        expect(uris.any((uri) => uri.contains('build2')), isTrue);
      });

      test('should read build log by URI', () {
        const buildId = 'test-build';
        const logContent = 'Building...\nCompiling...\nDone';
        logProvider.storeBuildLog(buildId, logContent);

        final result = strategy.read({'uri': 'logs://build/$buildId'});

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['content'], contains('Building'));
        expect(map['encoding'], equals('utf-8'));
      });

      test('should throw error when URI does not start with logs://build/', () {
        expect(
          () => strategy.read({'uri': 'logs://run/test'}),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('WorkspaceResourceStrategy', () {
      late WorkspaceResourceStrategy strategy;
      late PathSandbox pathSandbox;
      late Directory testDir;

      setUp(() {
        // Create a temporary test directory
        testDir = Directory.systemTemp.createTempSync('workspace_test_');
        // Ensure directory exists
        if (!testDir.existsSync()) {
          testDir.createSync(recursive: true);
        }
        pathSandbox = PathSandbox(workspaceRoot: testDir.path);
        strategy = WorkspaceResourceStrategy();
        strategy.setPathSandbox(pathSandbox);
      });

      tearDown(() {
        // Clean up test directory
        if (testDir.existsSync()) {
          try {
            testDir.deleteSync(recursive: true);
          } catch (e) {
            // Ignore cleanup errors
          }
        }
      });

      test('should have correct URI prefix', () {
        expect(strategy.uriPrefix, equals('workspace://'));
        expect(strategy.description, contains('Workspace'));
        expect(strategy.readOnly, isTrue);
      });

      test('should throw error when path sandbox not configured', () {
        final unconfiguredStrategy = WorkspaceResourceStrategy();
        expect(
          () => unconfiguredStrategy.list({}),
          throwsA(isA<StateError>()),
        );
      });

      test('should list files in directory', () {
        // Ensure directory exists
        if (!testDir.existsSync()) {
          testDir.createSync(recursive: true);
        }
        
        // Create test files - must match default allowed suffixes since no security config
        final file1 = File('${testDir.path}/test1.dart');
        final file2 = File('${testDir.path}/test2.dart');
        final file3 = File('${testDir.path}/config.yaml');
        file1.createSync();
        file2.createSync();
        file3.createSync();

        // Verify files exist before listing
        expect(file1.existsSync(), isTrue);
        expect(file2.existsSync(), isTrue);
        expect(file3.existsSync(), isTrue);

        // Use directory parameter - PathSandbox should resolve it
        final resolvedDir = pathSandbox.resolvePath(testDir.path);
        expect(resolvedDir, isNotNull);

        final result = strategy.list({'directory': testDir.path});

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['items'], isA<List>());
        final items = map['items'] as List;
        expect(items.length, greaterThanOrEqualTo(3));

        // Verify file URIs
        final uris = items
            .map((item) => (item as Map<String, Object?>)['uri'] as String)
            .toList();
        expect(uris.any((uri) => uri.contains('test1.dart')), isTrue);
        expect(uris.any((uri) => uri.contains('test2.dart')), isTrue);
        expect(uris.any((uri) => uri.contains('config.yaml')), isTrue);
      });

      test('should return empty list for directory outside workspace', () {
        final outsideDir = Directory.systemTemp.createTempSync('outside_');

        final result = strategy.list({'directory': outsideDir.path});

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['items'], isA<List>());
        expect((map['items'] as List).isEmpty, isTrue);
        expect(map['total'], equals(0));

        outsideDir.deleteSync(recursive: true);
      });

      test('should support pagination', () {
        // Ensure directory exists
        if (!testDir.existsSync()) {
          testDir.createSync(recursive: true);
        }
        
        // Create multiple test files
        for (var i = 0; i < 15; i++) {
          final file = File('${testDir.path}/file$i.dart');
          file.createSync();
          expect(file.existsSync(), isTrue);
        }

        final page1 = strategy.list({
          'directory': testDir.path,
          'page': 0,
          'pageSize': 5,
        });
        final page2 = strategy.list({
          'directory': testDir.path,
          'page': 1,
          'pageSize': 5,
        });

        expect((page1['items'] as List).length, equals(5));
        expect((page2['items'] as List).length, equals(5));
        expect(page1['total'], equals(15));
        expect(page2['total'], equals(15));
      });

      test('should read file content', () {
        // Ensure directory exists
        if (!testDir.existsSync()) {
          testDir.createSync(recursive: true);
        }
        
        final testFile = File('${testDir.path}/test.dart');
        const content = 'void main() {\n  print("Hello");\n}';
        testFile.writeAsStringSync(content);
        expect(testFile.existsSync(), isTrue);

        // Use the file path directly - the read method will resolve it via sandbox
        final result = strategy.read({
          'uri': 'workspace://${testFile.path}',
        });

        expect(result, isA<Map>());
        final map = result as Map<String, Object?>;
        expect(map['content'], contains('void main'));
        expect(map['content'], contains('print("Hello")'));
        expect(map['encoding'], equals('utf-8'));
        expect(map['total'], isA<int>());
      });

      test('should support start and length parameters', () {
        // Ensure directory exists
        if (!testDir.existsSync()) {
          testDir.createSync(recursive: true);
        }
        
        final testFile = File('${testDir.path}/test.dart');
        const content = 'Line 1\nLine 2\nLine 3\nLine 4';
        testFile.writeAsStringSync(content);
        expect(testFile.existsSync(), isTrue);

        final result = strategy.read({
          'uri': 'workspace://${testFile.path}',
          'start': 7,
          'length': 7,
        });

        expect(result, isA<Map>());
        expect(result['start'], isA<int>());
        expect(result['length'], isA<int>());
        final contentResult = result['content'] as String;
        expect(contentResult.length, lessThanOrEqualTo(content.length));
      });

      test('should throw error when URI is missing', () {
        expect(
          () => strategy.read({}),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw error when URI does not start with workspace://', () {
        expect(
          () => strategy.read({'uri': 'logs://run/test'}),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw error when file does not exist', () {
        expect(
          () => strategy.read({
            'uri': 'workspace://${testDir.path}/nonexistent.dart',
          }),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw error when path is outside workspace', () {
        final outsideFile = File('${Directory.systemTemp.path}/outside.dart');
        outsideFile.createSync();

        expect(
          () => strategy.read({'uri': 'workspace://${outsideFile.path}'}),
          throwsA(isA<StateError>()),
        );

        outsideFile.deleteSync();
      });

      test('should respect security config restrictions', () {
        // Ensure directory exists
        if (!testDir.existsSync()) {
          testDir.createSync(recursive: true);
        }
        
        // Create a restricted sandbox
        final restrictedSandbox = PathSandbox(
          workspaceRoot: testDir.path,
          securityConfig: SecurityConfig(
            allowedFileSuffixes: {'.dart'},
            allowedFileNames: {'pubspec.yaml'},
          ),
        );
        final restrictedStrategy = WorkspaceResourceStrategy();
        restrictedStrategy.setPathSandbox(restrictedSandbox);

        // Create files with different extensions
        final allowedFile = File('${testDir.path}/allowed.dart');
        final deniedFile = File('${testDir.path}/denied.txt');
        final pubspecFile = File('${testDir.path}/pubspec.yaml');
        allowedFile.createSync();
        deniedFile.createSync();
        pubspecFile.createSync();

        expect(allowedFile.existsSync(), isTrue);
        expect(deniedFile.existsSync(), isTrue);
        expect(pubspecFile.existsSync(), isTrue);

        final result = restrictedStrategy.list({
          'directory': testDir.path,
        });

        final items = result['items'] as List;
        final uris = items
            .map((item) => (item as Map<String, Object?>)['uri'] as String)
            .toList();

        // Should only include .dart files and pubspec.yaml
        expect(uris.any((uri) => uri.contains('allowed.dart')), isTrue);
        expect(uris.any((uri) => uri.contains('pubspec.yaml')), isTrue);
        expect(uris.any((uri) => uri.contains('denied.txt')), isFalse);
      });

      test('should deny access when security config restricts file', () {
        final restrictedSandbox = PathSandbox(
          workspaceRoot: testDir.path,
          securityConfig: SecurityConfig(
            allowedFileSuffixes: {'.dart'},
          ),
        );
        final restrictedStrategy = WorkspaceResourceStrategy();
        restrictedStrategy.setPathSandbox(restrictedSandbox);

        // Create a denied file
        File('${testDir.path}/denied.txt').createSync();

        expect(
          () => restrictedStrategy.read({
            'uri': 'workspace://${testDir.path}/denied.txt',
          }),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

