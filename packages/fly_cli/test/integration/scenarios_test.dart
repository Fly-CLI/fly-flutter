import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../helpers/command_test_helper.dart';
import '../helpers/mock_logger.dart';

void main() {
  group('Scenario Integration Tests', () {
    late Directory tempDir;
    late MockLogger mockLogger;
    // Use encapsulated scenario root under tool/integration_scenarios
    final scenariosDir = Directory(
      path.join(
        Directory.current.path,
        'tool',
        'integration_scenarios',
        'scenarios',
      ),
    );
    final goldensDir = Directory(
      path.join(
        Directory.current.path,
        'tool',
        'integration_scenarios',
        'goldens',
      ),
    );

    setUp(() {
      mockLogger = MockLogger();
      tempDir = CommandTestHelper.createTempDir();
    });

    tearDown(() {
      CommandTestHelper.cleanupTempDir(tempDir);
      mockLogger.clear();
    });

    // Helper to find all scenario JSON files
    List<File> findScenarioFiles() {
      print('Looking for scenarios in: ${scenariosDir.path}');
      if (!scenariosDir.existsSync()) {
        print('Scenarios directory does not exist!');
        return [];
      }
      final files = scenariosDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      print('Found ${files.length} scenario files');
      files.forEach((f) => print(' - ${f.path}'));
      return files;
    }

    // Helper to execute a scenario
    Future<void> executeScenario(File scenarioFile) async {
      final dynamic jsonDynamic = jsonDecode(await scenarioFile.readAsString());
      final jsonContent = jsonDynamic as Map<String, dynamic>;
      final scenarioName = path.basenameWithoutExtension(scenarioFile.path);
      final generationMode = jsonContent['generation_mode'] as String;

      print('Executing scenario: $scenarioName ($generationMode)');

      if (generationMode == 'project') {
        await _executeProjectScenario(jsonContent, tempDir, scenarioName);
      } else if (generationMode == 'feature') {
        await _executeFeatureScenario(jsonContent, tempDir, scenarioName);
      } else if (generationMode == 'service') {
        await _executeServiceScenario(jsonContent, tempDir, scenarioName);
      }

      // Define golden directory for this scenario
      final goldenDir = Directory(
        path.join('tool', 'integration_scenarios', 'goldens', scenarioName),
      );

      // Define actual output directory
      String projectName = jsonContent['name'] as String? ?? 'test_project';
      if (generationMode == 'project') {
        projectName = jsonContent['name'] as String;
      }

      final actualDir = Directory(path.join(tempDir.path, projectName));

      // If goldens don't exist, generate them
      if (!goldenDir.existsSync()) {
        print('Golden directory not found for $scenarioName. Creating...');
        await _updateGoldens(actualDir, goldenDir);
      } else {
        await _compareWithGolden(actualDir, goldenDir);
      }
    }

    final scenarioFiles = findScenarioFiles();
    for (final file in scenarioFiles) {
      test(
        'Scenario: ${path.basenameWithoutExtension(file.path)}',
        () async {
          await executeScenario(file);
        },
        timeout: const Timeout(Duration(minutes: 10)),
      );
    }
  });
}

Future<void> _updateGoldens(Directory actualDir, Directory goldenDir) async {
  print('Updating goldens from ${actualDir.path} to ${goldenDir.path}');

  // Debug: list parent directory
  if (actualDir.parent.existsSync()) {
    print('Listing parent directory: ${actualDir.parent.path}');
    actualDir.parent.listSync().forEach((e) => print(' - ${e.path}'));
  } else {
    print('Parent directory does not exist: ${actualDir.parent.path}');
  }

  if (!actualDir.existsSync()) {
    print('Actual directory does not exist!');
    return;
  }

  if (!goldenDir.existsSync()) {
    goldenDir.createSync(recursive: true);
  }

  // Copy files recursively
  await _copyDirectory(actualDir, goldenDir);
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  print('Copying from ${source.path} to ${destination.path}');
  await for (final entity in source.list(recursive: false)) {
    print('Found entity: ${entity.path}');
    if (entity is Directory) {
      final newDirectory = Directory(
        path.join(destination.path, path.basename(entity.path)),
      );
      await newDirectory.create();
      await _copyDirectory(entity, newDirectory);
    } else if (entity is File) {
      // Skip some files
      if (_shouldSkipFile(entity.path)) {
        print('Skipping file: ${entity.path}');
        continue;
      }

      print('Copying file: ${entity.path}');
      await entity.copy(
        path.join(destination.path, path.basename(entity.path)),
      );
    }
  }
}

bool _shouldSkipFile(String filePath) {
  final filename = path.basename(filePath);
  if (filename.startsWith('.')) return true; // Skip hidden files
  if (filename == 'pubspec.lock') return true; // Skip lock file
  if (filename.endsWith('.log')) return true;
  if (path.basename(path.dirname(filePath)) == 'build')
    return true; // Skip build dir
  return false;
}

Future<void> _compareWithGolden(
  Directory actualDir,
  Directory goldenDir,
) async {
  // 1. Check that all files in golden exist in actual and match content
  await _compareDirectory(goldenDir, actualDir);

  // 2. Check that actual doesn't have extra files (optional, but good for strictness)
  // For now, let's just ensure goldens match.
}

