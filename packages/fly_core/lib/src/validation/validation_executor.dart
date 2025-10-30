import 'validation_result.dart';
import 'validation_rule.dart';

/// Executor for running validation rules in sequence
/// 
/// Provides utilities for executing validation rules in order
/// and combining their results.
class ValidationExecutor {
  const ValidationExecutor();

  /// Execute multiple rules in sequence
  /// 
  /// Rules are executed in priority order (lowest first).
  /// Returns a combined result of all rule executions.
  Future<ValidationResult> executeAll<T>(
    List<ValidationRule<T>> rules,
    T value, {
    String? fieldName,
    bool stopOnFirstFailure = false,
  }) async {
    // Sort rules by priority
    final sortedRules = List<ValidationRule<T>>.from(rules)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final results = <ValidationResult>[];

    for (final rule in sortedRules) {
      // Check if rule should run
      if (!rule.shouldRun(value)) {
        continue;
      }

      final result = await rule.validate(value, fieldName: fieldName);
      results.add(result);

      // Stop on first failure if configured
      if (stopOnFirstFailure && !result.isValid) {
        break;
      }
    }

    // Combine all results
    return ValidationResult.combine(results);
  }

  /// Execute rules in parallel
  /// 
  /// All rules execute concurrently and results are combined.
  /// Note: Parallel execution may not respect priority ordering.
  Future<ValidationResult> executeAllParallel<T>(
    List<ValidationRule<T>> rules,
    T value, {
    String? fieldName,
  }) async {
    // Filter rules that should run
    final applicableRules = rules.where((rule) => rule.shouldRun(value)).toList();

    // Execute all rules in parallel
    final results = await Future.wait(
      applicableRules.map(
        (rule) => rule.validate(value, fieldName: fieldName),
      ),
    );

    // Combine all results
    return ValidationResult.combine(results);
  }

  /// Execute a single rule
  /// 
  /// Convenience method for executing a single rule.
  Future<ValidationResult> execute<T>(
    ValidationRule<T> rule,
    T value, {
    String? fieldName,
  }) async {
    if (!rule.shouldRun(value)) {
      return ValidationResult.success();
    }

    return await rule.validate(value, fieldName: fieldName);
  }

  /// Validate and throw on failure
  /// 
  /// Executes validation and throws an exception if validation fails.
  Future<void> validateAndThrow<T>(
    List<ValidationRule<T>> rules,
    T value, {
    String? fieldName,
    String? errorPrefix,
  }) async {
    final result = await executeAll(rules, value, fieldName: fieldName);

    if (!result.isValid) {
      final prefix = errorPrefix ?? 'Validation failed';
      final errorMessage = result.errors.join('; ');
      throw ValidationException('$prefix: $errorMessage');
    }

    if (result.warnings.isNotEmpty && errorPrefix != null) {
      // Log warnings if error prefix provided
      final warningMessage = result.warnings.join('; ');
      throw ValidationWarning('$errorPrefix: $warningMessage');
    }
  }
}

/// Exception thrown when validation fails
class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Warning for validation issues
class ValidationWarning implements Exception {
  const ValidationWarning(this.message);
  final String message;

  @override
  String toString() => message;
}

