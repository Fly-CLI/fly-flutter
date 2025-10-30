import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:version/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:fly_cli/src/core/templates/brick_metadata.dart';

/// Responsible ONLY for validating brick structure and compatibility
/// 
/// This service is decoupled from discovery and generation.
/// It focuses solely on validating brick metadata and structure.
class BrickValidationService {
  BrickValidationService({
    required this.logger,
  });

  final Logger logger;

  /// Validate a brick's metadata and structure
  Future<BrickValidationResult> validate(BrickMetadata brick) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Validate metadata
      final metadataResult = brick.validate();
      errors.addAll(metadataResult.errors);
      warnings.addAll(metadataResult.warnings);

      // Validate file structure
      final structureResult = await _validateBrickStructure(brick);
      errors.addAll(structureResult.errors);
      warnings.addAll(structureResult.warnings);

      // Validate compatibility
      final compatibilityResult = await _validateBrickCompatibility(brick);
      errors.addAll(compatibilityResult.errors);
      warnings.addAll(compatibilityResult.warnings);

      return BrickValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return BrickValidationResult.failure(['Validation failed: $e']);
    }
  }

  /// Validate brick file structure
  Future<BrickValidationResult> _validateBrickStructure(BrickMetadata brick) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final brickDir = Directory(brick.path);
      if (!await brickDir.exists()) {
        errors.add('Brick directory does not exist: ${brick.path}');
        return BrickValidationResult.failure(errors);
      }

      // Check for __brick__ directory
      final brickContentDir = Directory(path.join(brick.path, '__brick__'));
      if (!await brickContentDir.exists()) {
        errors.add('Missing __brick__ directory: ${brickContentDir.path}');
      }

      // Check for brick.yaml or template.yaml
      final brickYamlFile = File(path.join(brick.path, 'brick.yaml'));
      final templateYamlFile = File(path.join(brick.path, 'template.yaml'));
      
      if (!await brickYamlFile.exists() && !await templateYamlFile.exists()) {
        errors.add('Missing brick.yaml or template.yaml in: ${brick.path}');
      }

      // Validate brick content based on type
      switch (brick.type) {
        case BrickType.project:
          await _validateProjectBrickStructure(brick, errors, warnings);
          break;
        case BrickType.screen:
          await _validateScreenBrickStructure(brick, errors, warnings);
          break;
        case BrickType.service:
          await _validateServiceBrickStructure(brick, errors, warnings);
          break;
        case BrickType.widget:
          await _validateWidgetBrickStructure(brick, errors, warnings);
          break;
        case BrickType.addon:
          await _validateAddonBrickStructure(brick, errors, warnings);
          break;
      }

      return BrickValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return BrickValidationResult.failure(['Structure validation failed: $e']);
    }
  }

  /// Validate project brick structure
  Future<void> _validateProjectBrickStructure(
    BrickMetadata brick,
    List<String> errors,
    List<String> warnings,
  ) async {
    final brickContentDir = Directory(path.join(brick.path, '__brick__'));
    
    // Check for essential project files
    final essentialFiles = [
      'pubspec.yaml',
      'lib/main.dart',
      'README.md',
    ];

    for (final fileName in essentialFiles) {
      final file = File(path.join(brickContentDir.path, fileName));
      if (!await file.exists()) {
        warnings.add('Missing recommended project file: $fileName');
      }
    }

    // Check for platform-specific directories
    final platformDirs = ['android', 'ios', 'web', 'windows', 'macos', 'linux'];
    for (final platformDir in platformDirs) {
      final dir = Directory(path.join(brickContentDir.path, platformDir));
      if (await dir.exists()) {
        logger.detail('Found platform directory: $platformDir');
      }
    }
  }

  /// Validate screen brick structure
  Future<void> _validateScreenBrickStructure(
    BrickMetadata brick,
    List<String> errors,
    List<String> warnings,
  ) async {
    final brickContentDir = Directory(path.join(brick.path, '__brick__'));
    
    // Check for screen file
    final screenFile = File(path.join(brickContentDir.path, '{{screen_name}}_screen.dart'));
    if (!await screenFile.exists()) {
      errors.add('Missing screen file: {{screen_name}}_screen.dart');
    }

    // Check for optional files
    final optionalFiles = [
      '{{screen_name}}_viewmodel.dart',
      '{{screen_name}}_screen_test.dart',
    ];

    for (final fileName in optionalFiles) {
      final file = File(path.join(brickContentDir.path, fileName));
      if (await file.exists()) {
        logger.detail('Found optional screen file: $fileName');
      }
    }
  }

  /// Validate service brick structure
  Future<void> _validateServiceBrickStructure(
    BrickMetadata brick,
    List<String> errors,
    List<String> warnings,
  ) async {
    final brickContentDir = Directory(path.join(brick.path, '__brick__'));
    
    // Check for service file
    final serviceFile = File(path.join(brickContentDir.path, '{{service_name}}_service.dart'));
    if (!await serviceFile.exists()) {
      errors.add('Missing service file: {{service_name}}_service.dart');
    }

    // Check for optional files
    final optionalFiles = [
      '{{service_name}}_service_test.dart',
      '{{service_name}}_service_mock.dart',
    ];

    for (final fileName in optionalFiles) {
      final file = File(path.join(brickContentDir.path, fileName));
      if (await file.exists()) {
        logger.detail('Found optional service file: $fileName');
      }
    }
  }

  /// Validate widget brick structure
  Future<void> _validateWidgetBrickStructure(
    BrickMetadata brick,
    List<String> errors,
    List<String> warnings,
  ) async {
    final brickContentDir = Directory(path.join(brick.path, '__brick__'));
    
    // Check for widget file
    final widgetFile = File(path.join(brickContentDir.path, '{{widget_name}}_widget.dart'));
    if (!await widgetFile.exists()) {
      errors.add('Missing widget file: {{widget_name}}_widget.dart');
    }

    // Check for optional files
    final optionalFiles = [
      '{{widget_name}}_widget_test.dart',
    ];

    for (final fileName in optionalFiles) {
      final file = File(path.join(brickContentDir.path, fileName));
      if (await file.exists()) {
        logger.detail('Found optional widget file: $fileName');
      }
    }
  }

  /// Validate addon brick structure
  Future<void> _validateAddonBrickStructure(
    BrickMetadata brick,
    List<String> errors,
    List<String> warnings,
  ) async {
    final brickContentDir = Directory(path.join(brick.path, '__brick__'));
    
    // Addon bricks have flexible structure
    // Just check that there's some content
    final files = await brickContentDir.list().toList();
    if (files.isEmpty) {
      warnings.add('Addon brick has no content files');
    }
  }

  /// Validate brick compatibility with current environment
  Future<BrickValidationResult> _validateBrickCompatibility(BrickMetadata brick) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Check Flutter SDK version compatibility
      if (brick.minFlutterSdk != null) {
        final currentFlutterVersion = await _getCurrentFlutterVersion();
        if (currentFlutterVersion != null) {
          if (currentFlutterVersion < brick.minFlutterSdk!) {
            errors.add(
              'Brick requires Flutter SDK ${brick.minFlutterSdk} or higher, '
              'but current version is $currentFlutterVersion'
            );
          }
        } else {
          warnings.add('Could not determine current Flutter SDK version');
        }
      }

      // Check Dart SDK version compatibility
      if (brick.minDartSdk != null) {
        final currentDartVersion = await _getCurrentDartVersion();
        if (currentDartVersion != null) {
          if (currentDartVersion < brick.minDartSdk!) {
            errors.add(
              'Brick requires Dart SDK ${brick.minDartSdk} or higher, '
              'but current version is $currentDartVersion'
            );
          }
        } else {
          warnings.add('Could not determine current Dart SDK version');
        }
      }

      return BrickValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return BrickValidationResult.failure(['Compatibility validation failed: $e']);
    }
  }

  /// Get current Flutter SDK version
  Future<Version?> _getCurrentFlutterVersion() async {
    try {
      final result = await Process.run('flutter', ['--version'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(output);
        if (match != null) {
          return Version.parse(match.group(1)!);
        }
      }
    } catch (e) {
      logger.warn('Failed to get Flutter version: $e');
    }
    return null;
  }

  /// Get current Dart SDK version
  Future<Version?> _getCurrentDartVersion() async {
    try {
      final result = await Process.run('dart', ['--version'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final match = RegExp(r'Dart SDK version: (\d+\.\d+\.\d+)').firstMatch(output);
        if (match != null) {
          return Version.parse(match.group(1)!);
        }
      }
    } catch (e) {
      logger.warn('Failed to get Dart version: $e');
    }
    return null;
  }
}
