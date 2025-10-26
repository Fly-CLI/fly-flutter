import 'dart:io';

import 'package:fly_cli/src/features/context/infrastructure/analysis/project_analyzer.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/analysis_test_fixtures.dart';

void main() {
  group('ProjectAnalyzer', () {
    late ProjectAnalyzer analyzer;
    late Directory tempDir;

    setUp(() {
      analyzer = const ProjectAnalyzer();
      tempDir = Directory.systemTemp.createTempSync('fly_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('Project Analysis', () {
      test('should analyze minimal Flutter project', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);

        final projectInfo = await analyzer.analyzeProject(projectDir);

        expect(projectInfo.name, equals('minimal_test'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.version, equals('1.0.0+1'));
        expect(projectInfo.isFlyProject, isFalse);
        expect(projectInfo.hasManifest, isFalse);
        expect(projectInfo.platforms, equals(['ios', 'android']));
      });

      test('should analyze Fly project with manifest', () async {
        final projectDir = await AnalysisTestFixtures.createFlyProject(tempDir);

        final projectInfo = await analyzer.analyzeProject(projectDir);

        expect(projectInfo.name, equals('fly_test'));
        expect(projectInfo.type, equals('fly'));
        expect(projectInfo.isFlyProject, isTrue);
        expect(projectInfo.hasManifest, isTrue);
        expect(projectInfo.template, equals('riverpod'));
        expect(projectInfo.organization, equals('test_org'));
      });

      test('should detect Fly project by dependencies', () async {
        final projectDir = await AnalysisTestFixtures.createFlyProject(tempDir);

        final projectInfo = await analyzer.analyzeProject(projectDir);

        expect(projectInfo.isFlyProject, isTrue);
      });

      test('should extract environment constraints', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final projectInfo = await analyzer.analyzeProject(projectDir);

        // Environment constraints should be present in the test pubspec
        expect(projectInfo.dartVersion, isNotNull);
        expect(projectInfo.flutterVersion, isNotNull);
      });

      test('should handle missing description', () async {
        final projectDir = Directory(path.join(tempDir.path, 'no_desc'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: no_desc
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
''');

        final projectInfo = await analyzer.analyzeProject(projectDir);

        expect(projectInfo.name, equals('no_desc'));
        expect(projectInfo.description, isNull);
      });
    });

    group('Pubspec Analysis', () {
      test('should parse pubspec.yaml correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        final pubspecInfo = await analyzer.analyzePubspec(pubspecFile);

        expect(pubspecInfo.name, equals('complex_test'));
        expect(pubspecInfo.version, equals('1.0.0+1'));
        expect(pubspecInfo.description, equals('A complex test project'));
        expect(pubspecInfo.dependencies.containsKey('flutter_riverpod'), isTrue);
        expect(pubspecInfo.devDependencies.containsKey('flutter_test'), isTrue);
      });

      test('should handle pubspec with repository URL', () async {
        final projectDir = Directory(path.join(tempDir.path, 'with_repo'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: with_repo
version: 1.0.0+1
description: A project with repository
repository: https://github.com/test/with_repo

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
''');

        final pubspecInfo = await analyzer.analyzePubspec(pubspecFile);

        expect(pubspecInfo.repository, equals('https://github.com/test/with_repo'));
      });

      test('should handle malformed pubspec.yaml', () async {
        final projectDir = Directory(path.join(tempDir.path, 'malformed'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('invalid: yaml: content: [');

        expect(
          () => analyzer.analyzePubspec(pubspecFile),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle missing pubspec.yaml', () async {
        final projectDir = Directory(path.join(tempDir.path, 'missing'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        expect(
          () => analyzer.analyzePubspec(pubspecFile),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Manifest Analysis', () {
      test('should parse Fly manifest correctly', () async {
        final projectDir = await AnalysisTestFixtures.createFlyProject(tempDir);

        final manifestInfo = await analyzer.analyzeManifest(projectDir);

        expect(manifestInfo, isNotNull);
        expect(manifestInfo!.name, equals('fly_test'));
        expect(manifestInfo.template, equals('riverpod'));
        expect(manifestInfo.organization, equals('test_org'));
        expect(manifestInfo.platforms, equals(['ios', 'android']));
        expect(manifestInfo.screens.length, equals(2));
        expect(manifestInfo.services.length, equals(1));
        expect(manifestInfo.packages.length, equals(2));
      });

      test('should return null for missing manifest', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);

        final manifestInfo = await analyzer.analyzeManifest(projectDir);

        expect(manifestInfo, isNull);
      });

      test('should handle malformed manifest gracefully', () async {
        final projectDir = Directory(path.join(tempDir.path, 'malformed_manifest'));
        await projectDir.create(recursive: true);

        final manifestFile = File(path.join(projectDir.path, 'fly_project.yaml'));
        await manifestFile.writeAsString('invalid: yaml: content: [');

        final manifestInfo = await analyzer.analyzeManifest(projectDir);

        expect(manifestInfo, isNull);
      });
    });

    group('Structure Analysis', () {
      test('should analyze project structure correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.rootDirectory, equals(projectDir.path));
        expect(structureInfo.totalFiles, greaterThan(0));
        expect(structureInfo.linesOfCode, greaterThan(0));
        expect(structureInfo.fileTypes.containsKey('.dart'), isTrue);
        expect(structureInfo.directories.containsKey('lib'), isTrue);
        expect(structureInfo.features.contains('home'), isTrue);
        expect(structureInfo.features.contains('profile'), isTrue);
      });

      test('should detect architecture patterns', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        // Should detect riverpod pattern from dependencies
        expect(structureInfo.architecturePattern, equals('riverpod'));
        expect(structureInfo.conventions.contains('feature-first'), isTrue);
        expect(structureInfo.conventions.contains('test-driven'), isTrue);
      });

      test('should count files and lines correctly', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.totalFiles, greaterThan(0));
        expect(structureInfo.linesOfCode, greaterThan(0));
        expect(structureInfo.fileTypes['.dart'], greaterThan(0));
        expect(structureInfo.fileTypes['.yaml'], equals(1));
      });

      test('should handle empty project', () async {
        final projectDir = Directory(path.join(tempDir.path, 'empty'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString(AnalysisTestFixtures.minimalPubspecContent);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.totalFiles, equals(1)); // Only pubspec.yaml
        expect(structureInfo.linesOfCode, equals(0));
        expect(structureInfo.features.isEmpty, isTrue);
      });

      test('should detect Fly architecture pattern', () async {
        final projectDir = await AnalysisTestFixtures.createFlyProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.architecturePattern, equals('fly'));
      });

      test('should detect multiple state management patterns', () async {
        final projectDir = await AnalysisTestFixtures.createProblematicProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        // Should detect one of the patterns, not necessarily all
        expect(structureInfo.architecturePattern, isNotNull);
        expect(['riverpod', 'bloc', 'provider'].contains(structureInfo.architecturePattern), isTrue);
      });
    });

    group('Architecture Pattern Detection', () {
      test('should detect Riverpod pattern', () async {
        final projectDir = Directory(path.join(tempDir.path, 'riverpod'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: riverpod_test
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
''');

        final projectInfo = await analyzer.analyzeProject(projectDir);
        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.architecturePattern, equals('riverpod'));
      });

      test('should detect BLoC pattern', () async {
        final projectDir = Directory(path.join(tempDir.path, 'bloc'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: bloc_test
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
''');

        final projectInfo = await analyzer.analyzeProject(projectDir);
        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.architecturePattern, equals('bloc'));
      });

      test('should detect Provider pattern', () async {
        final projectDir = Directory(path.join(tempDir.path, 'provider'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: provider_test
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
''');

        final projectInfo = await analyzer.analyzeProject(projectDir);
        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.architecturePattern, equals('provider'));
      });

      test('should return null for unknown patterns', () async {
        final projectDir = Directory(path.join(tempDir.path, 'unknown'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: unknown_test
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
''');

        final projectInfo = await analyzer.analyzeProject(projectDir);
        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.architecturePattern, isNull);
      });
    });

    group('Convention Detection', () {
      test('should detect feature-first convention', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.conventions.contains('feature-first'), isTrue);
      });

      test('should detect test-driven convention', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.conventions.contains('test-driven'), isTrue);
      });

      test('should detect documented convention', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        // Should detect documented convention if README.md exists
        expect(structureInfo.conventions.contains('documented'), isTrue);
      });

      test('should return empty list for no conventions', () async {
        final projectDir = Directory(path.join(tempDir.path, 'no_conventions'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString(AnalysisTestFixtures.minimalPubspecContent);

        final structureInfo = await analyzer.analyzeStructure(projectDir);

        expect(structureInfo.conventions.isEmpty, isTrue);
      });
    });

    group('Error Handling', () {
      test('should throw for non-Flutter project', () async {
        final nonFlutterDir = Directory(path.join(tempDir.path, 'not_flutter'));
        await nonFlutterDir.create(recursive: true);

        expect(
          () => analyzer.analyzeProject(nonFlutterDir),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle file access errors gracefully', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        
        // Make pubspec.yaml unreadable by deleting it temporarily
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        final tempPath = '${pubspecFile.path}.temp';
        await pubspecFile.rename(tempPath);

        expect(
          () => analyzer.analyzeProject(projectDir),
          throwsA(isA<Exception>()),
        );

        // Restore the file
        await File(tempPath).rename(pubspecFile.path);
      });
    });

    group('Performance', () {
      test('should complete analysis within reasonable time', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);

        final stopwatch = Stopwatch()..start();
        final projectInfo = await analyzer.analyzeProject(projectDir);
        final structureInfo = await analyzer.analyzeStructure(projectDir);
        stopwatch.stop();

        expect(projectInfo, isNotNull);
        expect(structureInfo, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
      });
    });

    group('Data Models', () {
      test('should serialize ProjectInfo to JSON correctly', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final projectInfo = await analyzer.analyzeProject(projectDir);

        final json = projectInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['name'], equals('minimal_test'));
        expect(json['type'], equals('flutter'));
        expect(json['is_fly_project'], isFalse);
      });

      test('should serialize StructureInfo to JSON correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final structureInfo = await analyzer.analyzeStructure(projectDir);

        final json = structureInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['root_directory'], equals(projectDir.path));
        expect(json['total_files'], greaterThan(0));
        expect(json['features'], isA<List<dynamic>>());
      });

      test('should serialize DirectoryInfo to JSON correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final structureInfo = await analyzer.analyzeStructure(projectDir);
        final libDir = structureInfo.directories['lib']!;

        final json = libDir.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['files'], greaterThan(0));
        expect(json['dart_files'], greaterThan(0));
        expect(json['subdirectories'], isA<List<dynamic>>());
      });
    });
  });
}
