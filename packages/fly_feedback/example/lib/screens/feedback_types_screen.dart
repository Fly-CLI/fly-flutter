import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Feedback Types Example
///
/// This screen demonstrates all available feedback types:
/// - Success: Positive outcomes
/// - Error: Failures with optional retry
/// - Warning: Cautionary messages
/// - Info: Neutral information
/// - Confirmation: User confirmation dialogs
///
/// **Key Concepts:**
/// - Different feedback types for different scenarios
/// - Error feedback with retry actions
/// - Success feedback with actions
/// - Confirmation dialogs for user decisions
class FeedbackTypesScreen extends StatelessWidget {
  const FeedbackTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('3. All Feedback Types'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Feedback Types',
              description:
                  'Different types of feedback for different scenarios. Each type has specific use cases and features.',
            ),
            const SizedBox(height: 24),
            _FeedbackTypeCard(
              title: 'Success',
              description: 'Positive outcomes and successful operations',
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'Your data has been saved successfully!',
                  action: () {
                    feedbackService.showInfo(context, 'Action executed!');
                  },
                  actionLabel: 'Undo',
                );
              },
            ),
            _FeedbackTypeCard(
              title: 'Error',
              description: 'Failures that may require user action or retry',
              icon: Icons.error,
              color: Colors.red,
              onTap: () {
                feedbackService.showError(
                  context,
                  'Failed to save data. Please try again.',
                  retryAction: () {
                    feedbackService.showSuccess(
                      context,
                      'Retry successful! Data saved.',
                    );
                  },
                  retryLabel: 'Retry',
                  technicalDetails: 'HTTP 500: Internal Server Error',
                  showTechnicalDetails: false,
                );
              },
            ),
            _FeedbackTypeCard(
              title: 'Warning',
              description: 'Cautionary messages that require attention',
              icon: Icons.warning,
              color: Colors.orange,
              onTap: () {
                feedbackService.showWarning(
                  context,
                  'Warning: This action cannot be undone.',
                );
              },
            ),
            _FeedbackTypeCard(
              title: 'Info',
              description: 'Neutral information that may be helpful',
              icon: Icons.info,
              color: Colors.blue,
              onTap: () {
                feedbackService.showInfo(
                  context,
                  'Did you know? You can customize all feedback messages.',
                );
              },
            ),
            _FeedbackTypeCard(
              title: 'Confirmation',
              description: 'User confirmation dialogs for important actions',
              icon: Icons.help_outline,
              color: Colors.purple,
              onTap: () {
                feedbackService.showConfirmation(
                  context: context,
                  title: 'Delete Item',
                  message: 'Are you sure you want to delete this item? This action cannot be undone.',
                  confirmLabel: 'Delete',
                  cancelLabel: 'Cancel',
                  isDangerous: true,
                  onConfirm: () {
                    feedbackService.showSuccess(
                      context,
                      'Item deleted successfully',
                    );
                  },
                  onCancel: () {
                    feedbackService.showInfo(context, 'Deletion cancelled');
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'Feedback type examples:',
              code: '''
// Success with action
feedbackService.showSuccess(
  context,
  'Saved!',
  action: () => undo(),
  actionLabel: 'Undo',
);

// Error with retry
feedbackService.showError(
  context,
  'Failed to save',
  retryAction: () => retry(),
  retryLabel: 'Retry',
);

// Confirmation dialog
feedbackService.showConfirmation(
  context: context,
  title: 'Delete?',
  message: 'Are you sure?',
  onConfirm: () => delete(),
  isDangerous: true,
);
''',
            ),
          ],
        ),
      ),
    );
  }
}

/// Feedback type card widget
class _FeedbackTypeCard extends StatelessWidget {
  const _FeedbackTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
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

