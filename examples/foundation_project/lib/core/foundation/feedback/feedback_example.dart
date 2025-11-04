// ignore_for_file: unused_element, unreachable_from_main

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/feedback_emitter_mixin.dart';
import 'package:foundation_project/core/foundation/feedback/feedback_event.dart';
import 'package:foundation_project/core/foundation/feedback/feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/feedback_listener_mixin.dart';
import 'package:foundation_project/core/foundation/mvvm/base_screen.dart';
import 'package:foundation_project/core/foundation/mvvm/view_model.dart';

/// ============================================================================
/// FEEDBACK SYSTEM USAGE EXAMPLES
/// ============================================================================
///
/// This file demonstrates all usage patterns for the reusable feedback system.
/// The feedback system allows ViewModels, Services, and any Dart class to
/// emit UI feedback without knowing about Flutter widgets or BuildContext.

// ============================================================================
// EXAMPLE 1: Basic Usage with BaseScreen (Automatic)
// ============================================================================

/// Example ViewModel with feedback
class ExampleViewModelState extends ViewModelState {
  @override
  final bool isLoading;
  @override
  final String? error;

  ExampleViewModelState({
    this.isLoading = false,
    this.error,
  });

  ExampleViewModelState copyWith({bool? isLoading, String? error}) {
    return ExampleViewModelState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ExampleViewModel extends ViewModel<ExampleViewModelState> {
  // FeedbackEmitterMixin already included via ViewModel base class

  @override
  ExampleViewModelState build() => ExampleViewModelState();

  @override
  ExampleViewModelState copyState({bool? isLoading, String? error}) {
    return state.copyWith(isLoading: isLoading, error: error);
  }

  /// Simple success/error pattern
  Future<void> saveData() async {
    state = copyState(isLoading: true);

    // Simulate async operation
    await Future.delayed(const Duration(seconds: 1));
    final success = true; // Simulate result

    state = copyState(isLoading: false);

    if (success) {
      emitSuccess('Data saved successfully!'); // Automatic snackbar!
    } else {
      emitError(
        'Failed to save data',
        retryAction: saveData, // One-tap retry button
      );
    }
  }

  /// Using performAsyncWithFeedback convenience method
  Future<void> syncData() async {
    await performAsync(
      () async {
        // Your async operation
        await Future.delayed(const Duration(seconds: 1));
        return true;
      },
      successMessage: 'Data synced successfully!',
      errorMessage: 'Failed to sync data',
    );
  }

  /// Confirmation dialog example
  void deleteItem(String itemId) {
    emitConfirmation(
      title: 'Delete Item',
      message: 'Are you sure you want to delete this item?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDangerous: true, // Red confirm button
      onConfirm: () async {
        // Perform deletion
        await Future.delayed(const Duration(milliseconds: 500));
        emitSuccess('Item deleted');
      },
    );
  }
}

final exampleViewModelProvider =
    NotifierProvider<ExampleViewModel, ExampleViewModelState>(
  () => ExampleViewModel(),
);

/// Example Screen using BaseScreen (Automatic feedback handling)
class ExampleScreen
    extends BaseScreen<ExampleViewModel, ExampleViewModelState> {
  const ExampleScreen({super.key});

  @override
  NotifierProvider<ExampleViewModel, ExampleViewModelState>
      getViewModelProvider() {
    return exampleViewModelProvider;
  }

  @override
  Color getBackgroundColor(theme) => theme.colors.background;

  @override
  Future<void> onRefresh(ExampleViewModel viewModel) => Future.value();

  @override
  Widget buildContent(
    BuildContext context,
    ExampleViewModel viewModel,
    ExampleViewModelState state,
    Color primary,
    WidgetRef ref,
  ) {
    // Feedback automatically handled by BaseScreen!
    // No manual setup needed - just build your UI

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: viewModel.saveData,
            child: const Text('Save Data (Shows Success)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: viewModel.syncData,
            child: const Text('Sync Data (Uses Convenience Method)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.deleteItem('123'),
            child: const Text('Delete Item (Shows Confirmation)'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Custom Widget with Manual Setup
// ============================================================================

/// Example custom widget that doesn't extend BaseScreen
class CustomFeedbackWidget extends ConsumerStatefulWidget {
  const CustomFeedbackWidget({super.key});

  @override
  ConsumerState<CustomFeedbackWidget> createState() =>
      _CustomFeedbackWidgetState();
}

class _CustomFeedbackWidgetState extends ConsumerState<CustomFeedbackWidget>
    with FeedbackListenerMixin<CustomFeedbackWidget> {
  @override
  void initState() {
    super.initState();
    // Set up listener after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener(); // One line!
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    // Connect to any feedback source
    final viewModel = ref.read(exampleViewModelProvider.notifier);
    return viewModel.feedbackStream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final viewModel = ref.read(exampleViewModelProvider.notifier);
            viewModel.saveData();
          },
          child: const Text('Trigger Feedback'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Service with Feedback (No UI Dependencies)
// ============================================================================

/// Example service that emits feedback
class DataSyncService with FeedbackEmitterMixin {
  Future<void> performSync() async {
    try {
      // Simulate network operation
      await Future.delayed(const Duration(seconds: 2));

      final success = true; // Simulate result

      if (success) {
        emitSuccess('Data synchronized successfully!');
      } else {
        emitError('Sync failed', retryAction: performSync);
      }
    } catch (e) {
      emitError(
        'Sync failed',
        technicalDetails: e.toString(),
        retryAction: performSync,
      );
    }
  }

  void dispose() {
    disposeFeedbackEmitter(); // Clean up
  }
}

/// Widget that listens to service feedback
class ServiceFeedbackExample extends ConsumerStatefulWidget {
  const ServiceFeedbackExample({super.key});

  @override
  ConsumerState<ServiceFeedbackExample> createState() =>
      _ServiceFeedbackExampleState();
}

class _ServiceFeedbackExampleState
    extends ConsumerState<ServiceFeedbackExample>
    with FeedbackListenerMixin<ServiceFeedbackExample> {
  final DataSyncService _syncService = DataSyncService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    return _syncService.feedbackStream; // Listen to service
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _syncService.performSync,
          child: const Text('Sync Data (Service Feedback)'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Custom Feedback Handler
// ============================================================================

/// Custom animated feedback handler
class AnimatedFeedbackHandler with FeedbackHandlerMixin implements FeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) => display == FeedbackDisplay.custom;

  @override
  void handle(BuildContext context, FeedbackEvent event, WidgetRef? ref) {
    if (!isValidContext(context)) return;

    // Custom animated overlay
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getColorForType(event.type),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_getIconForType(event.type), color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove after delay
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Color _getColorForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.error:
        return Colors.red;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.info:
        return Colors.blue;
    }
  }

  IconData _getIconForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle;
      case FeedbackType.error:
        return Icons.error_outline;
      case FeedbackType.warning:
        return Icons.warning_amber;
      case FeedbackType.info:
        return Icons.info_outline;
    }
  }
}

/// Screen using custom handler
class CustomHandlerExample extends ConsumerStatefulWidget {
  const CustomHandlerExample({super.key});

  @override
  ConsumerState<CustomHandlerExample> createState() =>
      _CustomHandlerExampleState();
}

class _CustomHandlerExampleState extends ConsumerState<CustomHandlerExample>
    with FeedbackListenerMixin<CustomHandlerExample> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    return ref.read(exampleViewModelProvider.notifier).feedbackStream;
  }

  @override
  FeedbackHandler getFeedbackHandler() {
    // Use custom handler + standard handlers
    return CompositeFeedbackHandler([
      AnimatedFeedbackHandler(), // Custom!
      SnackbarFeedbackHandler(),
      DialogFeedbackHandler(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final viewModel = ref.read(exampleViewModelProvider.notifier);
            viewModel.emitSuccess(
              'Custom animated feedback!',
              display: FeedbackDisplay.custom,
            );
          },
          child: const Text('Show Custom Feedback'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Analytics Integration
// ============================================================================

/// Widget with analytics tracking
class _AnalyticsTrackingState extends ConsumerState<CustomFeedbackWidget>
    with FeedbackListenerMixin<CustomFeedbackWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    return ref.read(exampleViewModelProvider.notifier).feedbackStream;
  }

  @override
  void onFeedbackHandled(FeedbackEvent event) {
    // Track feedback to analytics
    debugPrint('📊 Analytics: Feedback shown');
    debugPrint('   Type: ${event.type.name}');
    debugPrint('   Message: ${event.message}');
    debugPrint('   Timestamp: ${event.timestamp}');
    debugPrint('   ID: ${event.id}');

    // Send to analytics service
    // Analytics.track('feedback_shown', {
    //   'type': event.type.name,
    //   'message': event.message,
    //   'timestamp': event.timestamp.toIso8601String(),
    //   ...event.metadata,
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

