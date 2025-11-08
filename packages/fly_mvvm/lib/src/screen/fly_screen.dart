import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_events/fly_events.dart';
import '../view_model/fly_view_model.dart';
import '../view_model/view_model_state.dart';

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
///
/// ### Automatic feedback
/// Override [configureFeedback] to opt into advanced feedback handling:
/// - Merge multiple scopes (e.g. nested ViewModels or child flows)
/// - Filter or transform feedback events before display
/// - Inject custom services, handlers, or haptic behavior
/// The default configuration listens to the
/// ViewModel scope with the composite handler.
abstract class FlyScreen<
V extends FlyViewModel<S>,
S extends FlyViewModelState<S>
>
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

  /// Configure automatic feedback handling.
  ///
  /// Override this to customize the feedback binding experience for a screen.
  /// Use [FeedbackBindingConfig] to control scopes, filtering, and service
  /// composition.
  ///
  /// Defaults to enabling feedback with a composite handler and disabled
  /// haptic feedback.
  FeedbackBindingConfig configureFeedback(
    BuildContext context,
    V viewModel,
    WidgetRef ref,
  ) {
    return FeedbackBindingConfig(
      enabled: enableFeedback,
      handler: getFeedbackHandler(),
      hapticConfig: getHapticConfig(),
    );
  }

  /// Check if view model is loading
  bool isLoading(FlyViewModelState state) => state.isLoading;

  /// Check if view model has error
  bool hasError(FlyViewModelState state) => state.hasError;

  /// Get error message from view model state
  String? getErrorMessage(FlyViewModelState state) => state.error;
}

/// Factory signature for building a feedback service during binding.
typedef FeedbackServiceFactory = FeedbackService<FeedbackEvent> Function(
  BuildContext context,
  WidgetRef ref,
  Set<String> scopes,
);

/// Signature for transforming or filtering feedback payloads.
typedef FeedbackEventTransformer = FeedbackEvent? Function(
  BuildContext context,
  WidgetRef ref,
  FeedbackAppEvent lifecycleEvent,
);

/// Declarative configuration for the FlyScreen feedback binding.
class FeedbackBindingConfig {
  const FeedbackBindingConfig({
    this.enabled = true,
    this.additionalScopes = const <String>{},
    this.handler,
    this.hapticConfig,
    this.service,
    this.serviceFactory,
    this.eventFilter,
    this.eventTransformer,
    this.onEvent,
  })  : assert(
          service == null || serviceFactory == null,
          'Provide either a service instance or a serviceFactory, not both.',
        );

  /// Disables feedback handling.
  const FeedbackBindingConfig.disabled()
      : enabled = false,
        additionalScopes = const <String>{},
        handler = null,
        hapticConfig = null,
        service = null,
        serviceFactory = null,
        eventFilter = null,
        eventTransformer = null,
        onEvent = null;

  /// Whether feedback should be bound.
  final bool enabled;

  /// Additional feedback scopes to bind alongside the ViewModel scope.
  final Set<String> additionalScopes;

  /// Override handler used when creating the default service.
  final FlyFeedbackHandler? handler;

  /// Override haptic configuration used when creating the default service.
  final HapticConfig? hapticConfig;

  /// Provide a custom service instance. Mutually exclusive with [serviceFactory].
  final FeedbackService<FeedbackEvent>? service;

  /// Build a feedback service dynamically during binding.
  final FeedbackServiceFactory? serviceFactory;

  /// Filter lifecycle events prior to handling.
  final bool Function(FeedbackAppEvent event)? eventFilter;

  /// Transform a lifecycle event into a feedback payload.
  ///
  /// Return `null` to swallow the event.
  final FeedbackEventTransformer? eventTransformer;

  /// Callback invoked before the payload is displayed.
  final void Function(
    BuildContext context,
    FeedbackAppEvent event,
  )? onEvent;

