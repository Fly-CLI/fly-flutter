import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';

/// Base interface for composable validation rules
abstract class ValidationRule<T> {
  /// Validate a value and return a ValidationResult
  Future<ValidationResult> validate(T value, {String? fieldName});

  /// Whether this rule supports async operations
  bool get isAsync => false;

  /// Priority for rule execution (lower numbers execute first)
  int get priority => 0;
}

/// Core validation rules for names and identifiers
class NameValidationRule {
  // Constants for validation rules
  static const int minLength = 2;
  static const int maxLength = 50;
  static final RegExp _pattern = RegExp(r'^[a-z][a-z0-9_]*$');
  
  // Reserved words that cannot be used as names
  static const Set<String> _reservedWords = {
    'null',
    'true',
    'false',
    'void',
    'dynamic',
    'var',
    'final',
    'const',
    'class',
    'enum',
    'extends',
    'implements',
    'with',
    'mixin',
    'abstract',
    'interface',
    'typedef',
  };

  /// Validate project name format
  static ValidationResult validateProjectName(
    String name, {
    String? fieldName,
  }) {
    return _validateName(name, fieldName ?? 'Project name');
  }

  /// Validate screen name format
  static ValidationResult validateScreenName(String name, {String? fieldName}) {
    return _validateName(name, fieldName ?? 'Screen name');
  }

  /// Validate service name format
  static ValidationResult validateServiceName(
    String name, {
    String? fieldName,
  }) {
    return _validateName(name, fieldName ?? 'Service name');
  }

  /// Validate feature name format
  static ValidationResult validateFeatureName(
    String name, {
    String? fieldName,
  }) {
    return _validateName(name, fieldName ?? 'Feature name');
  }

  /// Generic name validation logic
  static ValidationResult _validateName(String name, String fieldName) {
    if (name.isEmpty) {
      return ValidationResult.failure(['$fieldName cannot be empty']);
    }

    if (name.length < minLength) {
      return ValidationResult.failure([
        '$fieldName must be at least $minLength characters long',
      ]);
    }

    if (name.length > maxLength) {
      return ValidationResult.failure([
        '$fieldName must be no more than $maxLength characters long',
      ]);
    }

    if (_reservedWords.contains(name)) {
      return ValidationResult.failure([
        '$fieldName cannot be a reserved word: "$name"',
      ]);
    }

    if (!_pattern.hasMatch(name)) {
      return ValidationResult.failure([
        '$fieldName must contain only lowercase letters, numbers, and underscores',
        '$fieldName must start with a letter',
      ]);
    }

    return ValidationResult.success();
  }

  /// Quick boolean check for project name validity
  static bool isValidProjectName(String name) {
    return validateProjectName(name).isValid;
  }

  /// Quick boolean check for screen name validity
  static bool isValidScreenName(String name) {
    return validateScreenName(name).isValid;
  }

  /// Quick boolean check for service name validity
  static bool isValidServiceName(String name) {
    return validateServiceName(name).isValid;
  }

  /// Quick boolean check for feature name validity
  static bool isValidFeatureName(String name) {
    return validateFeatureName(name).isValid;
  }
}

/// Async validation rule for expensive operations
abstract class AsyncValidationRule<T> implements ValidationRule<T> {
  @override
  bool get isAsync => true;

  /// Cache for validation results
  final Map<String, ValidationResult> _cache = {};

  /// Cache duration in milliseconds
  Duration get cacheDuration => const Duration(minutes: 5);

  /// Get cached result if available and not expired
  ValidationResult? getCachedResult(String key) {
    // For now, we'll implement simple caching without expiration
    // In a production system, you'd want to track timestamps
    return _cache[key];
  }

  /// Cache a validation result
  void cacheResult(String key, ValidationResult result) {
    _cache[key] = result;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}

/// Validation rule for network connectivity
class NetworkValidationRule extends AsyncValidationRule<String> {
  NetworkValidationRule({this.requiredHosts = const ['pub.dev']});

  final List<String> requiredHosts;