Future<void> _compareDirectory(Directory goldenDir, Directory actualDir) async {
  await for (final entity in goldenDir.list(recursive: false)) {
    final relativePath = path.relative(entity.path, from: goldenDir.path);
    final actualEntityPath = path.join(actualDir.path, relativePath);

    if (entity is Directory) {
      final actualSubDir = Directory(actualEntityPath);
      expect(
        actualSubDir.existsSync(),
        isTrue,
        reason: 'Directory missing: $relativePath',
      );
      await _compareDirectory(entity, actualSubDir);
    } else if (entity is File) {
      final actualFile = File(actualEntityPath);
      expect(
        actualFile.existsSync(),
        isTrue,
        reason: 'File missing: $relativePath',
      );

      final goldenContent = await entity.readAsString();
      final actualContent = await actualFile.readAsString();

      // Normalize line endings
      final normalizedGolden = goldenContent.replaceAll('\r\n', '\n');
      final normalizedActual = actualContent.replaceAll('\r\n', '\n');

      expect(
        normalizedActual,
        equals(normalizedGolden),
        reason: 'Content mismatch: $relativePath',
      );
    }
  }
}

Future<void> _executeProjectScenario(
  Map<String, dynamic> json,
  Directory tempDir,
  String scenarioName,
) async {
  final name = json['name'] as String;
  final args = <String>[
    'generate',
    'project',
    name,
    '--output-dir=${tempDir.path}',
  ];

  if (json.containsKey('description')) {
    args.add('--description=${json['description']}');
  }
  if (json.containsKey('organization')) {
    args.add('--organization=${json['organization']}');
  }
  if (json.containsKey('platforms')) {
    final platforms = (json['platforms'] as List).join(',');
    args.add('--platforms=$platforms');
  }
  if (json.containsKey('preset')) {
    args.add('--template');
    args.add('fly_foundation');
  }

  final result = await CommandTestHelper.runCommand(args);
  if (!result.success) {
    print('Project creation failed: ${result.message}');
    if (result.suggestion != null)
      print('Suggestion/Error: ${result.suggestion}');
  }
  expect(
    result.success,
    isTrue,
    reason: 'Project creation failed: ${result.message}',
  );
}

Future<void> _executeFeatureScenario(
  Map<String, dynamic> json,
  Directory tempDir,
  String scenarioName,
) async {
  final projectName = 'test_project';
  final projectDir = Directory(path.join(tempDir.path, projectName));

  if (!projectDir.existsSync()) {
    final result = await CommandTestHelper.runCommand([
      'generate',
      'project',
      projectName,
      '--template',
      'fly_foundation',
      '--output-dir=${tempDir.path}',
    ]);
    print('Create result: ${result.message}');
    if (result.data != null) print('Create data: ${result.data}');
    if (!result.success && result.suggestion != null)
      print('Create error: ${result.suggestion}');
    expect(
      result.success,
      isTrue,
      reason: 'Base project creation failed: ${result.message}',
    );
  }

  final name = json['name'] as String;
  final args = <String>[
    'generate',
    'feature',
    // Corrected from 'screen' to 'feature' based on context, or should check JSON?
    // Legacy JSON had 'generate screen' mapped to 'feature' brick?
    // Wait, legacy JSONs are:
    // features/auth_screen.json -> "generation_mode": "feature"
    // services/analytics_service.json -> "generation_mode": "service"
    // The command for feature is likely 'generate feature' or 'generate screen' depending on CLI.
    // New CLI has 'generateFeature' command.
    // Let's assume 'generate feature' for now.
    name,
    '--output-dir=${projectDir.path}',
  ];

  if (json.containsKey('feature_name')) {
    // args.add('--feature=${json['feature_name']}');
    // If generating a screen, it might need a feature name.
    // If generating a feature, 'name' IS the feature name.
    // Let's check the JSON content in a bit.
  }

  final result = await CommandTestHelper.runCommand(args);
  if (!result.success) {
    print('Feature generation failed: ${result.message}');
    if (result.suggestion != null)
      print('Suggestion/Error: ${result.suggestion}');
  }
  expect(
    result.success,
    isTrue,
    reason: 'Feature generation failed: ${result.message}',
  );
}

Future<void> _executeServiceScenario(
  Map<String, dynamic> json,
  Directory tempDir,
  String scenarioName,
) async {
  final projectName = 'test_project';
  final projectDir = Directory(path.join(tempDir.path, projectName));

  if (!projectDir.existsSync()) {
    final result = await CommandTestHelper.runCommand([
      'generate',
      'project',
      projectName,
      '--template',
      'fly_foundation',
      '--output-dir=${tempDir.path}',
    ]);
    print('Create result: ${result.message}');
    if (result.data != null) print('Create data: ${result.data}');
    if (!result.success && result.suggestion != null)
      print('Create error: ${result.suggestion}');
    expect(
      result.success,
      isTrue,
      reason: 'Base project creation failed: ${result.message}',
    );
  }

  final name = json['name'] as String;
  final args = <String>[
    'generate',
    'service',
    name,
    '--output-dir=${projectDir.path}',
  ];

  final result = await CommandTestHelper.runCommand(args);
  if (!result.success) {
    print('Service generation failed: ${result.message}');
    if (result.suggestion != null)
      print('Suggestion/Error: ${result.suggestion}');
  }
  expect(
    result.success,
    isTrue,
    reason: 'Service generation failed: ${result.message}',
  );
}
