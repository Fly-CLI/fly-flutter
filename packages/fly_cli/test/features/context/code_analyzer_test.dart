import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:fly_cli/src/features/context/infrastructure/analysis/code_analyzer.dart';
import 'package:fly_cli/src/features/context/domain/models/models.dart';

import '../../helpers/analysis_test_fixtures.dart';

void main() {
  group('CodeAnalyzer', () {
    late CodeAnalyzer analyzer;
    late Directory tempDir;

    setUp(() {
      analyzer = const CodeAnalyzer();
      tempDir = Directory.systemTemp.createTempSync('fly_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('Code Analysis', () {
      test('should analyze code in complex project', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(includeCode: true);

        final codeInfo = await analyzer.analyzeCode(projectDir, config);

        expect(codeInfo.keyFiles.isNotEmpty, isTrue);
        expect(codeInfo.metrics.isNotEmpty, isTrue);
        expect(codeInfo.patterns.isNotEmpty, isTrue);
        expect(codeInfo.fileContents.isNotEmpty, isTrue);
        expect(codeInfo.imports.isNotEmpty, isTrue);
      });

      test('should handle project without lib directory', () async {
        final projectDir = Directory(path.join(tempDir.path, 'no_lib'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString(AnalysisTestFixtures.minimalPubspecContent);

        final config = const ContextGeneratorConfig(includeCode: true);

        final codeInfo = await analyzer.analyzeCode(projectDir, config);

        expect(codeInfo.keyFiles.isEmpty, isTrue);
        expect(codeInfo.fileContents.isEmpty, isTrue);
        expect(codeInfo.metrics['total_dart_files'], equals(0));
        expect(codeInfo.patterns.isEmpty, isTrue);
      });

      test('should respect file size limits', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          maxFileSize: 1000, // Very small limit
        );

        final codeInfo = await analyzer.analyzeCode(projectDir, config);

        // Should have some files but not all due to size limit
        expect(codeInfo.fileContents.isNotEmpty, isTrue);
        
        // All included files should be under size limit
        for (final content in codeInfo.fileContents.values) {
          expect(content.length, lessThanOrEqualTo(1000));
        }
      });

      test('should respect file count limits', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          maxFiles: 5,
        );

        final codeInfo = await analyzer.analyzeCode(projectDir, config);

        expect(codeInfo.fileContents.length, lessThanOrEqualTo(5));
      });

      test('should not include code when not requested', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(includeCode: false);

        final codeInfo = await analyzer.analyzeCode(projectDir, config);

        expect(codeInfo.fileContents.isEmpty, isTrue);
        expect(codeInfo.keyFiles.isNotEmpty, isTrue); // Still identifies key files
        expect(codeInfo.metrics.isNotEmpty, isTrue); // Still calculates metrics
      });
    });

    group('Key File Identification', () {
      test('should identify main.dart as main file', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final mainFile = keyFiles.firstWhere((f) => f.name == 'main.dart');
        expect(mainFile.type, equals('main'));
        expect(mainFile.importance, equals('high'));
        expect(mainFile.description, equals('Application entry point'));
      });

      test('should identify screen files correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final screenFiles = keyFiles.where((f) => f.type == 'screen').toList();
        expect(screenFiles.isNotEmpty, isTrue);
        
        for (final file in screenFiles) {
          expect(file.importance, equals('medium'));
          expect(file.description, equals('UI screen implementation'));
        }
      });

      test('should identify viewmodel files correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final viewmodelFiles = keyFiles.where((f) => f.type == 'viewmodel').toList();
        expect(viewmodelFiles.isNotEmpty, isTrue);
        
        for (final file in viewmodelFiles) {
          expect(file.importance, equals('medium'));
          expect(file.description, equals('Business logic and state management'));
        }
      });

      test('should identify service files correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final serviceFiles = keyFiles.where((f) => f.type == 'service').toList();
        expect(serviceFiles.isNotEmpty, isTrue);
        
        for (final file in serviceFiles) {
          expect(file.importance, equals('medium'));
          expect(file.description, equals('API service or data layer'));
        }
      });

      test('should identify routing files correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final routingFiles = keyFiles.where((f) => f.type == 'routing').toList();
        expect(routingFiles.isNotEmpty, isTrue);
        
        for (final file in routingFiles) {
          expect(file.importance, equals('high'));
          expect(file.description, equals('Navigation and routing configuration'));
        }
      });

      test('should sort files by importance', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        // High importance files should come first
        final highImportanceFiles = keyFiles.where((f) => f.importance == 'high').toList();
        final mediumImportanceFiles = keyFiles.where((f) => f.importance == 'medium').toList();
        final lowImportanceFiles = keyFiles.where((f) => f.importance == 'low').toList();

        expect(highImportanceFiles.isNotEmpty, isTrue);
        expect(mediumImportanceFiles.isNotEmpty, isTrue);
        expect(lowImportanceFiles.isNotEmpty, isTrue);

        // Check that high importance files come before medium, and medium before low
        final firstHighIndex = keyFiles.indexWhere((f) => f.importance == 'high');
        final firstMediumIndex = keyFiles.indexWhere((f) => f.importance == 'medium');
        final firstLowIndex = keyFiles.indexWhere((f) => f.importance == 'low');

        expect(firstHighIndex, lessThan(firstMediumIndex));
        expect(firstMediumIndex, lessThan(firstLowIndex));
      });

      test('should count lines of code correctly', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final mainFile = keyFiles.firstWhere((f) => f.name == 'main.dart');
        expect(mainFile.linesOfCode, greaterThan(0));
        expect(mainFile.linesOfCode, lessThan(100)); // Should be reasonable for test file
      });
    });

    group('File Content Extraction', () {
      test('should extract file contents for important files', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        final keyFiles = await analyzer.identifyKeyFiles(libDir);
        final config = const ContextGeneratorConfig(includeCode: true);

        final fileContents = await analyzer.extractFileContents(keyFiles, config);

        expect(fileContents.isNotEmpty, isTrue);
        
        // Should include high and medium importance files
        for (final entry in fileContents.entries) {
          final file = keyFiles.firstWhere((f) => f.path == entry.key);
          expect(['high', 'medium'].contains(file.importance), isTrue);
        }
      });

      test('should skip low importance files', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        final keyFiles = await analyzer.identifyKeyFiles(libDir);
        final config = const ContextGeneratorConfig(includeCode: true);

        final fileContents = await analyzer.extractFileContents(keyFiles, config);

        // Should not include low importance files
        for (final entry in fileContents.entries) {
          final file = keyFiles.firstWhere((f) => f.path == entry.key);
          expect(file.importance, isNot(equals('low')));
        }
      });

      test('should handle file read errors gracefully', () async {
        final projectDir = Directory(path.join(tempDir.path, 'error_test'));
        await projectDir.create(recursive: true);

        final libDir = Directory(path.join(projectDir.path, 'lib'));
        await libDir.create(recursive: true);

        // Create a file that will cause read errors
        final errorFile = File(path.join(libDir.path, 'error.dart'));
        await errorFile.writeAsString('test content');

        // Make file unreadable by deleting it temporarily
        final tempPath = '${errorFile.path}.temp';
        await errorFile.rename(tempPath);

        final keyFiles = await analyzer.identifyKeyFiles(libDir);
        final config = const ContextGeneratorConfig(includeCode: true);

        // Should not throw, but should skip the problematic file
        final fileContents = await analyzer.extractFileContents(keyFiles, config);
        
        // Restore file for cleanup
        await File(tempPath).rename(errorFile.path);
        
        expect(fileContents, isA<Map<String, String>>());
      });
    });

    group('Metrics Calculation', () {
      test('should calculate basic metrics correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final metrics = await analyzer.calculateMetrics(projectDir);

        expect(metrics.containsKey('total_dart_files'), isTrue);
        expect(metrics.containsKey('total_lines_of_code'), isTrue);
        expect(metrics.containsKey('total_characters'), isTrue);
        expect(metrics.containsKey('classes'), isTrue);
        expect(metrics.containsKey('functions'), isTrue);
        expect(metrics.containsKey('imports'), isTrue);

        expect(metrics['total_dart_files'], greaterThan(0));
        expect(metrics['total_lines_of_code'], greaterThan(0));
        expect(metrics['total_characters'], greaterThan(0));
        expect(metrics['classes'], greaterThan(0));
        expect(metrics['functions'], greaterThan(0));
        expect(metrics['imports'], greaterThan(0));
      });

      test('should count classes correctly', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);

        final metrics = await analyzer.calculateMetrics(projectDir);

        // Should have at least MyApp and MyHomePage classes
        expect(metrics['classes'], greaterThanOrEqualTo(2));
      });

      test('should count functions correctly', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);

        final metrics = await analyzer.calculateMetrics(projectDir);

        // Should have at least main function and build methods
        expect(metrics['functions'], greaterThanOrEqualTo(3));
      });

      test('should count imports correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final metrics = await analyzer.calculateMetrics(projectDir);

        // Should have multiple imports
        expect(metrics['imports'], greaterThan(5));
      });

      test('should handle empty project', () async {
        final projectDir = Directory(path.join(tempDir.path, 'empty'));
        await projectDir.create(recursive: true);

        final metrics = await analyzer.calculateMetrics(projectDir);

        expect(metrics['total_dart_files'], equals(0));
        expect(metrics['total_lines_of_code'], equals(0));
        expect(metrics['total_characters'], equals(0));
        expect(metrics['classes'], equals(0));
        expect(metrics['functions'], equals(0));
        expect(metrics['imports'], equals(0));
      });

      test('should include test files when present', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final metrics = await analyzer.calculateMetrics(projectDir);

        // Should include test files in counts
        expect(metrics['total_dart_files'], greaterThan(5)); // lib + test files
      });
    });

    group('Import Analysis', () {
      test('should extract imports from files', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final imports = await analyzer.analyzeImports(keyFiles);

        expect(imports.isNotEmpty, isTrue);
        
        for (final entry in imports.entries) {
          expect(entry.value, isA<List<String>>());
          expect(entry.value.isNotEmpty, isTrue);
        }
      });

      test('should extract Flutter imports', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final imports = await analyzer.analyzeImports(keyFiles);

        final mainImports = imports['main.dart']!;
        expect(mainImports.contains('package:flutter/material.dart'), isTrue);
      });

      test('should extract package imports', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final imports = await analyzer.analyzeImports(keyFiles);

        // Should find Riverpod imports
        final hasRiverpodImport = imports.values.any((fileImports) =>
            fileImports.any((import) => import.contains('flutter_riverpod')));
        expect(hasRiverpodImport, isTrue);
      });

      test('should handle files with no imports', () async {
        final projectDir = Directory(path.join(tempDir.path, 'no_imports'));
        await projectDir.create(recursive: true);

        final libDir = Directory(path.join(projectDir.path, 'lib'));
        await libDir.create(recursive: true);

        final emptyFile = File(path.join(libDir.path, 'empty.dart'));
        await emptyFile.writeAsString('// Empty file');

        final keyFiles = await analyzer.identifyKeyFiles(libDir);
        final imports = await analyzer.analyzeImports(keyFiles);

        expect(imports.containsKey('empty.dart'), isTrue);
        expect(imports['empty.dart']!.isEmpty, isTrue);
      });

      test('should skip low importance files', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));
        final keyFiles = await analyzer.identifyKeyFiles(libDir);

        final imports = await analyzer.analyzeImports(keyFiles);

        // Should only include high and medium importance files
        for (final entry in imports.entries) {
          final file = keyFiles.firstWhere((f) => f.path == entry.key);
          expect(['high', 'medium'].contains(file.importance), isTrue);
        }
      });
    });

    group('Pattern Detection', () {
      test('should detect Riverpod patterns', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.contains('riverpod'), isTrue);
      });

      test('should detect BLoC patterns', () async {
        final projectDir = await AnalysisTestFixtures.createProblematicProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.contains('bloc'), isTrue);
      });

      test('should detect Provider patterns', () async {
        final projectDir = await AnalysisTestFixtures.createProblematicProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.contains('provider'), isTrue);
      });

      test('should detect Material Design patterns', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.contains('material_design'), isTrue);
      });

      test('should detect MVVM patterns', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.contains('mvvm'), isTrue);
      });

      test('should detect GoRouter patterns', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.contains('go_router'), isTrue);
      });

      test('should detect exception handling patterns', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.contains('exception_handling'), isTrue);
      });

      test('should return empty list for no patterns', () async {
        final projectDir = Directory(path.join(tempDir.path, 'no_patterns'));
        await projectDir.create(recursive: true);

        final libDir = Directory(path.join(projectDir.path, 'lib'));
        await libDir.create(recursive: true);

        final simpleFile = File(path.join(libDir.path, 'simple.dart'));
        await simpleFile.writeAsString('''
// Simple file with no patterns
class SimpleClass {
  void simpleMethod() {
    print('Hello');
  }
}
''');

        final patterns = await analyzer.detectPatterns(libDir);

        expect(patterns.isEmpty, isTrue);
      });
    });

    // File Type Detection tests removed - testing non-existent private methods

    // Import Extraction tests removed - testing non-existent private methods

    group('Data Models', () {
      test('should serialize CodeInfo to JSON correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(includeCode: true);

        final codeInfo = await analyzer.analyzeCode(projectDir, config);
        final json = codeInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['key_files'], isA<List<dynamic>>());
        expect(json['file_contents'], isA<Map<String, dynamic>>());
        expect(json['metrics'], isA<Map<String, dynamic>>());
        expect(json['imports'], isA<Map<String, dynamic>>());
        expect(json['patterns'], isA<List<dynamic>>());
      });

      test('should serialize SourceFile to JSON correctly', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final libDir = Directory(path.join(projectDir.path, 'lib'));

        final keyFiles = await analyzer.identifyKeyFiles(libDir);
        final mainFile = keyFiles.firstWhere((f) => f.name == 'main.dart');

        final json = mainFile.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['path'], equals('main.dart'));
        expect(json['name'], equals('main.dart'));
        expect(json['type'], equals('main'));
        expect(json['lines_of_code'], greaterThan(0));
        expect(json['importance'], equals('high'));
        expect(json['description'], equals('Application entry point'));
      });
    });

    group('Performance', () {
      test('should complete analysis within reasonable time', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);
        final config = const ContextGeneratorConfig(includeCode: true);

        final stopwatch = Stopwatch()..start();
        final codeInfo = await analyzer.analyzeCode(projectDir, config);
        stopwatch.stop();

        expect(codeInfo, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 seconds max
      });

      test('should handle concurrent analysis requests', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(includeCode: true);

        final futures = List.generate(3, (_) => analyzer.analyzeCode(projectDir, config));
        final results = await Future.wait(futures);

        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotNull);
          expect(result.keyFiles.isNotEmpty, isTrue);
        }
      });
    });
  });
}
