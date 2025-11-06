import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Custom Handler Example
///
/// This screen demonstrates how to create custom feedback handlers:
/// - Implementing FlyFeedbackHandler interface
/// - Creating specialized display logic
/// - Using custom handlers with the listener mixin
///
/// **Key Concepts:**
/// - Custom handlers for specialized requirements
/// - Handler selection based on display type
/// - Composite handlers for multiple strategies
class CustomHandlerScreen extends StatefulWidget {
  /// Creates a [CustomHandlerScreen] widget.
  const CustomHandlerScreen({super.key});

  @override
  State<CustomHandlerScreen> createState() => _CustomHandlerScreenState();
}

class _CustomHandlerScreenState extends State<CustomHandlerScreen>
    with FlyFeedbackListenerMixin<CustomHandlerScreen> {
  late final ExampleService _service;

  @override
  void initState() {
    super.initState();
    _service = ExampleService();
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
    // Use custom handler along with default handlers
    return CompositeFeedbackHandler([
      CustomConsoleFeedbackHandler(),
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
      appBar: AppBar(
        title: const Text('5. Custom Handler'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Custom Feedback Handlers',
              description:
                  'Create custom handlers for specialized feedback display '
                  'requirements. This example shows a console logger handler '
                  'that also logs to the console.',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _service.performOperation(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Trigger Feedback with Custom Handler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            const _InfoBox(
              title: 'Check Console',
              message: 'Open your debug console to see custom handler logs. '
                  'The custom handler logs all feedback events to the console.',
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'Custom handler implementation:',
              code: r'''
class CustomConsoleFeedbackHandler implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) {
    // Support all display types
    return true;
  }

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    // Log to console
    debugPrint('📝 [Custom Handler] ${event.type}: ${event.message}');
    
    // Also use default handler behavior
    // (In real apps, you'd call another handler here)
  }
}
''',
            ),
            const SizedBox(height: 16),
            const _CodeExample(
              title: 'Using custom handler:',
              code: '''
@override
FlyFeedbackHandler getFeedbackHandler() {
  return CompositeFeedbackHandler([
    CustomConsoleFeedbackHandler(), // Custom handler
    SnackbarFeedbackHandler(),      // Default handlers
    DialogFeedbackHandler(),
  ]);
}
''',
            ),
          ],
        ),
      ),
    );
  }
}

/// Example service for custom handler demo
class ExampleService with FlyFeedbackEmitterMixin {
  /// Performs an example operation that emits feedback.
  Future<void> performOperation() async {
    emitInfo('Starting operation...');
    await Future<void>.delayed(const Duration(milliseconds: 300));

    emitSuccess('Operation completed successfully!');
  }

  /// Disposes the service and cleans up resources.
  void dispose() {
    disposeFeedbackEmitter();
  }
}

/// Custom feedback handler that logs to console
///
/// This handler demonstrates how to create a custom feedback handler
/// that performs additional operations (like logging) alongside
/// the default display behavior.
class CustomConsoleFeedbackHandler implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) {
    // This handler supports all display types
    // It logs everything and delegates to other handlers
    return true;
  }

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    // Log to console with emoji indicators
    final emoji = event.type.emoji;
    final typeName = event.type.name.toUpperCase();
    debugPrint(
      '$emoji [Custom Handler] $typeName: ${event.message}',
    );

    // Note: In a real implementation, you might want to:
    // 1. Log to analytics service
    // 2. Send to crash reporting
    // 3. Store in local database
    // 4. Then delegate to other handlers for display
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

/// Info box widget
class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }
}
