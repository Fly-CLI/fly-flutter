import 'package:flutter_form/flutter_form.dart';

/// Mixin that provides form functionality for ViewModels
/// This should be used by ViewModels that need to work with flutter_form integration
/// 
/// ## Usage
/// 
/// ```dart
/// class MyFormViewModel extends ViewModel<MyFormState> with FormViewModelMixin {
///   @override
///   MyFormState build() {
///     // Setup form fields
///     registerField('email', ValidationType.email(), required: true);
///     registerField('name', ValidationType.text(minLength: 2));
///     return MyFormState.initial();
///   }
///   
///   @override
///   void onDispose() {
///     disposeFormController(); // Clean up controllers
///     super.onDispose();
///   }
/// }
/// ```
/// 
/// **IMPORTANT:** Always call `disposeFormController()` in your ViewModel's `onDispose()` 
/// method to prevent memory leaks. The FormController manages TextEditingController and 
/// FocusNode instances that must be properly disposed.
mixin FormViewModelMixin {
  FormController? _formController;
  bool _isFormControllerDisposed = false;

  /// Get the form controller instance
  /// Lazily initializes the controller on first access
  FormController get formController {
    if (_isFormControllerDisposed) {
      throw StateError(
        'FormController has been disposed. Cannot access after disposal.',
      );
    }
    _formController ??= FormController();
    return _formController!;
  }

  /// Check if form controller has been created
  bool get hasFormController => _formController != null;

  /// Check if form is valid
  bool get isFormValid => formController.isValid;

  /// Get validation errors
  Map<String, String?> get validationErrors => formController.errors;

  /// Validate the entire form
  ValidationResult validateForm() {
    return formController.validateAll();
  }

  /// Register a field with validation type
  void registerField(
    String fieldName,
    ValidationType type, {
    bool required = false,
    Map<String, dynamic>? constraints,
  }) {
    formController.addField(
      fieldName,
      type,
      required: required,
      constraints: constraints,
    );
  }

  /// Set field value
  void setFieldValue(String fieldName, String value) {
    formController.setFieldValue(fieldName, value);
  }

  /// Get field value
  String getFieldValue(String fieldName) {
    return formController.getFieldValue(fieldName);
  }

  /// Get all form values
  Map<String, String> get formData => formController.values;

  /// Clear all form data
  void clearForm() {
    formController.clear();
  }

  /// Reset form to initial state
  void resetForm() {
    formController.reset();
  }

  /// Check if form has changes
  bool get hasFormChanges {
    return formData.values.any((value) => value.isNotEmpty);
  }

  /// Dispose the form controller
  /// 
  /// **CRITICAL:** This method MUST be called in ViewModel's `onDispose()` to prevent
  /// memory leaks. The FormController manages TextEditingController and FocusNode
  /// instances that will accumulate in memory if not properly disposed.
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// void onDispose() {
  ///   disposeFormController(); // Always call this first
  ///   super.onDispose();
  /// }
  /// ```
  void disposeFormController() {
    if (_isFormControllerDisposed) {
      return; // Already disposed, prevent double disposal
    }
    
    _formController?.dispose();
    _formController = null;
    _isFormControllerDisposed = true;
  }
}
