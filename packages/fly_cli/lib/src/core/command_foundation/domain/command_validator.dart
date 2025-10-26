import 'dart:io';
import 'package:args/args.dart';
import 'command_context.dart';
import 'command_result.dart';

/// Validation result for command arguments and environment
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
  
  /// Whether validation passed
  final bool isValid;
  
  /// List of validation errors
  final List<String> errors;
  
  /// List of validation warnings
  final List<String> warnings;
  
  /// Create a successful validation result
  factory ValidationResult.success() => const ValidationResult(isValid: true);
  
  /// Create a failed validation result with errors
  factory ValidationResult.failure(List<String> errors) => ValidationResult(
    isValid: false,
    errors: errors,
  );
  
  /// Create a validation result with warnings
  factory ValidationResult.withWarnings(List<String> warnings) => ValidationResult(
    isValid: true,
    warnings: warnings,
  );
  
  /// Combine multiple validation results
  factory ValidationResult.combine(List<ValidationResult> results) {
    final allErrors = <String>[];
    final allWarnings = <String>[];
    
    for (final result in results) {
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
    }
    
    return ValidationResult(
      isValid: allErrors.isEmpty,
      errors: allErrors,
      warnings: allWarnings,
    );
  }
  
  @override
  String toString() => 'ValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
}

/// Base interface for command validators
abstract class CommandValidator {
  /// Validate command arguments and environment
  Future<ValidationResult> validate(CommandContext context, ArgResults args);
  
  /// Priority for validator execution (lower numbers execute first)
  int get priority => 0;
  
  /// Whether this validator should run for the given command
  bool shouldRun(CommandContext context, String commandName) => true;
}

/// Validates that a required positional argument is present and not empty.
class RequiredArgumentValidator implements CommandValidator {
  final String argumentName;
  final String errorMessage;
  final String suggestion;

  RequiredArgumentValidator(
    this.argumentName, {
    this.errorMessage = 'Missing required argument',
    this.suggestion = 'Please provide the required argument.',
  });

  @override
  int get priority => 0;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final argValue = args[argumentName];
    if (argValue == null || (argValue is String && argValue.isEmpty)) {
      return ValidationResult.failure([
        '$errorMessage: "$argumentName"',
      ]);
    }
    return ValidationResult.success();
  }
}

/// Validates that the command is run within a Flutter project context.
class FlutterProjectValidator implements CommandValidator {
  @override
  int get priority => 10;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    // Check if pubspec.yaml exists
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return ValidationResult.failure([
        'Not in a Flutter project directory',
      ]);
    }
    return ValidationResult.success();
  }
}

/// Validates project name format.
class ProjectNameValidator implements CommandValidator {
  @override
  int get priority => 5;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final projectName = args.rest.isNotEmpty ? args.rest.first : null;
    if (projectName != null && !_isValidProjectName(projectName)) {
      return ValidationResult.failure([
        'Invalid project name: $projectName',
      ]);
    }
    return ValidationResult.success();
  }

  bool _isValidProjectName(String name) {
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }
}

/// Validates that a directory is writable.
class DirectoryWritableValidator implements CommandValidator {
  final String? targetDirectory;

  DirectoryWritableValidator([this.targetDirectory]);

  @override
  int get priority => 15;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final dir = Directory(targetDirectory ?? context.workingDirectory);
    if (!dir.existsSync()) {
      return ValidationResult.failure([
        'Directory does not exist: ${dir.path}',
      ]);
    }
    
    // Check if directory is writable by trying to create a test file
    try {
      final testFile = File('${dir.path}/.fly_test_write');
      testFile.writeAsStringSync('test');
      testFile.deleteSync();
      return ValidationResult.success();
    } catch (e) {
      return ValidationResult.failure([
        'Directory is not writable: ${dir.path}',
      ]);
    }
  }
}

/// Validates that a template exists.
class TemplateExistsValidator implements CommandValidator {
  final String? templateName;

  TemplateExistsValidator([this.templateName]);

  @override
  int get priority => 20;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    // For now, just return success - template validation would be more complex
    return ValidationResult.success();
  }
}

/// Validates environment prerequisites.
class EnvironmentValidator implements CommandValidator {
  @override
  int get priority => 25;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    // For now, just return success - environment validation would be more complex
    return ValidationResult.success();
  }
}

/// Validates network connectivity.
class NetworkValidator implements CommandValidator {
  final List<String> requiredHosts;

  NetworkValidator([this.requiredHosts = const ['pub.dev']]);

  @override
  int get priority => 30;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    // For now, just return success - network validation would be more complex
    return ValidationResult.success();
  }
}