import 'package:args/args.dart';
import 'dart:io';

import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_validator.dart';

/// Validates required arguments are present
class RequiredArgumentValidator extends CommandValidator {
  RequiredArgumentValidator(this.argumentName);

  final String argumentName;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    if (args.rest.isEmpty) {
      return ValidationResult.failure([
        'Required argument "$argumentName" is missing',
      ]);
    }

    return ValidationResult.success();
  }

  @override
  int get priority => 100; // High priority for required arguments
}

/// Validates project name format
class ProjectNameValidator extends CommandValidator {
  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    if (args.rest.isEmpty) return ValidationResult.success();

    final projectName = args.rest.first;
    
    if (!_isValidProjectName(projectName)) {
      return ValidationResult.failure([
        'Invalid project name: $projectName',
        'Project name must contain only lowercase letters, numbers, and underscores',
        'Must start with a letter and be 2-50 characters long',
      ]);
    }

    return ValidationResult.success();
  }

  bool _isValidProjectName(String name) {
    if (name.isEmpty || name.length < 2 || name.length > 50) {
      return false;
    }
    final regex = RegExp(r'^[a-z][a-z0-9_]*$');
    return regex.hasMatch(name);
  }

  @override
  int get priority => 200;
}

/// Validates that we're in a Flutter project directory
class FlutterProjectValidator extends CommandValidator {
  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final pubspecFile = File('pubspec.yaml');
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

/// Validates directory permissions
class DirectoryWritableValidator extends CommandValidator {
  DirectoryWritableValidator([this.targetDirectory]);

  final String? targetDirectory;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final directory = Directory(targetDirectory ?? context.workingDirectory);
    
    if (!directory.existsSync()) {
      return ValidationResult.failure([
        'Directory does not exist: ${directory.path}',
      ]);
    }

    // Check if directory is writable by trying to create a temporary file
    try {
      final tempFile = File('${directory.path}/.fly_temp_${DateTime.now().millisecondsSinceEpoch}');
      tempFile.createSync();
      tempFile.deleteSync();
    } catch (e) {
      return ValidationResult.failure([
        'Directory is not writable: ${directory.path}',
        'Check permissions or try running with elevated privileges',
      ]);
    }

    return ValidationResult.success();
  }

  @override
  int get priority => 400;
}

/// Validates template exists
class TemplateExistsValidator extends CommandValidator {
  TemplateExistsValidator([this.templateName]);

  final String? templateName;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final template = templateName ?? args['template'] as String?;
    if (template == null) return ValidationResult.success();

    try {
      // Use the template manager to check if template exists
      final templates = await context.templateManager.getAvailableTemplates();
      if (!templates.contains(template)) {
        return ValidationResult.failure([
          'Template "$template" not found',
          'Available templates: ${templates.join(', ')}',
        ]);
      }
    } catch (e) {
      return ValidationResult.failure([
        'Failed to validate template: $e',
      ]);
    }

    return ValidationResult.success();
  }

  @override
  int get priority => 500;
}

/// Validates environment prerequisites
class EnvironmentValidator extends CommandValidator {
  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
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

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    return ValidationResult.success();
  }

  @override
  int get priority => 600;
}

/// Validates network connectivity
class NetworkValidator extends CommandValidator {
  NetworkValidator([this.requiredHosts = const ['pub.dev']]);

  final List<String> requiredHosts;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final errors = <String>[];
    
    for (final host in requiredHosts) {
      try {
        final result = await Process.run('ping', [
          context.environment.isWindows ? '-n' : '-c',
          '1',
          host,
        ]);
        
        if (result.exitCode != 0) {
          errors.add('Cannot reach $host - check your internet connection');
        }
      } catch (e) {
        errors.add('Network connectivity check failed for $host');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }

    return ValidationResult.success();
  }

  @override
  int get priority => 700;
}