  /// Returns a copy with selective overrides.
  FeedbackBindingConfig copyWith({
    bool? enabled,
    Set<String>? additionalScopes,
    FlyFeedbackHandler? handler,
    HapticConfig? hapticConfig,
    FeedbackService<FeedbackEvent>? service,
    FeedbackServiceFactory? serviceFactory,
    bool Function(FeedbackAppEvent event)? eventFilter,
    FeedbackEventTransformer? eventTransformer,
    void Function(BuildContext context, FeedbackAppEvent event)? onEvent,
  }) {
    return FeedbackBindingConfig(
      enabled: enabled ?? this.enabled,
      additionalScopes: additionalScopes != null
          ? Set<String>.unmodifiable(additionalScopes)
          : this.additionalScopes,
      handler: handler ?? this.handler,
      hapticConfig: hapticConfig ?? this.hapticConfig,
      service: service ?? this.service,
      serviceFactory: serviceFactory ?? this.serviceFactory,
      eventFilter: eventFilter ?? this.eventFilter,
      eventTransformer: eventTransformer ?? this.eventTransformer,
      onEvent: onEvent ?? this.onEvent,
    );
  }
}

/// State class for FlyScreen with lifecycle management
class _FlyScreenState<
    V extends FlyViewModel<S>,
    S extends FlyViewModelState<S>>
    extends ConsumerState<FlyScreen<V, S>> {
  bool _hasInitialized = false;
  late final _FeedbackBindingController<V, S> _feedbackBindingController;
  late final AppEventEmitter _emitter;

  @override
  void initState() {
    super.initState();
    _emitter = ref.read(eventEmitterProvider);
    _feedbackBindingController = _FeedbackBindingController<V, S>(
      ref: ref,
      emitter: _emitter,
    );
    // Schedule lifecycle callbacks for after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleInitialize();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call onAppear every time the screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleAppear();
      }
    });
  }

  @override
  void didUpdateWidget(covariant FlyScreen<V, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bindFeedback();
      }
    });
  }

  @override
  void dispose() {
    // Emit screen hidden event
    _emitter.emit(
      ScreenHiddenEvent(screenName: widget.screenName),
    );
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
    _feedbackBindingController.dispose();
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

  void _handleInitialize() {
    if (!mounted || _hasInitialized) {
      return;
    }

    final viewModel = ref.read(widget.getViewModelProvider().notifier);
    widget.onInitialize(ref);
    viewModel.onInitialize();
    _hasInitialized = true;
    _bindFeedback(viewModel: viewModel);
  }

  void _handleAppear() {
    if (!mounted) {
      return;
    }

    final viewModel = ref.read(widget.getViewModelProvider().notifier);
    _emitter.emit(
      ScreenShownEvent(screenName: widget.screenName),
    );
    widget.onAppear(ref);
    viewModel.onAppear();
    _bindFeedback(viewModel: viewModel);
  }

  void _bindFeedback({V? viewModel}) {
    if (!mounted) {
      return;
    }

    final provider = widget.getViewModelProvider();
    final resolvedViewModel = viewModel ?? ref.read(provider.notifier);

    _feedbackBindingController.bind(
      context: context,
      screen: widget,
      viewModel: resolvedViewModel!,
    );
  }
}

