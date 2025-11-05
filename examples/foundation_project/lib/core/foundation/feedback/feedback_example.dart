// ignore_for_file: unused_element, unreachable_from_main

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/core/foundation/feedback/mixins/fly_feedback_emitter_mixin.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/fly_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/composite_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/snackbar_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/dialog_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/handlers/bottom_sheet_feedback_handler.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/foundation/feedback/mixins/fly_feedback_listener_mixin.dart';
import 'package:foundation_project/core/foundation/mvvm/fly_screen.dart';
import 'package:foundation_project/core/foundation/mvvm/fly_view_model.dart';
import 'package:foundation_project/core/foundation/feedback/service/feedback_service.dart';
import 'package:foundation_project/core/foundation/feedback/service/feedback_service_provider.dart';

/// ============================================================================
/// FEEDBACK SYSTEM USAGE EXAMPLES
/// ============================================================================
///
/// This file demonstrates all usage patterns for the reusable feedback system.
/// The feedback system allows ViewModels, Services, and any Dart class to
/// emit UI feedback without knowing about Flutter widgets or BuildContext.

// ============================================================================
// EXAMPLE 1: Basic Usage with FlyScreen (Automatic)
// ============================================================================

/// Example ViewModel with feedback
class ExampleViewModelState extends FlyViewModelState {
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

class ExampleViewModel extends FlyViewModel<ExampleViewModelState> {
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
    const success = true; // Simulate result

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

/// Example Screen using FlyScreen (Automatic feedback handling)
class ExampleScreen
    extends FlyScreen<ExampleViewModel, ExampleViewModelState> {
  const ExampleScreen({super.key});

  @override
  NotifierProvider<ExampleViewModel, ExampleViewModelState>
      getViewModelProvider() {
    return exampleViewModelProvider;
  }

  @override
  Future<void> onRefresh(ExampleViewModel viewModel) => Future.value();

  @override
  Widget buildContent(
    BuildContext context,
    ExampleViewModel viewModel,
    ExampleViewModelState state,
    WidgetRef ref,
  ) {
    // Feedback automatically handled by FlyScreen!
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

/// Example wrapper showing how to use ExampleScreen with Scaffold
/// Users must wrap FlyScreen in their own Scaffold or layout widget
class ExampleScreenWrapper extends ConsumerWidget {
  const ExampleScreenWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const exampleScreen = ExampleScreen();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Example'),
      ),
      body: exampleScreen,
    );
  }
}

// ============================================================================
// EXAMPLE 2: Custom Widget with Manual Setup
// ============================================================================

/// Example custom widget that doesn't extend FlyScreen
class CustomFeedbackWidget extends ConsumerStatefulWidget {
  const CustomFeedbackWidget({super.key});

  @override
  ConsumerState<CustomFeedbackWidget> createState() =>
      _CustomFeedbackWidgetState();
}

class _CustomFeedbackWidgetState extends ConsumerState<CustomFeedbackWidget>
    with FlyFeedbackListenerMixin<CustomFeedbackWidget> {
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
class DataSyncService with FlyFeedbackEmitterMixin {
  Future<void> performSync() async {
    try {
      // Simulate network operation
      await Future.delayed(const Duration(seconds: 2));

      const success = true; // Simulate result

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
    with FlyFeedbackListenerMixin<ServiceFeedbackExample> {
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
class AnimatedFeedbackHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
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
    with FlyFeedbackListenerMixin<CustomHandlerExample> {
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
  FlyFeedbackHandler getFeedbackHandler() {
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
// EXAMPLE 5: Direct Service Usage (With BuildContext)
// ============================================================================

/// Widget using FeedbackService directly (without mixin)
/// Use this pattern when you have BuildContext and want direct control
class DirectServiceExample extends ConsumerWidget {
  const DirectServiceExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackService = ref.read(feedbackServiceProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                feedbackService.showSuccess(context, 'Operation successful!');
              },
              child: const Text('Show Success (Service)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                feedbackService.showError(
                  context,
                  'Operation failed',
                  retryAction: () {
                    // Retry logic
                    feedbackService.showInfo(context, 'Retrying...');
                  },
                  retryLabel: 'Retry',
                );
              },
              child: const Text('Show Error with Retry (Service)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                feedbackService.showConfirmation(
                  context: context,
                  title: 'Confirm Action',
                  message: 'Are you sure you want to proceed?',
                  confirmLabel: 'Confirm',
                  cancelLabel: 'Cancel',
                  isDangerous: true,
                  onConfirm: () {
                    feedbackService.showSuccess(context, 'Action confirmed!');
                  },
                );
              },
              child: const Text('Show Confirmation (Service)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 6: Custom Feedback Type with Service
// ============================================================================

/// Custom feedback type extending FeedbackEvent
class CustomFeedback extends FeedbackEvent {
  final String? customField;

  CustomFeedback.success(String message, {this.customField})
      : super(
          message: message,
          type: FeedbackType.success,
        );

  // Note: For custom feedback types, use show() directly
  // Convenience methods may not work with custom types
}

/// Widget using custom feedback type
class CustomFeedbackTypeExample extends ConsumerWidget {
  const CustomFeedbackTypeExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For custom types, you would need a custom provider
    // This is a conceptual example
    // final customService = ref.read(customFeedbackServiceProvider);

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Example: Using default service with custom feedback
            final service = ref.read(feedbackServiceProvider);
            final customFeedback = CustomFeedback.success(
              'Custom feedback shown!',
              customField: 'custom value',
            );
            // Use show() method directly for custom types
            service.show(context, customFeedback, ref);
          },
          child: const Text('Show Custom Feedback Type'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 7: Analytics Integration
// ============================================================================

/// Widget with analytics tracking
class _AnalyticsTrackingState extends ConsumerState<CustomFeedbackWidget>
    with FlyFeedbackListenerMixin<CustomFeedbackWidget> {
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

