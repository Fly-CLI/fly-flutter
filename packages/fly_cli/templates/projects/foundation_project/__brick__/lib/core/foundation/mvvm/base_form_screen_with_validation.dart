import 'package:flutter/material.dart';
import 'package:flutter_form/flutter_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{project_name_snake}}/core/foundation/mvvm/base_screen.dart';
import 'package:{{project_name_snake}}/core/foundation/mvvm/view_model.dart';
import 'package:{{project_name_snake}}/shared/localization/localizations.dart';

/// Base form screen with integrated flutter_form validation
/// Provides common validation infrastructure, form submission logic, loading states, and consistent UI patterns
abstract class BaseFormScreenWithValidation<
  T,
  V extends ViewModel<S>,
  S extends ViewModelState
>
    extends BaseFormScreen<T, V, S> {
  const BaseFormScreenWithValidation({
    super.key,
    super.shouldRefresh,
    super.screenTitle,
    super.addIcon,
    super.addButtonText,
    super.showAppBar,
    super.showRefreshIndicator,
    super.item,
  });

  /// Abstract method for form setup - must be implemented by subclasses
  void setupFormValidation(FormController formController);

  /// Override validation methods to use FormController from ViewModel
  @override
  bool isFormValid(V viewModel) {
    // The ViewModel should have a formController property
    final formViewModel = viewModel as dynamic;
    return formViewModel.formController?.isValid ?? false;
  }

  /// Get validation errors from ViewModel
  Map<String, String?> getValidationErrors(V viewModel) {
    final formViewModel = viewModel as dynamic;
    return formViewModel.formController?.errors ?? <String, String?>{};
  }

  /// Validate the entire form using ViewModel
  ValidationResult validateForm(V viewModel) {
    final formViewModel = viewModel as dynamic;
    return formViewModel.formController?.validateAll() ??
        const ValidationResult.success();
  }

  /// Get form data from ViewModel
  Map<String, String> getFormData(V viewModel) {
    final formViewModel = viewModel as dynamic;
    return formViewModel.formController?.values ?? <String, String>{};
  }

  /// Check if form is loading
  @override
  bool isFormLoading(S viewModelState) {
    return viewModelState.isLoading;
  }

  /// Get submit button text
  @override
  String getSubmitButtonText(BuildContext context) {
    return item != null ? localizations.update : localizations.add;
  }

  /// Get cancel button text
  @override
  String getCancelButtonText(BuildContext context) {
    return localizations.cancel;
  }

  /// Handle form submission
  @override
  Future<void> onSubmit(V viewModel, T item) async {
    final formViewModel = viewModel as dynamic;
    final success = await formViewModel.submitForm();
    if (!success) return;
    _onSaveSuccess();
  }

  /// Handle form cancellation
  @override
  void onCancel(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Called when form is successfully saved
  void _onSaveSuccess() {
    // Default implementation - can be overridden by subclasses
    // This typically shows a success message and navigates back
  }

  /// Build form content - must be implemented by subclasses
  @override
  Widget buildFormContent(
    BuildContext context,
    V viewModel,
    S viewModelState,
    Color primary,
    WidgetRef ref,
  );
}
