import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Emitter/Listener Pattern Example
///
/// This screen demonstrates the emitter/listener pattern:
/// - Services or ViewModels emit feedback using FlyFeedbackEmitterMixin
/// - Widgets listen to feedback using FlyFeedbackListenerMixin
/// - Decoupled architecture: business logic doesn't need BuildContext
///
/// **Key Concepts:**
/// - Separation of concerns: business logic doesn't know about UI
/// - Stream-based communication
/// - Automatic listener setup and disposal
class EmitterListenerScreen extends StatefulWidget {
  const EmitterListenerScreen({super.key});

  @override
  State<EmitterListenerScreen> createState() => _EmitterListenerScreenState();
}

class _EmitterListenerScreenState extends State<EmitterListenerScreen>
    with FlyFeedbackListenerMixin<EmitterListenerScreen> {
  late final ExampleService _service;

  @override
  void initState() {
    super.initState();
    _service = ExampleService();
    // Setup listener after first frame
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
      appBar: AppBar(
        title: const Text('4. Emitter/Listener Pattern'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Decoupled Feedback',
              description:
                  'Emit feedback from services or view models without BuildContext. Widgets listen and display automatically.',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _service.performSuccessfulOperation(),
              icon: const Icon(Icons.check),
              label: const Text('Perform Successful Operation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _service.performFailedOperation(),
              icon: const Icon(Icons.error),
              label: const Text('Perform Failed Operation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _service.performOperationWithConfirmation(),
              icon: const Icon(Icons.help),
              label: const Text('Operation Requiring Confirmation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _service.performMultipleOperations(),
              icon: const Icon(Icons.queue),
              label: const Text('Multiple Operations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'Service with emitter mixin:',
              code: '''
class ExampleService with FlyFeedbackEmitterMixin {
  Future<void> performOperation() async {
    try {
      // Do work...
      emitSuccess('Operation completed!');
    } catch (e) {
      emitError('Operation failed');
    }
  }

  void dispose() {
    disposeFeedbackEmitter();
  }
}
''',
            ),
            const SizedBox(height: 16),
            const _CodeExample(
              title: 'Widget with listener mixin:',
              code: '''
class _MyScreenState extends State<MyScreen>
    with FlyFeedbackListenerMixin<MyScreen> {
  
  final service = ExampleService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupFeedbackListener();
    });
  }

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    return service.feedbackStream;
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}
''',
            ),
          ],
        ),
      ),
    );
  }
}

/// Example service that emits feedback
///
/// This service demonstrates how to use FlyFeedbackEmitterMixin
/// to emit feedback without needing BuildContext.
class ExampleService with FlyFeedbackEmitterMixin {
  /// Perform a successful operation
  Future<void> performSuccessfulOperation() async {
    // Simulate async work
    await Future.delayed(const Duration(milliseconds: 500));
    emitSuccess(
      'Operation completed successfully!',
      display: FeedbackDisplay.snackBar,
    );
  }

  /// Perform a failed operation
  Future<void> performFailedOperation() async {
    // Simulate async work
    await Future.delayed(const Duration(milliseconds: 500));
    emitError(
      'Operation failed. Please try again.',
      retryAction: () {
        emitSuccess('Retry successful!');
      },
      retryLabel: 'Retry',
    );
  }

  /// Perform an operation requiring confirmation
  void performOperationWithConfirmation() {
    emitConfirmation(
      title: 'Confirm Operation',
      message: 'Are you sure you want to proceed with this operation?',
      confirmLabel: 'Proceed',
      cancelLabel: 'Cancel',
      onConfirm: () {
        emitSuccess('Operation confirmed and executed!');
      },
      onCancel: () {
        emitInfo('Operation cancelled');
      },
    );
  }

  /// Perform multiple operations
  Future<void> performMultipleOperations() async {
    emitInfo('Starting multiple operations...');
    await Future.delayed(const Duration(milliseconds: 300));

    emitWarning('Operation 1 completed with warnings');
    await Future.delayed(const Duration(milliseconds: 300));

    emitSuccess('Operation 2 completed successfully');
    await Future.delayed(const Duration(milliseconds: 300));

    emitSuccess('All operations completed!');
  }

  /// Dispose the service
  void dispose() {
    disposeFeedbackEmitter();
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Code example widget
class _CodeExample extends StatelessWidget {
  const _CodeExample({
    required this.title,
    required this.code,
  });

  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            code.trim(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

