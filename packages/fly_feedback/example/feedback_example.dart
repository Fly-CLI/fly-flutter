// ignore_for_file: unused_element
// This file demonstrates usage patterns for the fly_feedback package

import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// ============================================================================
/// FEEDBACK SYSTEM USAGE EXAMPLES
/// ============================================================================
///
/// This file demonstrates all usage patterns for the reusable feedback system.
/// The feedback system allows ViewModels, Services, and any Dart class to
/// emit UI feedback without knowing about Flutter widgets or BuildContext.

// ============================================================================
// EXAMPLE 1: Service with Feedback Emission
// ============================================================================

/// Example service with feedback emission
class ExampleService with FlyFeedbackEmitterMixin {
  Future<void> saveData() async {
    // Simulate async operation
    await Future<void>.delayed(const Duration(seconds: 1));
    emitSuccess('Data saved successfully!');
  }

  void dispose() {
    disposeFeedbackEmitter();
  }
}

// ============================================================================
// EXAMPLE 2: Custom Widget with Manual Setup
// ============================================================================

/// Example custom widget that listens to feedback stream
class CustomFeedbackWidget extends StatefulWidget {
  const CustomFeedbackWidget({super.key});

  @override
  State<CustomFeedbackWidget> createState() => _CustomFeedbackWidgetState();
}

class _CustomFeedbackWidgetState extends State<CustomFeedbackWidget>
    with FlyFeedbackListenerMixin<CustomFeedbackWidget> {
  final ExampleService _service = ExampleService();

  @override
  void initState() {
    super.initState();
    // Set up listener after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    // Connect to service feedback stream
    return _service.feedbackStream;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _service.saveData();
          },
          child: const Text('Trigger Feedback'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Direct Service Usage (With BuildContext)
// ============================================================================

/// Example widget using FeedbackService directly
class DirectServiceExample extends StatelessWidget {
  const DirectServiceExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Create service instance directly (in real apps, use dependency injection)
    final feedbackService = DefaultFeedbackService<FeedbackEvent>(
      handler: CompositeFeedbackHandler([
        SnackbarFeedbackHandler(),
        DialogFeedbackHandler(),
        BottomSheetFeedbackHandler(),
        ToastFeedbackHandler(),
        BannerFeedbackHandler(),
      ]),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Direct Service Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                feedbackService.showSuccess(
                  context,
                  'Operation successful!',
                );
              },
              child: const Text('Show Success'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                feedbackService.showError(
                  context,
                  'Operation failed',
                  retryAction: () {
                    feedbackService.showSuccess(context, 'Retry successful!');
                  },
                  retryLabel: 'Retry',
                );
              },
              child: const Text('Show Error with Retry'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                feedbackService.showConfirmation(
                  context: context,
                  title: 'Delete Item',
                  message: 'Are you sure you want to delete this item?',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  isDangerous: true,
                  onConfirm: () {
                    feedbackService.showSuccess(
                      context,
                      'Item deleted',
                    );
                  },
                );
              },
              child: const Text('Show Confirmation'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Custom Feedback Handler
// ============================================================================

/// Custom handler example
class CustomFeedbackHandler implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) {
    return display == FeedbackDisplay.custom;
  }

  @override
  void handle(
    BuildContext context,
    FeedbackEvent event,
  ) {
    // Custom implementation
    debugPrint('Custom handler: ${event.message}');
  }
}

// ============================================================================
// EXAMPLE 5: Custom Widget with Custom Handler
// ============================================================================

class CustomHandlerWidget extends StatefulWidget {
  const CustomHandlerWidget({super.key});

  @override
  State<CustomHandlerWidget> createState() => _CustomHandlerWidgetState();
}

class _CustomHandlerWidgetState extends State<CustomHandlerWidget>
    with FlyFeedbackListenerMixin<CustomHandlerWidget> {
  final ExampleService _service = ExampleService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    return _service.feedbackStream;
  }

  @override
  FlyFeedbackHandler getFeedbackHandler() {
    return CompositeFeedbackHandler([
      CustomFeedbackHandler(),
      SnackbarFeedbackHandler(),
      DialogFeedbackHandler(),
    ]);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Handler Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _service.saveData();
          },
          child: const Text('Trigger Feedback'),
        ),
      ),
    );
  }
}
