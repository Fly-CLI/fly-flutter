import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:foundation_project/core/foundation/mvvm/fly_view_model.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter_extensions.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter_mixin.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_providers.dart';

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

  /// Get custom feedback handler (optional override)
  /// Override to provide custom feedback display logic
  FlyFeedbackHandler? getFeedbackHandler() {
    return null; // Use default handler provided by the screen state
  }

  /// Get the screen name for lifecycle events
  /// Override this to provide a custom screen name
  /// Defaults to the runtime type name
  String get screenName => runtimeType.toString();

  /// Provide haptic configuration for feedback presentation (optional).
  HapticConfig? getHapticConfig() => null;

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
    with LifecycleEmitterMixin {
  bool _hasInitialized = false;
  StreamSubscription<FeedbackLifecycleEvent>? _feedbackSubscription;
  DefaultFeedbackService? _feedbackService;
  String? _feedbackScope;

  @override
  void initState() {
    super.initState();
    // Schedule lifecycle callbacks for after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Set up automatic feedback listener if enabled
        if (widget.enableFeedback) {
          _restartFeedbackSubscription();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call onAppear every time the screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.enableFeedback) {
          _restartFeedbackSubscription();
        }
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
  void didUpdateWidget(covariant FlyScreen<V, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _feedbackService = null;
    if (oldWidget.enableFeedback != widget.enableFeedback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _restartFeedbackSubscription();
        }
      });
    }
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
    _cancelFeedbackSubscription();
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

  DefaultFeedbackService _resolveFeedbackService() {
    return _feedbackService ??= DefaultFeedbackService(
      handler: widget.getFeedbackHandler() ??
          CompositeFeedbackHandler(FeedbackDisplayFactory.allDefaultHandlers),
      hapticConfig: widget.getHapticConfig() ?? HapticConfig.disabled(),
    );
  }

  void _restartFeedbackSubscription() {
    if (!widget.enableFeedback) {
      _cancelFeedbackSubscription();
      return;
    }

    _cancelFeedbackSubscription();
    _feedbackSubscription = _createFeedbackSubscription();
  }

  StreamSubscription<FeedbackLifecycleEvent>? _createFeedbackSubscription() {
    if (!mounted) return null;

    Stream<FeedbackLifecycleEvent> stream;
    try {
      final viewModel = ref.read(widget.getViewModelProvider().notifier);
      _feedbackScope = viewModel.feedbackScope;

      final emitter = ref.read(lifecycleEmitterProvider);
      stream = emitter
          .getFeedbackStream()
          .where((event) => event.scope == _feedbackScope);
    } catch (error) {
      debugPrint('⚠️ Unable to subscribe to feedback events: $error');
      return null;
    }

    return stream.listen(
      (event) => _handleFeedbackEvent(event.payload),
      onError: _handleFeedbackStreamError,
      onDone: () => _feedbackSubscription = null,
      cancelOnError: false,
    );
  }

  void _cancelFeedbackSubscription() {
    _feedbackSubscription?.cancel();
    _feedbackSubscription = null;
  }

  void _handleFeedbackEvent(FeedbackEvent event) {
    if (!mounted) {
      debugPrint('⚠️ Cannot handle feedback - widget not mounted');
      return;
    }

    try {
      final service = _resolveFeedbackService();
      service.show(context, event);
    } catch (error, stackTrace) {
      debugPrint('❌ Feedback handling error: $error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'FlyScreen',
        ),
      );
    }
  }

  void _handleFeedbackStreamError(Object error, StackTrace stackTrace) {
    debugPrint('❌ Feedback stream error: $error');
  }
}
