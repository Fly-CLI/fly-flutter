import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:fly_cli/src/features/context/infrastructure/analysis/enhanced/context_generator.dart';
import 'package:fly_cli/src/features/context/domain/models/models.dart';
import '../helpers/analysis_test_fixtures.dart';
import '../helpers/mock_logger.dart';

void main() {
  group('Analysis Performance Tests', () {
    late ContextGenerator generator;
    late MockLogger mockLogger;
    late Directory tempDir;

    setUp(() {
      mockLogger = MockLogger();
      generator = ContextGenerator(logger: mockLogger);
      tempDir = Directory.systemTemp.createTempSync('fly_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
      mockLogger.clear();
    });

    group('Performance Benchmarks', () {
      test('should analyze minimal project within 5 seconds', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          includeArchitecture: true,
          includeSuggestions: true,
        );

        final stopwatch = Stopwatch()..start();
        final context = await generator.generate(projectDir, config);
        stopwatch.stop();

        expect(context, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
      });

      test('should analyze complex project within 10 seconds', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          includeArchitecture: true,
          includeSuggestions: true,
        );

        final stopwatch = Stopwatch()..start();
        final context = await generator.generate(projectDir, config);
        stopwatch.stop();

        expect(context, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
      });

      test('should analyze large project within 30 seconds', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          includeArchitecture: true,
          includeSuggestions: true,
          maxFiles: 50, // Reasonable limit for performance
          maxFileSize: 10000, // Reasonable size limit
        );

        final stopwatch = Stopwatch()..start();
        final context = await generator.generate(projectDir, config);
        stopwatch.stop();

        expect(context, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds max
      });

      test('should analyze Fly project within 8 seconds', () async {
        final projectDir = await AnalysisTestFixtures.createFlyProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          includeArchitecture: true,
          includeSuggestions: true,
        );

        final stopwatch = Stopwatch()..start();
        final context = await generator.generate(projectDir, config);
        stopwatch.stop();

        expect(context, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(8000)); // 8 seconds max
      });

      test('should analyze problematic project within 12 seconds', () async {
        final projectDir = await AnalysisTestFixtures.createProblematicProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          includeArchitecture: true,
          includeSuggestions: true,
        );

        final stopwatch = Stopwatch()..start();
        final context = await generator.generate(projectDir, config);
        stopwatch.stop();

        expect(context, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(12000)); // 12 seconds max
      });
    });

    group('Memory Usage Tests', () {
      test('should not exceed memory limits for minimal project', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
        );

        // Get initial memory usage
        final initialMemory = ProcessInfo.currentRss;

        final context = await generator.generate(projectDir, config);

        // Get final memory usage
        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        expect(context, isNotNull);
        expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // 50MB max increase
      });

      test('should not exceed memory limits for complex project', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
        );

        // Get initial memory usage
        final initialMemory = ProcessInfo.currentRss;

        final context = await generator.generate(projectDir, config);

        // Get final memory usage
        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        expect(context, isNotNull);
        expect(memoryIncrease, lessThan(100 * 1024 * 1024)); // 100MB max increase
      });

      test('should respect file size limits to control memory usage', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          maxFiles: 10, // Small limit
          maxFileSize: 1000, // Very small size limit
        );

        // Get initial memory usage
        final initialMemory = ProcessInfo.currentRss;

        final context = await generator.generate(projectDir, config);

        // Get final memory usage
        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        expect(context, isNotNull);
        expect(memoryIncrease, lessThan(200 * 1024 * 1024)); // 200MB max increase

        // Verify limits were respected
        final code = context['code'] as Map<String, dynamic>;
        final fileContents = code['file_contents'] as Map<String, dynamic>;
        expect(fileContents.length, lessThanOrEqualTo(10));
        for (final content in fileContents.values) {
          expect(content.length, lessThanOrEqualTo(1000));
        }
      });
    });

    group('Concurrent Performance Tests', () {
      test('should handle concurrent analysis requests efficiently', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
        );

        final stopwatch = Stopwatch()..start();

        // Run multiple analyses concurrently
        final futures = List<Future<Map<String, dynamic>>>.generate(5, (_) => generator.generate(projectDir, config));
        final results = await Future.wait(futures);

        stopwatch.stop();

        // All should succeed
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isNotNull);
        }

        // Should complete within reasonable time (not 5x the single request time)
        expect(stopwatch.elapsedMilliseconds, lessThan(20000)); // 20 seconds max
      });

      test('should handle mixed project types concurrently', () async {
        final minimalProject = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final complexProject = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final flyProject = await AnalysisTestFixtures.createFlyProject(tempDir);

        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
        );

        final stopwatch = Stopwatch()..start();

        // Run analyses on different project types concurrently
        final futures = <Future<Map<String, dynamic>>>[
          generator.generate(minimalProject, config),
          generator.generate(complexProject, config),
          generator.generate(flyProject, config),
        ];
        final results = await Future.wait(futures);

        stopwatch.stop();

        // All should succeed
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotNull);
        }

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // 15 seconds max
      });
    });

    group('Scalability Tests', () {
      test('should scale linearly with project size', () async {
        final smallProject = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final largeProject = await AnalysisTestFixtures.createLargeProject(tempDir);

        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          maxFiles: 20, // Limit for fair comparison
          maxFileSize: 5000,
        );

        // Measure small project
        final smallStopwatch = Stopwatch()..start();
        final smallContext = await generator.generate(smallProject, config);
        smallStopwatch.stop();

        // Measure large project
        final largeStopwatch = Stopwatch()..start();
        final largeContext = await generator.generate(largeProject, config);
        largeStopwatch.stop();

        expect(smallContext, isNotNull);
        expect(largeContext, isNotNull);

        // Large project should take more time but not exponentially more
        final smallTime = smallStopwatch.elapsedMilliseconds;
        final largeTime = largeStopwatch.elapsedMilliseconds;

        expect(largeTime, greaterThan(smallTime));
        expect(largeTime, lessThan(smallTime * 10)); // Not more than 10x slower
      });

      test('should handle increasing file counts efficiently', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);
        
        final configs = [
          const ContextGeneratorConfig(
            includeCode: true,
            maxFiles: 5,
            maxFileSize: 10000,
          ),
          const ContextGeneratorConfig(
            includeCode: true,
            maxFiles: 15,
            maxFileSize: 10000,
          ),
          const ContextGeneratorConfig(
            includeCode: true,
            maxFiles: 30,
            maxFileSize: 10000,
          ),
        ];

        final times = <int>[];

        for (final config in configs) {
          final stopwatch = Stopwatch()..start();
          final context = await generator.generate(projectDir, config);
          stopwatch.stop();

          expect(context, isNotNull);
          times.add(stopwatch.elapsedMilliseconds);
        }

        // Times should increase but not dramatically
        expect(times[1], greaterThan(times[0]));
        expect(times[2], greaterThan(times[1]));
        expect(times[2], lessThan(times[0] * 5)); // Not more than 5x slower
      });

      test('should handle increasing file sizes efficiently', () async {
        final projectDir = await AnalysisTestFixtures.createLargeProject(tempDir);
        
        final configs = [
          const ContextGeneratorConfig(
            includeCode: true,
            maxFiles: 10,
            maxFileSize: 1000,
          ),
          const ContextGeneratorConfig(
            includeCode: true,
            maxFiles: 10,
            maxFileSize: 5000,
          ),
          const ContextGeneratorConfig(
            includeCode: true,
            maxFiles: 10,
            maxFileSize: 10000,
          ),
        ];

        final times = <int>[];

        for (final config in configs) {
          final stopwatch = Stopwatch()..start();
          final context = await generator.generate(projectDir, config);
          stopwatch.stop();

          expect(context, isNotNull);
          times.add(stopwatch.elapsedMilliseconds);
        }

        // Times should increase but not dramatically
        expect(times[1], greaterThan(times[0]));
        expect(times[2], greaterThan(times[1]));
        expect(times[2], lessThan(times[0] * 3)); // Not more than 3x slower
      });
    });

    group('Configuration Performance Impact', () {
      test('should be faster without code analysis', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        
        final withCodeConfig = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
        );
        final withoutCodeConfig = const ContextGeneratorConfig(
          includeCode: false,
          includeDependencies: true,
        );

        // Measure with code analysis
        final withCodeStopwatch = Stopwatch()..start();
        final withCodeContext = await generator.generate(projectDir, withCodeConfig);
        withCodeStopwatch.stop();

        // Measure without code analysis
        final withoutCodeStopwatch = Stopwatch()..start();
        final withoutCodeContext = await generator.generate(projectDir, withoutCodeConfig);
        withoutCodeStopwatch.stop();

        expect(withCodeContext, isNotNull);
        expect(withoutCodeContext, isNotNull);

        // Without code analysis should be faster
        expect(withoutCodeStopwatch.elapsedMilliseconds, lessThan(withCodeStopwatch.elapsedMilliseconds));
      });

      test('should be faster without dependency analysis', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        
        final withDepsConfig = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
        );
        final withoutDepsConfig = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: false,
        );

        // Measure with dependency analysis
        final withDepsStopwatch = Stopwatch()..start();
        final withDepsContext = await generator.generate(projectDir, withDepsConfig);
        withDepsStopwatch.stop();

        // Measure without dependency analysis
        final withoutDepsStopwatch = Stopwatch()..start();
        final withoutDepsContext = await generator.generate(projectDir, withoutDepsConfig);
        withoutDepsStopwatch.stop();

        expect(withDepsContext, isNotNull);
        expect(withoutDepsContext, isNotNull);

        // Without dependency analysis should be faster
        expect(withoutDepsStopwatch.elapsedMilliseconds, lessThan(withDepsStopwatch.elapsedMilliseconds));
      });

      test('should be fastest with minimal configuration', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        
        final minimalConfig = const ContextGeneratorConfig();
        final fullConfig = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          includeArchitecture: true,
          includeSuggestions: true,
        );

        // Measure minimal configuration
        final minimalStopwatch = Stopwatch()..start();
        final minimalContext = await generator.generate(projectDir, minimalConfig);
        minimalStopwatch.stop();

        // Measure full configuration
        final fullStopwatch = Stopwatch()..start();
        final fullContext = await generator.generate(projectDir, fullConfig);
        fullStopwatch.stop();

        expect(minimalContext, isNotNull);
        expect(fullContext, isNotNull);

        // Minimal configuration should be fastest
        expect(minimalStopwatch.elapsedMilliseconds, lessThan(fullStopwatch.elapsedMilliseconds));
      });
    });

    group('Stress Tests', () {
      test('should handle repeated analysis without memory leaks', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
        );

        // Get initial memory usage
        final initialMemory = ProcessInfo.currentRss;

        // Run analysis multiple times
        for (int i = 0; i < 10; i++) {
          final context = await generator.generate(projectDir, config);
          expect(context, isNotNull);
        }

        // Get final memory usage
        final finalMemory = ProcessInfo.currentRss;
        final memoryIncrease = finalMemory - initialMemory;

        // Memory increase should be reasonable (not a leak)
        expect(memoryIncrease, lessThan(100 * 1024 * 1024)); // 100MB max increase
      });

      test('should handle rapid successive analysis requests', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final config = const ContextGeneratorConfig();

        final stopwatch = Stopwatch()..start();

        // Run analysis rapidly in succession
        for (int i = 0; i < 20; i++) {
          final context = await generator.generate(projectDir, config);
          expect(context, isNotNull);
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // 30 seconds max
      });

      test('should handle mixed configuration requests', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        
        final configs = [
          const ContextGeneratorConfig(),
          const ContextGeneratorConfig(includeCode: true),
          const ContextGeneratorConfig(includeDependencies: true),
          const ContextGeneratorConfig(includeArchitecture: true),
          const ContextGeneratorConfig(includeSuggestions: true),
          const ContextGeneratorConfig(
            includeCode: true,
            includeDependencies: true,
          ),
          const ContextGeneratorConfig(
            includeCode: true,
            includeDependencies: true,
            includeArchitecture: true,
          ),
          const ContextGeneratorConfig(
            includeCode: true,
            includeDependencies: true,
            includeArchitecture: true,
            includeSuggestions: true,
          ),
        ];

        final stopwatch = Stopwatch()..start();

        // Run analysis with different configurations
        for (final config in configs) {
          final context = await generator.generate(projectDir, config);
          expect(context, isNotNull);
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(60000)); // 60 seconds max
      });
    });

    group('Performance Regression Tests', () {
      test('should maintain performance characteristics', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final config = const ContextGeneratorConfig(
          includeCode: true,
          includeDependencies: true,
          includeArchitecture: true,
          includeSuggestions: true,
        );

        // Run analysis multiple times to get average
        final times = <int>[];
        for (int i = 0; i < 5; i++) {
          final stopwatch = Stopwatch()..start();
          final context = await generator.generate(projectDir, config);
          stopwatch.stop();
          
          expect(context, isNotNull);
          times.add(stopwatch.elapsedMilliseconds);
        }

        // Calculate average time
        final averageTime = times.reduce((a, b) => a + b) / times.length;

        // Average time should be reasonable
        expect(averageTime, lessThan(8000)); // 8 seconds average max

        // All individual times should be within reasonable range
        for (final time in times) {
          expect(time, lessThan(12000)); // 12 seconds individual max
        }
      });

      test('should have consistent performance across runs', () async {
        final projectDir = await AnalysisTestFixtures.createMinimalFlutterProject(tempDir);
        final config = const ContextGeneratorConfig();

        // Run analysis multiple times
        final times = <int>[];
        for (int i = 0; i < 10; i++) {
          final stopwatch = Stopwatch()..start();
          final context = await generator.generate(projectDir, config);
          stopwatch.stop();
          
          expect(context, isNotNull);
          times.add(stopwatch.elapsedMilliseconds);
        }

        // Calculate statistics
        final minTime = times.reduce((a, b) => a < b ? a : b);
        final maxTime = times.reduce((a, b) => a > b ? a : b);
        final averageTime = times.reduce((a, b) => a + b) / times.length;

        // Performance should be consistent
        expect(maxTime - minTime, lessThan(2000)); // Max 2 second variation
        expect(averageTime, lessThan(3000)); // Average under 3 seconds
      });
    });
  });
}
