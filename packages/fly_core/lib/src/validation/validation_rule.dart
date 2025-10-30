import 'validation_result.dart';

/// Base interface for composable validation rules
/// 
/// All validation rules implement this interface to provide
/// consistent validation behavior across packages.
abstract class ValidationRule<T> {
  /// Validate a value and return a ValidationResult
  Future<ValidationResult> validate(T value, {String? fieldName});

  /// Whether this rule supports async operations
  bool get isAsync => false;

  /// Priority for rule execution (lower numbers execute first)
  int get priority => 0;

  /// Whether this rule should run for the given value
  bool shouldRun(T value) => true;
}

/// Synchronous validation rule base class
/// 
/// For simple validation rules that don't need async operations.
abstract class SyncValidationRule<T> implements ValidationRule<T> {
  @override
  bool get isAsync => false;

  /// Synchronous validation implementation
  ValidationResult validateSync(T value, {String? fieldName});

  @override
  Future<ValidationResult> validate(T value, {String? fieldName}) async {
    return validateSync(value, fieldName: fieldName);
  }
}

/// Asynchronous validation rule base class
/// 
/// For validation rules that need async operations.
abstract class AsyncValidationRule<T> implements ValidationRule<T> {
  @override
  bool get isAsync => true;

  /// Cache for validation results (optional)
  final Map<String, ValidationResult> _cache = {};

  /// Whether to cache results
  bool get enableCache => false;

  /// Cache duration
  Duration get cacheDuration => const Duration(minutes: 5);

  /// Get cached result if available and not expired
  ValidationResult? getCachedResult(String key) {
    if (!enableCache) return null;
    return _cache[key];
  }

  /// Cache a validation result
  void cacheResult(String key, ValidationResult result) {
    if (enableCache) {
      _cache[key] = result;
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  /// Generate cache key from value
  String generateCacheKey(T value, {String? fieldName}) {
    return '$fieldName:$value';
  }
}

