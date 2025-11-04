import 'package:flutter_form/flutter_form.dart';

/// Interface for ViewModels that need form functionality
/// This should be implemented by ViewModels that work with flutter_form integration
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
