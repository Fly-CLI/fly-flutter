import 'dart:io';

import '../process_execution/process_execution.dart';
import 'validation_result.dart';
import 'validation_rule.dart';

/// Common string validation rules
class CommonValidationRules {
  /// Validate string is not empty
  static ValidationResult validateNotEmpty(String value, String fieldName) {
    if (value.isEmpty) {
      return ValidationResult.failure(['$fieldName cannot be empty']);
    }
    return ValidationResult.success();
  }

  /// Validate string length is within range
  static ValidationResult validateLength(
    String value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (minLength != null && value.length < minLength) {
      return ValidationResult.failure([
        '$fieldName must be at least $minLength characters long',
      ]);
    }

    if (maxLength != null && value.length > maxLength) {
      return ValidationResult.failure([
        '$fieldName must be no more than $maxLength characters long',
      ]);
    }

    return ValidationResult.success();
  }

  /// Validate string matches a pattern
  static ValidationResult validatePattern(
    String value,
    String fieldName,
    Pattern pattern,
    String patternDescription,
  ) {
    if (!pattern.allMatches(value).isNotEmpty) {
      return ValidationResult.failure([
        '$fieldName must match pattern: $patternDescription',
      ]);
    }
    return ValidationResult.success();
  }

  /// Validate string is not in a list of reserved words
  static ValidationResult validateNotReserved(
    String value,
    String fieldName,
    Set<String> reservedWords,
  ) {
    if (reservedWords.contains(value)) {
      return ValidationResult.failure([
        '$fieldName cannot be a reserved word: "$value"',
      ]);
    }
    return ValidationResult.success();
  }

  /// Validate string is in allowed list
  static ValidationResult validateInList(
    String value,
    String fieldName,
    List<String> allowedValues,
  ) {
    if (!allowedValues.contains(value)) {
      return ValidationResult.failure([
        '$fieldName must be one of: ${allowedValues.join(', ')}',
      ]);
    }
    return ValidationResult.success();
  }
}

/// Name validation rule for Dart identifiers
class NameValidationRule extends SyncValidationRule<String> {
  /// Minimum length for names
  static const int minLength = 2;

  /// Maximum length for names
  static const int maxLength = 50;

  /// Pattern for valid names
  static final RegExp pattern = RegExp(r'^[a-z][a-z0-9_]*$');

  /// Reserved words that cannot be used
  static const Set<String> reservedWords = {
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

  @override
  bool get isAsync => false;

  @override
  int get priority => 0;

  @override
  ValidationResult validateSync(String value, {String? fieldName}) {
    final name = fieldName ?? 'Name';

    // Check not empty
    final notEmptyResult = CommonValidationRules.validateNotEmpty(value, name);
    if (!notEmptyResult.isValid) return notEmptyResult;

    // Check length
    final lengthResult = CommonValidationRules.validateLength(
      value,
      name,
      minLength: minLength,
      maxLength: maxLength,
    );
    if (!lengthResult.isValid) return lengthResult;

    // Check not reserved
    final reservedResult = CommonValidationRules.validateNotReserved(
      value,
      name,
      reservedWords,
    );
    if (!reservedResult.isValid) return reservedResult;

    // Check pattern
    final patternResult = CommonValidationRules.validatePattern(
      value,
      name,
      pattern,
      'lowercase letters, numbers, underscores, starting with a letter',
    );
    if (!patternResult.isValid) return patternResult;

    return ValidationResult.success();
  }

  @override
  bool shouldRun(String value) => true;
}

/// File existence validation rule
class FileExistsRule implements ValidationRule<String> {
  @override
  bool get isAsync => false;

  @override
  int get priority => 0;

  @override
  Future<ValidationResult> validate(String value, {String? fieldName}) async {
    final file = File(value);
    if (await file.exists()) {
      return ValidationResult.success();
    }
    return ValidationResult.failure([
      'File does not exist: ${fieldName ?? 'File'}'
    ]);
  }

  @override
  bool shouldRun(String value) => value.isNotEmpty;
}

/// Directory existence validation rule
class DirectoryExistsRule implements ValidationRule<String> {
  @override
  bool get isAsync => false;

  @override
  int get priority => 0;

  @override
  Future<ValidationResult> validate(String value, {String? fieldName}) async {
    final directory = Directory(value);
    if (await directory.exists()) {
      return ValidationResult.success();
    }
    return ValidationResult.failure([
      'Directory does not exist: ${fieldName ?? 'Directory'}'
    ]);
  }

  @override
  bool shouldRun(String value) => value.isNotEmpty;
}

/// Network connectivity validation rule
class NetworkConnectivityRule extends AsyncValidationRule<String> {
  final ProcessExecutor? processExecutor;

  NetworkConnectivityRule({ProcessExecutor? processExecutor})
      : processExecutor = processExecutor ?? ProcessExecutor.defaults();

  @override
  bool get isAsync => true;

  @override
  bool get enableCache => true;

  @override
  int get priority => 100;

  @override
  Future<ValidationResult> validate(String value, {String? fieldName}) async {
    final cacheKey = generateCacheKey(value, fieldName: fieldName);
    final cached = getCachedResult(cacheKey);
    if (cached != null) {
      return cached;
    }

    try {
      final result = await processExecutor!.execute(
        Platform.isWindows ? 'ping' : 'ping',
        [Platform.isWindows ? '-n' : '-c', '1', value],
      );

      final validationResult = result.success
          ? ValidationResult.success()
          : ValidationResult.failure([
              'Cannot reach $value - check your internet connection',
            ]);

      cacheResult(cacheKey, validationResult);
      return validationResult;
    } catch (e) {
      final validationResult = ValidationResult.failure([
        'Network connectivity check failed for $value: $e',
      ]);
      cacheResult(cacheKey, validationResult);
      return validationResult;
    }
  }

  @override
  bool shouldRun(String value) => value.isNotEmpty;
}

