import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Simple Direct Usage Example
///
/// This screen demonstrates the most basic usage of the fly_feedback package.
/// We use FeedbackService directly with BuildContext to show feedback.
///
/// **Key Concepts:**
/// - Using DefaultFeedbackService with a handler
/// - Calling showSuccess, showError, etc. directly
/// - No need for streams or listeners
class SimpleDirectUsageScreen extends StatelessWidget {
  const SimpleDirectUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a feedback service with default handlers
    // In a real app, you'd typically inject this via dependency injection
    final feedbackService = DefaultFeedbackService(
      handler: CompositeFeedbackHandler([
        SnackbarFeedbackHandler(),
        DialogFeedbackHandler(),
        BottomSheetFeedbackHandler(),
        ToastFeedbackHandler(),
        BannerFeedbackHandler(),
      ]),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('1. Simple Direct Usage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Quick Start',
              description:
                  'The simplest way to show feedback is using FeedbackService directly.',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                feedbackService.showSuccess(
                  context,
                  'Operation completed successfully!',
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Show Success'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                feedbackService.showError(
                  context,
                  'Something went wrong. Please try again.',
                );
              },
              icon: const Icon(Icons.error),
              label: const Text('Show Error'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                feedbackService.showWarning(
                  context,
                  'Warning: This action may have consequences.',
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Show Warning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                feedbackService.showInfo(
                  context,
                  'Here is some useful information for you.',
                );
              },
              icon: const Icon(Icons.info),
              label: const Text('Show Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'How it works:',
              code: '''
// 1. Create a feedback service
final feedbackService = DefaultFeedbackService(
  handler: CompositeFeedbackHandler([
    SnackbarFeedbackHandler(),
    DialogFeedbackHandler(),
    // ... other handlers
  ]),
);

// 2. Use it anywhere you have BuildContext
feedbackService.showSuccess(context, 'Success!');
feedbackService.showError(context, 'Error!');
''',
            ),
          ],
        ),
      ),
    );
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

