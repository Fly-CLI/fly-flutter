// Note: flutter_form package is not available in foundation project
// This interface is a placeholder for form functionality
// In production, this would use flutter_form package

/// Validation result for form validation
class ValidationResult {
  final bool isValid;
  final Map<String, String?> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const {},
  });

  const ValidationResult.success()
      : isValid = true,
        errors = const {};

  const ValidationResult.failure(this.errors) : isValid = false;
}

/// Validation type for form fields
class ValidationType {
  final String type;
  final Map<String, dynamic>? constraints;

  const ValidationType(this.type, {this.constraints});

  factory ValidationType.email() => const ValidationType('email');
  factory ValidationType.text({int? minLength}) =>
      ValidationType('text', constraints: {'minLength': minLength});
}

/// Form controller stub
class FormController {
  final Map<String, String> _values = {};
  final Map<String, String?> _errors = {};

  bool get isValid => _errors.isEmpty;
  Map<String, String?> get errors => Map.unmodifiable(_errors);
  Map<String, String> get values => Map.unmodifiable(_values);

  void addField(String fieldName, ValidationType type,
      {bool required = false, Map<String, dynamic>? constraints}) {
    // Stub implementation
  }

  void setFieldValue(String fieldName, String value) {
    _values[fieldName] = value;
  }

  String getFieldValue(String fieldName) {
    return _values[fieldName] ?? '';
  }

  ValidationResult validateAll() {
    return ValidationResult.success();
  }

  void clear() {
    _values.clear();
    _errors.clear();
  }

  void reset() {
    clear();
  }
}

/// Interface for ViewModels that need form functionality
/// This should be implemented by ViewModels that work with form integration
abstract class FormViewModelInterface {
  /// Get the form controller instance
  FormController get formController;

  /// Check if form is valid
  bool get isFormValid;

  /// Get validation errors
  Map<String, String?> get validationErrors;

  /// Validate the entire form
  ValidationResult validateForm();

  /// Register a field with validation type
  void registerField(
    String fieldName,
    ValidationType type, {
    bool required = false,
    Map<String, dynamic>? constraints,
  });

  /// Set field value
  void setFieldValue(String fieldName, String value);

  /// Get field value
  String getFieldValue(String fieldName);

  /// Get form data as a map
  Map<String, String> get formData;

  /// Clear all form data
  void clearForm();

  /// Reset form to initial state
  void resetForm();

  /// Check if form has changes
  bool get hasFormChanges;
}
