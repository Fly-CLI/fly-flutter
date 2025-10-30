import 'package:args/args.dart';
import 'package:fly_cli/src/core/command_foundation/domain/command_context.dart';
import 'package:fly_cli/src/core/validation/validation_rules.dart' as cli_validation;
import 'package:fly_core/src/validation/validation.dart';

/// Base interface for command validators
abstract class CommandValidator {
  /// Validate command arguments and environment
  Future<ValidationResult> validate(CommandContext context, ArgResults args);
  
  /// Priority for validator execution (lower numbers execute first)
  int get priority => 0;
  
  /// Whether this validator should run for the given command
  bool shouldRun(CommandContext context, String commandName) => true;

  /// Whether this validator supports async operations
  bool get isAsync => false;
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
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    // For positional arguments, check args.rest
    final argValue = args.rest.isNotEmpty ? args.rest.first : null;
    if (argValue == null || (argValue is String && argValue.isEmpty)) {
      return ValidationResult.failure([
        '$errorMessage: "$argumentName"',
      ]);
    }
    return ValidationResult.success();
  }
}

/// Validates that the command is run within a Flutter project context using centralized validation rules
class FlutterProjectValidator implements CommandValidator {
  @override
  int get priority => 10;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final rule = cli_validation.FlutterProjectValidationRule();
    return rule.validate(context.workingDirectory);
  }
}

/// Validates project name format using centralized validation rules
class ProjectNameValidator implements CommandValidator {
  @override
  int get priority => 5;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final projectName = args.rest.isNotEmpty ? args.rest.first : null;
    if (projectName == null) {
      return ValidationResult.failure(['Project name is required']);
    }
    return cli_validation.NameValidationRule.validateProjectName(projectName);
  }
}

/// Validates that a directory is writable using centralized validation rules
class DirectoryWritableValidator implements CommandValidator {
  final String? targetDirectory;

  DirectoryWritableValidator([this.targetDirectory]);

  @override
  int get priority => 15;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final directoryPath = targetDirectory ?? context.workingDirectory;
    final rule = cli_validation.DirectoryValidationRule(targetDirectory);
    return rule.validate(directoryPath);
  }
}

/// Validates that a template exists using centralized async validation rules
class TemplateExistsValidator implements CommandValidator {
  final String? templateName;

  TemplateExistsValidator([this.templateName]);

  @override
  int get priority => 20;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final template = templateName ?? args['template'] as String?;
    if (template == null) return ValidationResult.success();

    final rule = cli_validation.TemplateValidationRule(context);
    return rule.validate(template);
  }
}

/// Validates environment prerequisites using centralized async validation rules
class EnvironmentValidator implements CommandValidator {
  @override
  int get priority => 25;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => true;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final rule = cli_validation.EnvironmentValidationRule();
    return rule.validate(null);
  }
}

/// Validates network connectivity using centralized async validation rules
class NetworkValidator implements CommandValidator {
  final List<String> requiredHosts;

  NetworkValidator([this.requiredHosts = const ['pub.dev']]);

  @override
  int get priority => 30;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => true;

  @override
  Future<ValidationResult> validate(CommandContext context,
      ArgResults args) async {
    final rule = cli_validation.NetworkValidationRule(requiredHosts: requiredHosts);
    final results = <ValidationResult>[];

    for (final host in requiredHosts) {
      final result = await rule.validate(host);
      results.add(result);
    }

    return ValidationResult.combine(results);
  }
}

/// Validates screen name format using centralized validation rules
class ScreenNameValidator implements CommandValidator {
  @override
  int get priority => 5;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final screenName = args.rest.isNotEmpty ? args.rest.first : null;
    if (screenName == null) {
      return ValidationResult.failure(['Screen name is required']);
    }
    return cli_validation.NameValidationRule.validateScreenName(screenName);
  }
}

/// Validates service name format using centralized validation rules
class ServiceNameValidator implements CommandValidator {
  @override
  int get priority => 5;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context,
      ArgResults args) async {
    final serviceName = args.rest.isNotEmpty ? args.rest.first : null;
    if (serviceName == null) {
      return ValidationResult.failure(['Service name is required']);
    }
    return cli_validation.NameValidationRule.validateServiceName(serviceName);
  }
}

/// Validates feature name format using centralized validation rules
class FeatureNameValidator implements CommandValidator {
  @override
  int get priority => 5;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context,
      ArgResults args) async {
    final featureName = args['feature'] as String?;
    if (featureName == null) {
      return ValidationResult.failure(['Feature name is required']);
    }
    return cli_validation.NameValidationRule.validateFeatureName(featureName);
  }
}

/// Validates platform values using centralized validation rules
class PlatformValidator implements CommandValidator {
  @override
  int get priority => 5;

  @override
  bool shouldRun(CommandContext context, String commandName) => true;

  @override
  bool get isAsync => false;

  @override
  Future<ValidationResult> validate(CommandContext context, ArgResults args) async {
    final platforms = args['platforms'] as List<String>?;
    if (platforms == null) return ValidationResult.success();

    final rule = cli_validation.PlatformValidationRule();
    return rule.validate(platforms);
  }
}
