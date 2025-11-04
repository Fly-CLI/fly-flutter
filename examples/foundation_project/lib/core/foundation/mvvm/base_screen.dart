import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/feedback_event.dart';
import 'package:foundation_project/core/foundation/feedback/feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/feedback_listener_mixin.dart';
import 'package:foundation_project/core/foundation/mvvm/view_model.dart';
import 'package:foundation_project/l10n/app_localizations.dart';
import 'package:foundation_project/shared/navigation/navigation_mixin.dart';
import 'package:foundation_project/shared/themes/themes.dart' show getAppTheme, AppThemeData;
import 'package:foundation_project/shared/ui/app_scaffold.dart';
import 'package:foundation_project/shared/ui/error_widget.dart';
import 'package:foundation_project/shared/widgets/app_bar.dart';

/// Abstract base screen class for handling common UI logic
/// Provides standard patterns for backup with loading, error, and basic layout
abstract class BaseScreen<V extends ViewModel<S>, S extends ViewModelState>
    extends ConsumerStatefulWidget
    with NavigationMixin {
  final bool shouldRefresh;
  final String screenTitle;
  final IconData? addIcon;
  final String? addButtonText;
  final bool showAppBar;
  final bool showRefreshIndicator;
  final bool enableFeedback; // Opt-in automatic feedback handling

  const BaseScreen({
    super.key,
    this.shouldRefresh = false,
    this.screenTitle = '',
    this.addIcon,
    this.addButtonText,
    this.showAppBar = true,
    this.showRefreshIndicator = false,
    this.enableFeedback = true, // Enabled by default
  });

  @override
  ConsumerState<BaseScreen<V, S>> createState() => _BaseScreenState<V, S>();

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  /// Get the ViewModel instance from the provider
  /// Use this helper method to access the view model in widget class methods
  V getViewModel(WidgetRef ref) {
    return ref.read(getViewModelProvider().notifier);
  }

  // =============================================================================
  // ABSTRACT METHODS - Must be implemented by subclasses
  // =============================================================================

  /// Get the ViewModel provider - should return a stable provider reference
  /// IMPORTANT: This method should return the SAME provider instance across rebuilds
  /// to avoid creating new providers on every build. The provider should be defined
  /// as a static final variable in the implementing class.
  NotifierProvider<V, S> getViewModelProvider();

  /// Get the background color for the screen
  Color getBackgroundColor(AppThemeData theme);

  /// Handle refresh action
  Future<void> onRefresh(V viewModel);

  /// Build the main content of the screen
  Widget buildContent(
    BuildContext context,
    V viewModel,
    S viewModelState,
      Color primary,
    WidgetRef ref,
  );

  // =============================================================================
  // LIFECYCLE METHODS - Optional overrides for screen lifecycle events
  // =============================================================================

  /// Called once when the screen is first initialized
  /// Override this to perform one-time setup operations at the screen level
  /// This is called before the ViewModel's onInitialize()
  void onInitialize(WidgetRef ref) {
    // Default implementation - can be overridden
  }

  /// Called every time the screen appears (including first time)
  /// Override this to perform actions when screen becomes visible
  /// This is called before the ViewModel's onAppear()
  void onAppear(WidgetRef ref) {
    // Default implementation - can be overridden
  }

  /// Called when the screen is popped or hidden
  /// Override this to cleanup resources at the screen level
  /// This is called before the ViewModel's onDisappear()
  void onDisappear() {
    // Default implementation - can be overridden
  }

  /// Called when the screen is being permanently disposed
  /// Override this to cleanup resources that need to be released
  /// This is called before the ViewModel's onDispose()
  void onDispose() {
    // Default implementation - can be overridden
  }

  // =============================================================================
  // OPTIONAL OVERRIDE METHODS
  // =============================================================================

  /// Build custom app bar (optional override)
  PreferredSizeWidget? buildAppBar(
    BuildContext context,
      Color primary,
    WidgetRef ref,
    V viewModel,
  ) {
    return null;
  }

  /// Handle add button press (optional override)
  void onAddPressed(BuildContext context, WidgetRef ref, V viewModel) {
    // Default implementation - can be overridden
  }

  /// Get custom feedback handler (optional override)
  /// Override to provide custom feedback display logic
  FeedbackHandler? getFeedbackHandler() {
    return null; // Use default handler from mixin
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Build loading state widget
  Widget buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Show error toast/snackbar instead of error widget
  void showErrorToast(
    BuildContext context,
      WidgetRef ref,
    String message,
    VoidCallback? onRetry, {
    V? viewModel,
  }) {
    final colors = Theme.of(context).colorScheme;

    // Clear the error from the ViewModel after displaying the toast
    viewModel?.clearError();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: colors.error,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: AppLocalizations.of(context).retry,
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Build error state widget (kept for backward compatibility)
  Widget buildErrorState(String message, VoidCallback? onRetry) {
    return AppErrorWidget(message: message, onRetry: onRetry);
  }

  /// Build empty state widget
  Widget buildEmptyStateWidget({
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionText, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ],
      ),
    );
  }

  /// Check if view model is loading
  bool isLoading(ViewModelState state) => state.isLoading;

  /// Check if view model has error
  bool hasError(ViewModelState state) => state.hasError;

  /// Get error message from view model state
  String? getErrorMessage(ViewModelState state) => state.errorMessage;
}

