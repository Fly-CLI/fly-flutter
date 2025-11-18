import 'dart:io';

import 'package:mason/mason.dart';
import 'package:test/test.dart';

import '../plugins/foundation_model.dart';
import '../plugins/hook_orchestrator.dart';
import '../plugins/variables/composed_derived_variables.dart';
import '../plugins/variables/shared_derived_variables.dart';
import '../plugins/variables/project_variables.dart';
import '../plugins/composition.dart';

void main() {
  group('HookOrchestrator', () {
    late Logger logger;
    late HookOrchestrator orchestrator;

    setUp(() {
      logger = Logger();
      orchestrator = HookOrchestrator();
    });

    group('plan', () {
      test('plans variables for project mode', () {
        final base = BaseTemplateVariables(
          name: 'test_project',
          organization: 'com.example',
          generationMode: GenerationMode.project,
          platforms: [PlatformType.ios, PlatformType.android],
        );

        final result = orchestrator.plan(base, logger);

        expect(result.shared.projectName, equals('test_project'));
        expect(result.shared.supportsIos, isTrue);
        expect(result.shared.supportsAndroid, isTrue);
        expect(result.modeSpecific, isA<ProjectVariables>());
      });
    });

    group('selectModules', () {
      test('selects project module for project mode', () {
        final base = BaseTemplateVariables(
          name: 'test_project',
          organization: 'com.example',
          generationMode: GenerationMode.project,
          platforms: [PlatformType.ios],
        );

        final composed = ComposedDerivedVariables(
          shared: SharedDerivedVariables.empty(),
          modeSpecific: const ProjectVariables(),
        );

        final result = orchestrator.selectModules(base, composed);

        expect(result.activeModules.length, equals(1));
        expect(result.activeModules.first, isA<ProjectModule>());
        expect(result.moduleVars['active_modules'], contains('project'));
      });
    });

    group('reorganizeFiles', () {
      test('handles non-existent output directory gracefully', () {
        final tempDir = Directory.systemTemp.createTempSync('hook_test_');
        final outputDir = Directory('${tempDir.path}/nonexistent');

        // Should not throw
        orchestrator.reorganizeFiles(
          outputDir,
          ['project'],
          logger,
        );

        tempDir.deleteSync(recursive: true);
      });

      test('handles non-existent modes directory gracefully', () {
        final tempDir = Directory.systemTemp.createTempSync('hook_test_');

        // Should not throw
        orchestrator.reorganizeFiles(
          tempDir,
          ['project'],
          logger,
        );

        tempDir.deleteSync(recursive: true);
      });

      test('removes inactive modules', () {
        final tempDir = Directory.systemTemp.createTempSync('hook_test_');
        final modesDir = Directory('${tempDir.path}/modes');
        modesDir.createSync(recursive: true);

        // Create inactive module directory
        final inactiveModule = Directory('${modesDir.path}/inactive');
        inactiveModule.createSync();
        final testFile = File('${inactiveModule.path}/test.txt');
        testFile.writeAsStringSync('test');

        orchestrator.reorganizeFiles(
          tempDir,
          ['project'], // Only project is active
          logger,
        );

        // Inactive module should be removed
        expect(inactiveModule.existsSync(), isFalse);

        tempDir.deleteSync(recursive: true);
      });

      test('moves project module files to root', () {
        final tempDir = Directory.systemTemp.createTempSync('hook_test_');
        final modesDir = Directory('${tempDir.path}/modes');
        modesDir.createSync(recursive: true);

        // Create project module directory
        final projectModule = Directory('${modesDir.path}/project');
        projectModule.createSync();
        final testFile = File('${projectModule.path}/test.txt');
        testFile.writeAsStringSync('test content');

        orchestrator.reorganizeFiles(
          tempDir,
          ['project'],
          logger,
        );

        // File should be moved to root
        final movedFile = File('${tempDir.path}/test.txt');
        expect(movedFile.existsSync(), isTrue);
        expect(movedFile.readAsStringSync(), equals('test content'));

        // Project module directory should be removed
        expect(projectModule.existsSync(), isFalse);

        tempDir.deleteSync(recursive: true);
      });

      test('merges feature module files into existing structure', () {
        final tempDir = Directory.systemTemp.createTempSync('hook_test_');
        final modesDir = Directory('${tempDir.path}/modes');
        modesDir.createSync(recursive: true);

        // Create feature module directory structure
        final featureModule = Directory('${modesDir.path}/feature');
        featureModule.createSync(recursive: true);
        final libDir = Directory('${featureModule.path}/lib');
        libDir.createSync(recursive: true);
        final testFile = File('${libDir.path}/test.dart');
        testFile.writeAsStringSync('test content');

        orchestrator.reorganizeFiles(
          tempDir,
          ['feature'],
          logger,
        );

        // File should be merged into existing structure
        final mergedFile = File('${tempDir.path}/lib/test.dart');
        expect(mergedFile.existsSync(), isTrue);
        expect(mergedFile.readAsStringSync(), equals('test content'));

        tempDir.deleteSync(recursive: true);
      });
    });
  });
}