/// Handles the lifecycle of feedback stream bindings for a screen.
///
/// Encapsulates configuration resolution, service construction, and stream
/// subscription management away from `_FlyScreenState`.
class _FeedbackBindingController<
    V extends FlyViewModel<S>, S extends FlyViewModelState<S>> {
  _FeedbackBindingController({
    required this.ref,
    required AppEventEmitter emitter,
  }) : _coordinator = _FeedbackCoordinator(emitter: emitter);

  final WidgetRef ref;
  final _FeedbackCoordinator _coordinator;

  FeedbackBindingConfig? _config;
  FeedbackService<FeedbackEvent>? _service;
  FlyScreen<V, S>? _screen;
  BuildContext? _context;
  Set<String> _scopes = const <String>{};
  bool _isDisposed = false;

  void bind({
    required BuildContext context,
    required FlyScreen<V, S> screen,
    required V viewModel,
  }) {
    if (_isDisposed) {
      throw StateError('Feedback binding controller has been disposed');
    }

    _context = context;
    _screen = screen;

    final config = screen.configureFeedback(context, viewModel, ref);
    _config = config;

    if (!config.enabled) {
      _coordinator.unbind();
      _service = null;
      _scopes = const <String>{};
      return;
    }

    final scopes = <String>{
      viewModel.feedbackScope,
      ...config.additionalScopes,
    };
    _scopes = Set<String>.unmodifiable(scopes);

    _service = _resolveService(
      screen: screen,
      config: config,
      context: context,
      scopes: _scopes,
    );

    _coordinator.bind(
      scopes: _scopes,
      onEvent: _handleEvent,
      onError: _handleError,
      filter: config.eventFilter,
    );
  }

  FeedbackService<FeedbackEvent> _resolveService({
    required FlyScreen<V, S> screen,
    required FeedbackBindingConfig config,
    required BuildContext context,
    required Set<String> scopes,
  }) {
    if (config.service != null) {
      return config.service!;
    }

    if (config.serviceFactory != null) {
      return config.serviceFactory!(context, ref, scopes);
    }

    final handler = config.handler ??
        screen.getFeedbackHandler() ??
        CompositeFeedbackHandler(FeedbackDisplayFactory.allDefaultHandlers);
    final haptics =
        config.hapticConfig ?? screen.getHapticConfig() ?? HapticConfig.disabled();

    return DefaultFeedbackService(
      handler: handler,
      hapticConfig: haptics,
    );
  }

  void _handleEvent(FeedbackAppEvent lifecycleEvent) {
    final config = _config;
    final context = _context;
    final screen = _screen;

    if (config == null || !config.enabled) {
      return;
    }

    if (context == null || !context.mounted || screen == null) {
      debugPrint('⚠️ Cannot handle feedback - context not available');
      return;
    }

    config.onEvent?.call(context, lifecycleEvent);

    FeedbackEvent? payload = lifecycleEvent.payload;
    if (config.eventTransformer != null) {
      payload = config.eventTransformer!(context, ref, lifecycleEvent);
    }

    if (payload == null) {
      return;
    }

    try {
      final service = _service ??
          _resolveService(
            screen: screen,
            config: config,
            context: context,
            scopes: _scopes,
          );
      _service = service;
      service.show(context, payload);
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

  void _handleError(Object error, StackTrace stackTrace) {
    debugPrint('❌ Feedback stream error: $error');
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _coordinator.dispose();
    _config = null;
    _service = null;
    _screen = null;
    _context = null;
    _scopes = const <String>{};
  }
}

/// Lightweight wrapper around the app lifecycle emitter that manages the
/// active feedback subscription for a screen.
class _FeedbackCoordinator {
  _FeedbackCoordinator({required AppEventEmitter emitter}) : _emitter = emitter;

  final AppEventEmitter _emitter;
  StreamSubscription<FeedbackAppEvent>? _subscription;
  bool _isDisposed = false;

  void bind({
    required Set<String> scopes,
    required void Function(FeedbackAppEvent event) onEvent,
    required void Function(Object error, StackTrace stackTrace) onError,
    bool Function(FeedbackAppEvent event)? filter,
  }) {
    if (_isDisposed) {
      throw StateError('Feedback coordinator has been disposed');
    }

    _subscription?.cancel();
    if (scopes.isEmpty) {
      return;
    }

    try {
      final scopeSet = scopes.toSet();
      final stream = _emitter.getStreamFor<FeedbackAppEvent>().where((event) {
        if (!scopeSet.contains(event.scope)) {
          return false;
        }
        return filter?.call(event) ?? true;
      });

      _subscription = stream.listen(
        onEvent,
        onError: onError,
        onDone: () => _subscription = null,
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  void unbind() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    unbind();
  }
}

