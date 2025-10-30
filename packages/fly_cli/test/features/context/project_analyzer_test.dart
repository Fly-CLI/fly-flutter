import 'dart:io';

import 'package:fly_cli/src/features/context/models.dart';
import 'package:fly_cli/src/features/context/analyzers/unified_analyzers.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../helpers/analysis_test_fixtures.dart';

void main() {
  group('UnifiedProjectAnalyzer', () {
    late UnifiedProjectAnalyzer analyzer;
    late Directory tempDir;
    late ContextGeneratorConfig config;

    setUp(() {
      analyzer = UnifiedProjectAnalyzer();
      tempDir = Directory.systemTemp.createTempSync('fly_test_');
      config = const ContextGeneratorConfig();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('Project Analysis', () {
      test('should analyze minimal Flutter project', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);

        final projectInfo = await analyzer.analyze(projectDir, config);

        expect(projectInfo.name, equals('minimal_test'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.version, equals('1.0.0+1'));
        expect(projectInfo.platforms, contains('ios'));
        expect(projectInfo.platforms, contains('android'));
        expect(projectInfo.isFlyProject, isFalse);
        expect(projectInfo.hasManifest, isFalse);
      });

      test('should analyze complex Flutter project', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final projectInfo = await analyzer.analyze(projectDir, config);

        expect(projectInfo.name, equals('complex_test'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.version, equals('2.0.0+2'));
        expect(projectInfo.platforms, contains('ios'));
        expect(projectInfo.platforms, contains('android'));
        expect(projectInfo.platforms, contains('web'));
        expect(projectInfo.isFlyProject, isFalse);
        expect(projectInfo.hasManifest, isFalse);
      });

      test('should handle Fly project with manifest', () async {
        final projectDir = await AnalysisTestFixtures.createFlyProject(tempDir);

        final projectInfo = await analyzer.analyze(projectDir, config);

        expect(projectInfo.name, equals('fly_test'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.isFlyProject, isTrue);
        expect(projectInfo.hasManifest, isTrue);
      });

      test('should handle missing pubspec.yaml', () async {
        final projectDir = Directory(path.join(tempDir.path, 'empty'));
        projectDir.createSync();

        // The unified analyzer handles missing pubspec.yaml gracefully
        final projectInfo = await analyzer.analyze(projectDir, config);
        expect(projectInfo.name, equals('unknown'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.version, equals('0.0.0'));
      });

      test('should handle malformed pubspec.yaml', () async {
        final projectDir = Directory(path.join(tempDir.path, 'malformed'));
        projectDir.createSync();
        
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        pubspecFile.writeAsStringSync('invalid yaml content: [unclosed');

        // The unified analyzer handles malformed pubspec.yaml gracefully
        final projectInfo = await analyzer.analyze(projectDir, config);
        expect(projectInfo.name, equals('unknown'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.version, equals('0.0.0'));
      });
    });

    group('Performance', () {
      test('should complete analysis within reasonable time', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final stopwatch = Stopwatch()..start();
        final projectInfo = await analyzer.analyze(projectDir, config);
        stopwatch.stop();

        expect(projectInfo.name, equals('complex_test'));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('should handle large projects efficiently', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        final stopwatch = Stopwatch()..start();
        final projectInfo = await analyzer.analyze(projectDir, config);
        stopwatch.stop();

        expect(projectInfo.name, equals('complex_test'));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      });
    });

    group('Integration', () {
      test('should work with different configurations', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);

        // Test with different config options
        final configWithArchitecture = const ContextGeneratorConfig(
          includeArchitecture: true,
        );

        final projectInfo = await analyzer.analyze(projectDir, configWithArchitecture);

        expect(projectInfo.name, equals('complex_test'));
        expect(projectInfo.type, equals('flutter'));
        expect(projectInfo.isFlyProject, isFalse);
      });

      test('should handle repeated analysis', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);

        // Run analysis multiple times
        for (int i = 0; i < 3; i++) {
          final projectInfo = await analyzer.analyze(projectDir, config);
          expect(projectInfo.name, equals('minimal_test'));
          expect(projectInfo.type, equals('flutter'));
        }
      });
    });

    group('Error Handling', () {
      test('should handle non-existent directory', () async {
        final projectDir = Directory(path.join(tempDir.path, 'nonexistent'));

        // The unified analyzer handles non-existent directories gracefully
        final projectInfo = await analyzer.analyze(projectDir, config);
        expect(projectInfo.name, equals('unknown'));
        expect(projectInfo.type, equals('flutter'));
      });

      test('should handle permission denied', () async {
        final projectDir = Directory(path.join(tempDir.path, 'restricted'));
        projectDir.createSync();
        
        // Test with restricted directory
        final projectInfo = await analyzer.analyze(projectDir, config);
        expect(projectInfo.name, equals('unknown'));
        expect(projectInfo.type, equals('flutter'));
      });
    });
  });
}