  @override
  Future<ValidationResult> validate(String host, {String? fieldName}) async {
    final cacheKey = 'network_$host';
    final cached = getCachedResult(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final result = await Process.run('ping', [
        if (Platform.isWindows) '-n' else '-c',
        '1',
        host,
      ]);

      final validationResult = result.exitCode == 0
          ? ValidationResult.success()
          : ValidationResult.failure([
              'Cannot reach $host - check your internet connection',
            ]);

      cacheResult(cacheKey, validationResult);
      return validationResult;
    } catch (e) {
      final validationResult = ValidationResult.failure([
        'Network connectivity check failed for $host: $e',
      ]);
      cacheResult(cacheKey, validationResult);
      return validationResult;
    }
  }

  @override
  int get priority => 700;
}

/// Validation rule for environment prerequisites
class EnvironmentValidationRule extends AsyncValidationRule<void> {
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
      final flutterVersion = await Process.run('flutter', ['--version']);
      if (flutterVersion.exitCode != 0) {
        errors.add('Flutter SDK not found or not working');
      }
    } catch (e) {
      errors.add('Flutter SDK not found in PATH');
    }

    // Check Dart SDK
    try {
      final dartVersion = await Process.run('dart', ['--version']);
      if (dartVersion.exitCode != 0) {
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
  int get priority => 600;
}

/// Validation rule for template existence
class TemplateValidationRule extends AsyncValidationRule<String> {
  TemplateValidationRule(this.context);

  final CommandContext context;

  @override
  Future<ValidationResult> validate(
    String templateName, {
    String? fieldName,
  }) async {
    final cacheKey = 'template_$templateName';
    final cached = getCachedResult(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final templates = await context.templateManager.getAvailableTemplates();
      final templateNames = templates.map((t) => t.name).toList();
      final validationResult = templateNames.contains(templateName)
          ? ValidationResult.success()
          : ValidationResult.failure([
              'Invalid template',
              'Available templates: ${templates.map((t) => t.toString()).join(', ')}',
            ]);

      cacheResult(cacheKey, validationResult);
      return validationResult;
    } catch (e) {
      final validationResult = ValidationResult.failure([
        'Failed to validate template: $e',
      ]);
      cacheResult(cacheKey, validationResult);
      return validationResult;
    }
  }

  @override
  int get priority => 500;
}

/// Validation rule for directory writability
class DirectoryValidationRule implements ValidationRule<String> {
  DirectoryValidationRule([this.targetDirectory]);

  final String? targetDirectory;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(
    String directoryPath, {
    String? fieldName,
  }) async {
    final directory = Directory(targetDirectory ?? directoryPath);

    if (!directory.existsSync()) {
      return ValidationResult.failure([
        'Directory does not exist: ${directory.path}',
      ]);
    }

    // Check if directory is writable by trying to create a temporary file
    try {
      File(
          '${directory.path}/.fly_temp_${DateTime.now().millisecondsSinceEpoch}',
        )
        ..createSync()
        ..deleteSync();
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure([
        'Directory is not writable: ${directory.path}',
        'Check permissions or try running with elevated privileges',
      ]);
    }
  }

  @override
  int get priority => 400;
}

/// Validation rule for Flutter project structure
class FlutterProjectValidationRule implements ValidationRule<String> {
  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(
    String projectPath, {
    String? fieldName,
  }) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return ValidationResult.failure([
        'Not in a Flutter project directory',
        'Run this command from a Flutter project root directory',
      ]);
    }

    return ValidationResult.success();
  }

  @override
  int get priority => 300;
}

/// Validation rule for platform validation
class PlatformValidationRule implements ValidationRule<List<String>> {
  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(
    List<String> platforms, {
    String? fieldName,
  }) async {
    const validPlatforms = ['ios', 'android', 'web', 'macos', 'windows', 'linux'];
    
    for (final platform in platforms) {
      if (!validPlatforms.contains(platform)) {
        return ValidationResult.failure([
          'Invalid platform',
          'Valid platforms: ${validPlatforms.join(', ')}',
        ]);
      }
    }
    
    return ValidationResult.success();
  }

  @override
  int get priority => 350;
}
