import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:fly_cli/src/features/context/infrastructure/analysis/dependency_analyzer.dart';
import 'package:fly_cli/src/features/context/domain/models/models.dart';
import '../../helpers/analysis_test_fixtures.dart';

void main() {
  group('DependencyAnalyzer', () {
    late DependencyAnalyzer analyzer;
    late Directory tempDir;

    setUp(() {
      analyzer = const DependencyAnalyzer();
      tempDir = Directory.systemTemp.createTempSync('fly_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('Dependency Analysis', () {
      test('should analyze dependencies correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        final dependencyInfo = await analyzer.analyzeDependencies(pubspecFile);

        expect(dependencyInfo.dependencies.containsKey('flutter_riverpod'), isTrue);
        expect(dependencyInfo.dependencies.containsKey('go_router'), isTrue);
        expect(dependencyInfo.dependencies.containsKey('dio'), isTrue);
        expect(dependencyInfo.devDependencies.containsKey('flutter_test'), isTrue);
        expect(dependencyInfo.devDependencies.containsKey('build_runner'), isTrue);
      });

      test('should categorize dependencies correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        final dependencyInfo = await analyzer.analyzeDependencies(pubspecFile);

        expect(dependencyInfo.categories.containsKey('state_management'), isTrue);
        expect(dependencyInfo.categories.containsKey('networking'), isTrue);
        expect(dependencyInfo.categories.containsKey('development'), isTrue);
        
        final stateManagement = dependencyInfo.categories['state_management']!;
        expect(stateManagement.contains('flutter_riverpod'), isTrue);
        
        final networking = dependencyInfo.categories['networking']!;
        expect(networking.contains('dio'), isTrue);
      });

      test('should detect Fly packages', () async {
        final projectDir = await AnalysisTestFixtures.createFlyProject(tempDir);
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        final dependencyInfo = await analyzer.analyzeDependencies(pubspecFile);

        expect(dependencyInfo.flyPackages.contains('fly_core'), isTrue);
        expect(dependencyInfo.flyPackages.contains('fly_state'), isTrue);
        expect(dependencyInfo.flyPackages.contains('fly_networking'), isTrue);
      });

      test('should detect dependency conflicts', () async {
        final projectDir = await AnalysisTestFixtures.createProblematicProject(tempDir);
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        final dependencyInfo = await analyzer.analyzeDependencies(pubspecFile);

        expect(dependencyInfo.conflicts.isNotEmpty, isTrue);
        expect(dependencyInfo.conflicts.any((c) => c.contains('state management')), isTrue);
        expect(dependencyInfo.conflicts.any((c) => c.contains('HTTP client')), isTrue);
      });

      test('should generate warnings for problematic packages', () async {
        final projectDir = await AnalysisTestFixtures.createProblematicProject(tempDir);
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        final dependencyInfo = await analyzer.analyzeDependencies(pubspecFile);

        expect(dependencyInfo.warnings.isNotEmpty, isTrue);
        
        final problematicWarnings = dependencyInfo.warnings
            .where((w) => w.package == 'flutter_webview_plugin')
            .toList();
        expect(problematicWarnings.isNotEmpty, isTrue);
        expect(problematicWarnings.first.severity, equals('medium'));
      });

      test('should warn about missing flutter_test', () async {
        final projectDir = Directory(path.join(tempDir.path, 'no_test'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('''
name: no_test
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
''');

        final dependencyInfo = await analyzer.analyzeDependencies(pubspecFile);

        final testWarnings = dependencyInfo.warnings
            .where((w) => w.package == 'flutter_test')
            .toList();
        expect(testWarnings.isNotEmpty, isTrue);
        expect(testWarnings.first.severity, equals('high'));
        expect(testWarnings.first.message.contains('Missing flutter_test'), isTrue);
      });
    });

    group('Package Categorization', () {
      test('should categorize state management packages', () {
        final dependencies = <String, String>{
          'flutter_riverpod': '^2.4.0',
          'flutter_bloc': '^8.1.0',
          'provider': '^6.0.0',
          'get': '^4.6.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('state_management'), isTrue);
        final stateManagement = categories['state_management']!;
        expect(stateManagement.contains('flutter_riverpod'), isTrue);
        expect(stateManagement.contains('flutter_bloc'), isTrue);
        expect(stateManagement.contains('provider'), isTrue);
        expect(stateManagement.contains('get'), isTrue);
      });

      test('should categorize networking packages', () {
        final dependencies = <String, String>{
          'dio': '^5.3.0',
          'http': '^1.1.0',
          'chopper': '^6.0.0',
          'web_socket_channel': '^2.4.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('networking'), isTrue);
        final networking = categories['networking']!;
        expect(networking.contains('dio'), isTrue);
        expect(networking.contains('http'), isTrue);
        expect(networking.contains('chopper'), isTrue);
        expect(networking.contains('web_socket_channel'), isTrue);
      });

      test('should categorize UI packages', () {
        final dependencies = <String, String>{
          'flutter_screenutil': '^5.9.0',
          'lottie': '^2.7.0',
          'cached_network_image': '^3.3.0',
          'shimmer': '^3.0.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('ui'), isTrue);
        final ui = categories['ui']!;
        expect(ui.contains('flutter_screenutil'), isTrue);
        expect(ui.contains('lottie'), isTrue);
        expect(ui.contains('cached_network_image'), isTrue);
        expect(ui.contains('shimmer'), isTrue);
      });

      test('should categorize testing packages', () {
        final dependencies = <String, String>{
          'flutter_test': '^1.0.0',
          'mockito': '^5.4.0',
          'mocktail': '^1.0.0',
          'integration_test': '^1.0.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('testing'), isTrue);
        final testing = categories['testing']!;
        expect(testing.contains('flutter_test'), isTrue);
        expect(testing.contains('mockito'), isTrue);
        expect(testing.contains('mocktail'), isTrue);
        expect(testing.contains('integration_test'), isTrue);
      });

      test('should categorize development packages', () {
        final dependencies = <String, String>{
          'build_runner': '^2.4.0',
          'json_annotation': '^4.8.0',
          'freezed': '^2.4.0',
          'auto_route': '^7.8.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('development'), isTrue);
        final development = categories['development']!;
        expect(development.contains('build_runner'), isTrue);
        expect(development.contains('json_annotation'), isTrue);
        expect(development.contains('freezed'), isTrue);
        expect(development.contains('auto_route'), isTrue);
      });

      test('should categorize platform packages', () {
        final dependencies = <String, String>{
          'permission_handler': '^11.0.0',
          'device_info_plus': '^9.1.0',
          'shared_preferences': '^2.2.0',
          'sqflite': '^2.3.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('platform'), isTrue);
        final platform = categories['platform']!;
        expect(platform.contains('permission_handler'), isTrue);
        expect(platform.contains('device_info_plus'), isTrue);
        expect(platform.contains('shared_preferences'), isTrue);
        expect(platform.contains('sqflite'), isTrue);
      });

      test('should categorize unknown packages as other', () {
        final dependencies = <String, String>{
          'unknown_package': '^1.0.0',
          'another_unknown': '^2.0.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('other'), isTrue);
        final other = categories['other']!;
        expect(other.contains('unknown_package'), isTrue);
        expect(other.contains('another_unknown'), isTrue);
      });

      test('should remove empty categories', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('state_management'), isFalse);
        expect(categories.containsKey('networking'), isFalse);
        expect(categories.containsKey('ui'), isFalse);
        expect(categories.containsKey('testing'), isFalse);
        expect(categories.containsKey('development'), isFalse);
        expect(categories.containsKey('platform'), isFalse);
        expect(categories.containsKey('utilities'), isFalse);
        expect(categories.containsKey('other'), isTrue);
      });
    });

    group('Fly Package Detection', () {
      test('should detect Fly packages by prefix', () {
        final dependencies = <String, String>{
          'fly_core': '^0.1.0',
          'fly_state': '^0.1.0',
          'fly_networking': '^0.1.0',
          'fly_ui': '^0.1.0',
          'flutter': '^1.0.0',
        };

        final flyPackages = analyzer.detectFlyPackages(dependencies);

        expect(flyPackages.length, equals(4));
        expect(flyPackages.contains('fly_core'), isTrue);
        expect(flyPackages.contains('fly_state'), isTrue);
        expect(flyPackages.contains('fly_networking'), isTrue);
        expect(flyPackages.contains('fly_ui'), isTrue);
        expect(flyPackages.contains('flutter'), isFalse);
      });

      test('should return empty list for no Fly packages', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
          'flutter_riverpod': '^2.4.0',
        };

        final flyPackages = analyzer.detectFlyPackages(dependencies);

        expect(flyPackages.isEmpty, isTrue);
      });
    });

    group('Conflict Detection', () {
      test('should detect multiple state management packages', () {
        final dependencies = <String, String>{
          'flutter_riverpod': '^2.4.0',
          'flutter_bloc': '^8.1.0',
          'provider': '^6.0.0',
        };

        final conflicts = analyzer.checkForConflicts(dependencies);

        expect(conflicts.isNotEmpty, isTrue);
        expect(conflicts.any((c) => c.contains('state management')), isTrue);
        expect(conflicts.any((c) => c.contains('flutter_riverpod')), isTrue);
        expect(conflicts.any((c) => c.contains('flutter_bloc')), isTrue);
        expect(conflicts.any((c) => c.contains('provider')), isTrue);
      });

      test('should detect multiple HTTP clients', () {
        final dependencies = <String, String>{
          'dio': '^5.3.0',
          'http': '^1.1.0',
          'chopper': '^6.0.0',
        };

        final conflicts = analyzer.checkForConflicts(dependencies);

        expect(conflicts.isNotEmpty, isTrue);
        expect(conflicts.any((c) => c.contains('HTTP client')), isTrue);
        expect(conflicts.any((c) => c.contains('dio')), isTrue);
        expect(conflicts.any((c) => c.contains('http')), isTrue);
        expect(conflicts.any((c) => c.contains('chopper')), isTrue);
      });

      test('should not detect conflicts for single packages', () {
        final dependencies = <String, String>{
          'flutter_riverpod': '^2.4.0',
          'dio': '^5.3.0',
        };

        final conflicts = analyzer.checkForConflicts(dependencies);

        expect(conflicts.isEmpty, isTrue);
      });

      test('should not detect conflicts for unrelated packages', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
          'shared_preferences': '^2.2.0',
        };

        final conflicts = analyzer.checkForConflicts(dependencies);

        expect(conflicts.isEmpty, isTrue);
      });
    });

    group('Warning Detection', () {
      test('should warn about old versions', () {
        final dependencies = <String, String>{
          'old_package': '^1.0.0',
          'another_old': '^0.5.0',
        };

        final warnings = analyzer.checkForWarnings(dependencies, {});

        final oldWarnings = warnings.where((w) => w.message.contains('updating')).toList();
        expect(oldWarnings.isNotEmpty, isTrue);
      });

      test('should warn about problematic packages', () {
        final dependencies = <String, String>{
          'flutter_webview_plugin': '^0.4.0',
          'webview_flutter': '^0.3.0',
        };

        final warnings = analyzer.checkForWarnings(dependencies, {});

        final problematicWarnings = warnings
            .where((w) => w.message.contains('Known issues'))
            .toList();
        expect(problematicWarnings.isNotEmpty, isTrue);
        expect(problematicWarnings.any((w) => w.severity == 'medium'), isTrue);
      });

      test('should warn about missing flutter_test in dev dependencies', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
        };
        final devDependencies = <String, String>{};

        final warnings = analyzer.checkForWarnings(dependencies, devDependencies);

        final testWarnings = warnings
            .where((w) => w.package == 'flutter_test')
            .toList();
        expect(testWarnings.isNotEmpty, isTrue);
        expect(testWarnings.first.severity, equals('high'));
      });

      test('should not warn about flutter_test when present', () {
        final dependencies = <String, String>{
          'flutter': '^1.0.0',
        };
        final devDependencies = <String, String>{
          'flutter_test': '^1.0.0',
        };

        final warnings = analyzer.checkForWarnings(dependencies, devDependencies);

        final testWarnings = warnings
            .where((w) => w.package == 'flutter_test')
            .toList();
        expect(testWarnings.isEmpty, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle malformed pubspec.yaml', () async {
        final projectDir = Directory(path.join(tempDir.path, 'malformed'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
        await pubspecFile.writeAsString('invalid: yaml: content: [');

        expect(
          () => analyzer.analyzeDependencies(pubspecFile),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle missing pubspec.yaml', () async {
        final projectDir = Directory(path.join(tempDir.path, 'missing'));
        await projectDir.create(recursive: true);

        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        expect(
          () => analyzer.analyzeDependencies(pubspecFile),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Data Models', () {
      test('should serialize DependencyInfo to JSON correctly', () async {
        final projectDir = await AnalysisTestFixtures.createComplexFlutterProject(tempDir);
        final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));

        final dependencyInfo = await analyzer.analyzeDependencies(pubspecFile);
        final json = dependencyInfo.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['dependencies'], isA<Map<String, dynamic>>());
        expect(json['dev_dependencies'], isA<Map<String, dynamic>>());
        expect(json['categories'], isA<Map<String, dynamic>>());
        expect(json['fly_packages'], isA<List<dynamic>>());
        expect(json['warnings'], isA<List<dynamic>>());
        expect(json['conflicts'], isA<List<dynamic>>());
      });

      test('should serialize DependencyWarning to JSON correctly', () {
        const warning = DependencyWarning(
          package: 'test_package',
          message: 'Test warning',
          severity: 'medium',
        );

        final json = warning.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['package'], equals('test_package'));
        expect(json['message'], equals('Test warning'));
        expect(json['severity'], equals('medium'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty dependencies', () {
        final dependencies = <String, String>{};
        final devDependencies = <String, String>{};

        final categories = analyzer.categorizeDependencies(dependencies);
        final flyPackages = analyzer.detectFlyPackages(dependencies);
        final warnings = analyzer.checkForWarnings(dependencies, devDependencies);
        final conflicts = analyzer.checkForConflicts(dependencies);

        expect(categories.isEmpty, isTrue);
        expect(flyPackages.isEmpty, isTrue);
        expect(warnings.isEmpty, isTrue);
        expect(conflicts.isEmpty, isTrue);
      });

      test('should handle dependencies with special characters', () {
        final dependencies = <String, String>{
          'package-with-dashes': '^1.0.0',
          'package_with_underscores': '^2.0.0',
          'package.with.dots': '^3.0.0',
        };

        final categories = analyzer.categorizeDependencies(dependencies);

        expect(categories.containsKey('other'), isTrue);
        final other = categories['other']!;
        expect(other.contains('package-with-dashes'), isTrue);
        expect(other.contains('package_with_underscores'), isTrue);
        expect(other.contains('package.with.dots'), isTrue);
      });

      test('should handle version constraints correctly', () {
        final dependencies = <String, String>{
          'package1': '^1.0.0',
          'package2': '>=2.0.0 <3.0.0',
          'package3': 'any',
          'package4': '1.0.0',
        };

        final warnings = analyzer.checkForWarnings(dependencies, {});

        // Should not throw and should process all version formats
        expect(warnings, isA<List<DependencyWarning>>());
      });
    });
  });
}
