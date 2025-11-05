import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/mixins/fly_feedback_listener_mixin.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/foundation/mvvm/fly_view_model.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter_mixin.dart';
import 'package:foundation_project/shared/ui/error_widget.dart';

/// Abstract base screen class for handling common UI logic
/// Provides standard patterns for loading, error, and content management
/// Returns content only - users must wrap in their own Scaffold or layout widget
///
/// For navigation, use NavigationService via Riverpod:
/// ```dart
/// // String-based service
/// ref.read(navigationServiceProvider).navigateTo('/route');
///
/// // Or Feature enum-based service
/// AppNavigation.instance.navigateTo(Feature.home);
/// ```
abstract class FlyScreen<V extends FlyViewModel<S>, S extends FlyViewModelState>
    extends ConsumerStatefulWidget {
  final bool shouldRefresh;
  final String screenTitle;
  final bool showRefreshIndicator;
  final bool enableFeedback; // Opt-in automatic feedback handling

  const FlyScreen({
    super.key,
    this.shouldRefresh = false,
    this.screenTitle = '',
    this.showRefreshIndicator = false,
    this.enableFeedback = true, // Enabled by default
  });

  @override
  ConsumerState<FlyScreen<V, S>> createState() => _FlyScreenState<V, S>();

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

  /// Handle refresh action
  Future<void> onRefresh(V viewModel);

  /// Build the main content of the screen
  Widget buildContent(
    BuildContext context,
    V viewModel,
    S viewModelState,
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

  /// Handle add button press (optional override)
  void onAddPressed(BuildContext context, WidgetRef ref, V viewModel) {
    // Default implementation - can be overridden
  }

  /// Get custom feedback handler (optional override)
  /// Override to provide custom feedback display logic
  FlyFeedbackHandler? getFeedbackHandler() {
    return null; // Use default handler from mixin
  }

  /// Get the screen name for lifecycle events
  /// Override this to provide a custom screen name
  /// Defaults to the runtime type name
  String get screenName => runtimeType.toString();

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Build loading state widget
  Widget buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Show error toast/snackbar instead of error widget
  /// 
  /// [retryLabel] - Optional label for retry action. If not provided, the action button will be omitted.
  void showErrorToast(
    BuildContext context,
      WidgetRef ref,
    String message,
    VoidCallback? onRetry, {
    V? viewModel,
    String? retryLabel,
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
        action: onRetry != null && retryLabel != null
            ? SnackBarAction(
                label: retryLabel,
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Build error state widget (kept for backward compatibility)
  /// 
  /// [retryText] - Optional label for retry button. If not provided and [onRetry] is set,
  /// an icon-only button will be shown.
  Widget buildErrorState(String message, VoidCallback? onRetry, {String? retryText}) {
    return AppErrorWidget(message: message, onRetry: onRetry, retryText: retryText);
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
  bool isLoading(FlyViewModelState state) => state.isLoading;

  /// Check if view model has error
  bool hasError(FlyViewModelState state) => state.hasError;

  /// Get error message from view model state
  String? getErrorMessage(FlyViewModelState state) => state.errorMessage;
}

/// State class for FlyScreen with lifecycle management
class _FlyScreenState<V extends FlyViewModel<S>, S extends FlyViewModelState>
    extends ConsumerState<FlyScreen<V, S>>
    with FlyFeedbackListenerMixin<FlyScreen<V, S>>, LifecycleEmitterMixin {
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
          // Emit screen shown event
          emitScreenShown(screenName: widget.screenName);
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

    // Use default implementation from FeedbackListenerMixin
    // which gets stream from lifecycle emitter
    return super.getFeedbackStream(context);
  }

  @override
  FlyFeedbackHandler getFeedbackHandler() {
    return widget.getFeedbackHandler() ?? super.getFeedbackHandler();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call onAppear every time the screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Emit screen shown event
        emitScreenShown(screenName: widget.screenName);
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
    // Emit screen hidden event
    emitScreenHidden(screenName: widget.screenName);
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
    // Dispose lifecycle emitter
    disposeLifecycleEmitter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      ref,
    );

    // Wrap with RefreshIndicator if needed
    if (widget.showRefreshIndicator) {
      content = RefreshIndicator(
        onRefresh: () => widget.onRefresh(viewModel),
        child: content,
      );
    }

    return content;
  }
}
