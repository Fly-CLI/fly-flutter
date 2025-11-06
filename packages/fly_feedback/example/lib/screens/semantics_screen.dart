import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Semantics Example
///
/// This screen demonstrates how to configure accessibility (a11y) semantics
/// for feedback messages. Semantics make your app accessible to screen readers
/// and assistive technologies.
///
/// **Key Concepts:**
/// - Configuring custom semantic labels and hints
/// - Per-feedback-type semantics configuration
/// - Dynamic label and hint builders
/// - Action-specific semantics
/// - Making feedback accessible to all users
class SemanticsScreen extends StatelessWidget {
  const SemanticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7. Accessibility Semantics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Accessibility Semantics',
              description:
                  'Configure semantic labels and hints to make feedback accessible to screen readers and assistive technologies.',
            ),
            const SizedBox(height: 24),
            _SemanticsExampleCard(
              title: '1. Default Semantics',
              description:
                  'Use default semantics configuration. Labels and hints are automatically generated.',
              icon: Icons.accessibility_new,
              color: Colors.blue,
              onTap: () => _showDefaultSemantics(context),
            ),
            _SemanticsExampleCard(
              title: '2. Custom Per-Type Semantics',
              description:
                  'Configure custom labels and hints for each feedback type.',
              icon: Icons.tune,
              color: Colors.purple,
              onTap: () => _showCustomPerTypeSemantics(context),
            ),
            _SemanticsExampleCard(
              title: '3. Dynamic Label Builder',
              description:
                  'Use dynamic builders to generate labels and hints based on context.',
              icon: Icons.auto_awesome,
              color: Colors.orange,
              onTap: () => _showDynamicBuilderSemantics(context),
            ),
            _SemanticsExampleCard(
              title: '4. Action-Specific Semantics',
              description:
                  'Configure semantics for action buttons (retry, confirm, cancel, etc.).',
              icon: Icons.touch_app,
              color: Colors.teal,
              onTap: () => _showActionSemantics(context),
            ),
            _SemanticsExampleCard(
              title: '5. Complete Custom Configuration',
              description:
                  'Full control over all semantics properties including buttons, focusable, and more.',
              icon: Icons.settings,
              color: Colors.indigo,
              onTap: () => _showCompleteCustomSemantics(context),
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'Basic Usage:',
              code: '''
// 1. Create custom semantics configuration
final semanticsConfig = FeedbackSemanticsConfig(
  feedbackTypeSemantics: {
    FeedbackType.success: SemanticsProperties(
      label: 'Success notification',
      hint: 'Double tap to dismiss',
    ),
    FeedbackType.error: SemanticsProperties(
      label: 'Error notification',
      hint: 'Double tap to dismiss or retry',
    ),
  },
);

// 2. Configure handler with semantics
final handler = SnackbarFeedbackHandler(
  config: SnackbarFeedbackHandlerConfig(
    semanticsConfig: semanticsConfig,
  ),
);

// 3. Use as normal
feedbackService.showSuccess(context, 'Operation completed!');
''',
            ),
            const SizedBox(height: 24),
            const _CodeExample(
              title: 'Dynamic Builders:',
              code: '''
// Use builders for dynamic labels/hints
final semanticsConfig = FeedbackSemanticsConfig(
  labelBuilder: (event, type, context) {
    return '\${type.name.toUpperCase()}: \${event.message}';
  },
  hintBuilder: (event, type, context) {
    if (event is ErrorFeedback && event.retryAction != null) {
      return 'Double tap to retry or dismiss';
    }
    return 'Double tap to dismiss';
  },
);
''',
            ),
            const SizedBox(height: 24),
            const _CodeExample(
              title: 'Action Semantics:',
              code: '''
// Configure semantics for action buttons
final semanticsConfig = FeedbackSemanticsConfig(
  actionSemantics: {
    SemanticsActionType.retry: SemanticsProperties(
      label: 'Retry operation',
      hint: 'Double tap to retry the failed operation',
      button: true,
      focusable: true,
    ),
    SemanticsActionType.confirm: SemanticsProperties(
      label: 'Confirm action',
      hint: 'Double tap to confirm this action',
      button: true,
      focusable: true,
    ),
  },
);
''',
            ),
          ],
        ),
      ),
    );
  }

  void _showDefaultSemantics(BuildContext context) {
    final feedbackService = DefaultFeedbackService(
      handler: SnackbarFeedbackHandler(),
    );

    feedbackService.showSuccess(
      context,
      'This uses default semantics configuration',
    );
  }

  void _showCustomPerTypeSemantics(BuildContext context) {
    final semanticsConfig = FeedbackSemanticsConfig(
      feedbackTypeSemantics: {
        FeedbackType.success: const SemanticsProperties(
          label: 'Success notification',
          hint: 'Operation completed successfully. Double tap to dismiss.',
        ),
        FeedbackType.error: const SemanticsProperties(
          label: 'Error notification',
          hint: 'An error occurred. Double tap to dismiss or retry.',
        ),
        FeedbackType.warning: const SemanticsProperties(
          label: 'Warning notification',
          hint: 'Warning message. Double tap to dismiss.',
        ),
        FeedbackType.info: const SemanticsProperties(
          label: 'Information notification',
          hint: 'Informational message. Double tap to dismiss.',
        ),
      },
    );

    final feedbackService = DefaultFeedbackService(
      handler: SnackbarFeedbackHandler(
        config: SnackbarFeedbackHandlerConfig(
          semanticsConfig: semanticsConfig,
        ),
      ),
    );

    feedbackService.showSuccess(
      context,
      'Custom success semantics',
    );
  }

  void _showDynamicBuilderSemantics(BuildContext context) {
    final semanticsConfig = FeedbackSemanticsConfig(
      labelBuilder: (event, type, context) {
        final typeName = type.name.toUpperCase();
        return '$typeName: ${event.message}';
      },
      hintBuilder: (event, type, context) {
        if (event is ErrorFeedback && event.retryAction != null) {
          return 'Double tap to retry or dismiss this error';
        }
        if (event is SuccessFeedback && event.action != null) {
          return 'Double tap to ${event.actionLabel?.toLowerCase() ?? 'perform action'} or dismiss';
        }
        return 'Double tap to dismiss this ${type.name} message';
      },
    );

    final feedbackService = DefaultFeedbackService(
      handler: SnackbarFeedbackHandler(
        config: SnackbarFeedbackHandlerConfig(
          semanticsConfig: semanticsConfig,
        ),
      ),
    );

    feedbackService.showError(
      context,
      'Dynamic error semantics',
      retryAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retry action executed')),
        );
      },
      retryLabel: 'Retry',
    );
  }

  void _showActionSemantics(BuildContext context) {
    final semanticsConfig = FeedbackSemanticsConfig(
      actionSemantics: {
        SemanticsActionType.retry: const SemanticsProperties(
          label: 'Retry operation button',
          hint: 'Double tap to retry the failed operation',
          button: true,
          focusable: true,
        ),
        SemanticsActionType.confirm: const SemanticsProperties(
          label: 'Confirm action button',
          hint: 'Double tap to confirm this action',
          button: true,
          focusable: true,
        ),
        SemanticsActionType.cancel: const SemanticsProperties(
          label: 'Cancel action button',
          hint: 'Double tap to cancel this action',
          button: true,
          focusable: true,
        ),
      },
    );

    final feedbackService = DefaultFeedbackService(
      handler: DialogFeedbackHandler(
        config: DialogFeedbackHandlerConfig(
          semanticsConfig: semanticsConfig,
        ),
      ),
    );

    feedbackService.showConfirmation(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete this item? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      },
      isDangerous: true,
    );
  }

  void _showCompleteCustomSemantics(BuildContext context) {
    final semanticsConfig = FeedbackSemanticsConfig(
      feedbackTypeSemantics: {
        FeedbackType.success: const SemanticsProperties(
          label: 'Success notification',
          hint: 'Operation completed successfully',
          button: false,
          focusable: true,
          liveRegion: true,
        ),
        FeedbackType.error: const SemanticsProperties(
          label: 'Error notification',
          hint: 'An error occurred. Use retry button to try again',
          button: false,
          focusable: true,
          liveRegion: true,
        ),
      },
      actionSemantics: {
        SemanticsActionType.retry: const SemanticsProperties(
          label: 'Retry button',
          hint: 'Double tap to retry the operation',
          button: true,
          focusable: true,
        ),
        SemanticsActionType.dismiss: const SemanticsProperties(
          label: 'Dismiss button',
          hint: 'Double tap to close this notification',
          button: true,
          focusable: true,
        ),
      },
      defaultSemantics: const SemanticsProperties(
        label: 'Notification',
        hint: 'Double tap to interact',
        button: false,
        focusable: true,
      ),
    );

    final feedbackService = DefaultFeedbackService(
      handler: BannerFeedbackHandler(
        config: BannerFeedbackHandlerConfig(
          semanticsConfig: semanticsConfig,
        ),
      ),
    );

    feedbackService.showError(
      context,
      'Complete custom semantics configuration',
      retryAction: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retry executed')),
        );
      },
      retryLabel: 'Retry',
    );
  }
}

/// Card widget for semantics example
class _SemanticsExampleCard extends StatelessWidget {
  const _SemanticsExampleCard({
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
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