/// State class for BaseScreen with lifecycle management
class _BaseScreenState<V extends ViewModel<S>, S extends ViewModelState>
    extends ConsumerState<BaseScreen<V, S>>
    with FeedbackListenerMixin<BaseScreen<V, S>> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Schedule lifecycle callbacks for after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Set up automatic feedback listener if enabled
        if (widget.enableFeedback) {
          setupFeedbackListener();
        }

        if (!_hasInitialized) {
          // Call screen lifecycle first
          widget.onInitialize(ref);
          // Then call ViewModel lifecycle
          final viewModel = ref.read(widget.getViewModelProvider().notifier);
          viewModel.onInitialize();
          _hasInitialized = true;
        }
      }
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    if (!widget.enableFeedback) return null;

    final viewModel = ref.read(widget.getViewModelProvider().notifier);
    return viewModel.feedbackStream;
  }

  @override
  FeedbackHandler getFeedbackHandler() {
    return widget.getFeedbackHandler() ?? super.getFeedbackHandler();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call onAppear every time the screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Call screen lifecycle first
        widget.onAppear(ref);
        // Then call ViewModel lifecycle
        final viewModel = ref.read(widget.getViewModelProvider().notifier);
        viewModel.onAppear();
      }
    });
  }

  @override
  void dispose() {
    // Call screen lifecycle first
    widget.onDisappear();
    widget.onDispose();
    // Then call ViewModel lifecycle - only if still mounted and ref is available
    try {
      if (mounted) {
        final viewModel = ref.read(widget.getViewModelProvider().notifier);
        viewModel.onDisappear();
        viewModel.onDispose();
      }
    } catch (e) {
      // Silently handle cases where ref is no longer available
      // This can happen during widget disposal in certain scenarios
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = getAppTheme(context);
    final primary = themeData.colors.primary;
    final backgroundColor = widget.getBackgroundColor(themeData);

    // Get the ViewModel provider - this should return a stable provider reference
    final provider = widget.getViewModelProvider();

    // Watch the ViewModel state
    final viewModelState = ref.watch(provider);

    // Get the ViewModel instance
    final viewModel = ref.read(provider.notifier);

    Widget content = widget.buildContent(
      context,
      viewModel,
      viewModelState,
      primary,
      ref,
    );

    // Wrap with RefreshIndicator if needed
    if (widget.showRefreshIndicator) {
      content = RefreshIndicator(
        onRefresh: () => widget.onRefresh(viewModel),
        child: content,
      );
    }

    return AppScaffold(
      backgroundColor: backgroundColor,
      appBar: widget.showAppBar
          ? widget.buildAppBar(context, primary, ref, viewModel)
          : null,
      child: content,
    );
  }
}

/// Abstract base screen for form backup
abstract class BaseFormScreen<
  T,
  V extends ViewModel<S>,
  S extends ViewModelState
>
    extends BaseScreen<V, S> {
  final T? item;

  const BaseFormScreen({
    super.key,
    super.shouldRefresh,
    super.screenTitle,
    super.addIcon,
    super.addButtonText,
    super.showAppBar,
    super.showRefreshIndicator,
    this.item,
  });

  /// Build the form content
  Widget buildFormContent(
    BuildContext context,
    V viewModel,
    S viewModelState,
      Color primary,
    WidgetRef ref,
  );

  /// Handle form submission
  Future<void> onSubmit(V viewModel, T item);

  /// Handle form cancellation
  void onCancel(BuildContext context);

  /// Get submit button text
  String getSubmitButtonText(BuildContext context);

  /// Get cancel button text
  String getCancelButtonText(BuildContext context);

  /// Check if form is valid
  bool isFormValid(V viewModel);

  /// Check if form is loading
  bool isFormLoading(S state);

  /// Create a default item for new forms
  T createDefaultItem();

  @override
  Widget buildContent(
    BuildContext context,
    V viewModel,
    S viewModelState,
      Color primary,
    WidgetRef ref,
  ) {
    // Show loading state
    if (isFormLoading(viewModelState)) {
      return buildLoadingState();
    }

    // Show error toast instead of error widget
    if (hasError(viewModelState)) {
      // Show error toast
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorToast(
          context,
          ref,
          getErrorMessage(viewModelState) ??
              AppLocalizations.of(context).errorOccurred,
          () => onRefresh(viewModel),
          viewModel: viewModel,
        );
      });

      // Return form content while showing toast
      return buildFormContent(
        context,
        viewModel,
        viewModelState,
        primary,
        ref,
      );
    }

    // Show form content
    return buildFormContent(context, viewModel, viewModelState, primary, ref);
  }

  @override
  PreferredSizeWidget? buildAppBar(
    BuildContext context,
      Color primary,
    WidgetRef ref,
    V viewModel,
  ) {
    final isLoading = isFormLoading(ref.watch(getViewModelProvider()));
    final isValid = isFormValid(viewModel);

    return FormAppBar(
      title: screenTitle,
      onSubmit: (isLoading || !isValid)
          ? null
          : () async {
              // Create a default item if none provided
              final itemToSubmit = item ?? createDefaultItem();
              await onSubmit(viewModel, itemToSubmit);
              // Note: Navigation should be handled in the onSubmit method's success callback
              // This ensures navigation only happens on successful submission
            },
      cancelText: getCancelButtonText(context),
      submitText: getSubmitButtonText(context),
      isSubmitting: isLoading,
    );
  }
}
