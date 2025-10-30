import 'dart:io';

import 'package:path/path.dart' as path;

import '../process_execution/process_execution.dart';
import 'common_rules.dart';
import 'validation_result.dart';
import 'validation_rule.dart';

/// Flutter project validation rule
/// 
/// Validates that the current directory is a Flutter project.
class FlutterProjectValidationRule implements ValidationRule<String> {
  const FlutterProjectValidationRule();

  @override
  bool get isAsync => false;

  @override
  int get priority => 300;

  @override
  Future<ValidationResult> validate(String projectPath, {String? fieldName}) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      return ValidationResult.failure([
        'Not in a Flutter project directory',
        'Run this command from a Flutter project root directory',
      ]);
    }

    return ValidationResult.success();
  }

  @override
  bool shouldRun(String value) => value.isNotEmpty;
}

/// Directory writability validation rule
/// 
/// Validates that a directory exists and is writable.
class DirectoryWritableRule implements ValidationRule<String> {
  const DirectoryWritableRule();

  @override
  bool get isAsync => false;

  @override
  int get priority => 400;

  @override
  Future<ValidationResult> validate(String directoryPath, {String? fieldName}) async {
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      return ValidationResult.failure([
        'Directory does not exist: ${directory.path}',
      ]);
    }

    // Check if directory is writable by trying to create a temporary file
    try {
      final tempFile = File(
        '${directory.path}/.fly_temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      await tempFile.create();
      await tempFile.delete();
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure([
        'Directory is not writable: ${directory.path}',
        'Check permissions or try running with elevated privileges',
      ]);
    }
  }

  @override
  bool shouldRun(String value) => value.isNotEmpty;
}

/// Platform validation rule
/// 
/// Validates that platform names are valid Flutter platforms.
class PlatformValidationRule implements ValidationRule<List<String>> {
  const PlatformValidationRule();

  static const List<String> validPlatforms = [
    'ios',
    'android',
    'web',
    'macos',
    'windows',
    'linux',
  ];

  @override
  bool get isAsync => false;

  @override
  int get priority => 350;

  @override
  Future<ValidationResult> validate(List<String> platforms, {String? fieldName}) async {
    for (final platform in platforms) {
      if (!validPlatforms.contains(platform)) {
        return ValidationResult.failure([
          'Invalid platform: $platform',
          'Valid platforms: ${validPlatforms.join(', ')}',
        ]);
      }
    }

    return ValidationResult.success();
  }

  @override
  bool shouldRun(List<String> value) => value.isNotEmpty;
}

/// Environment prerequisites validation rule
/// 
/// Validates that required SDKs and tools are installed and working.
class EnvironmentValidationRule extends AsyncValidationRule<void> {
  final ProcessExecutor? processExecutor;

  EnvironmentValidationRule({ProcessExecutor? processExecutor})
      : processExecutor = processExecutor ?? ProcessExecutor.defaults();

  @override
  bool get isAsync => true;

  @override
  bool get enableCache => true;

  @override
  int get priority => 600;

  @override
  Future<ValidationResult> validate(void value, {String? fieldName}) async {
    const cacheKey = 'environment_check';
    final cached = getCachedResult(cacheKey);
    if (cached != null) {
      return cached;
    }

    final errors = <String>[];

    // Check Flutter SDK
    try {
      final flutterResult = await processExecutor!.execute('flutter', ['--version']);
      if (!flutterResult.success) {
        errors.add('Flutter SDK not found or not working');
      }
    } catch (e) {
      errors.add('Flutter SDK not found in PATH');
    }

    // Check Dart SDK
    try {
      final dartResult = await processExecutor!.execute('dart', ['--version']);
      if (!dartResult.success) {
        errors.add('Dart SDK not found or not working');
      }
    } catch (e) {
      errors.add('Dart SDK not found in PATH');
    }

    final validationResult = errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);

    cacheResult(cacheKey, validationResult);
    return validationResult;
  }

  @override
  bool shouldRun(void value) => true;
}

/// Combined validation rules for Flutter CLI operations
class FlutterCliValidationRules {
  /// Get project name validation rule
  static ValidationRule<String> projectNameRule() {
    return NameValidationRule();
  }

  /// Get screen name validation rule
  static ValidationRule<String> screenNameRule() {
    return NameValidationRule();
  }

  /// Get service name validation rule
  static ValidationRule<String> serviceNameRule() {
    return NameValidationRule();
  }

  /// Get feature name validation rule
  static ValidationRule<String> featureNameRule() {
    return NameValidationRule();
  }

  /// Get Flutter project validation rule
  static ValidationRule<String> flutterProjectRule() {
    return const FlutterProjectValidationRule();
  }

  /// Get directory writable validation rule
  static ValidationRule<String> directoryWritableRule() {
    return const DirectoryWritableRule();
  }

  /// Get platform validation rule
  static ValidationRule<List<String>> platformRule() {
    return const PlatformValidationRule();
  }

  /// Get environment validation rule
  static ValidationRule<void> environmentRule({ProcessExecutor? processExecutor}) {
    return EnvironmentValidationRule(processExecutor: processExecutor);
  }

  /// Get network connectivity validation rule
  static ValidationRule<String> networkRule({ProcessExecutor? processExecutor}) {
    return NetworkConnectivityRule(processExecutor: processExecutor);
  }
}

