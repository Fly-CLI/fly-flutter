import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Display Types Example
///
/// This screen demonstrates all available feedback display strategies:
/// - SnackBar: Bottom of screen notification
/// - Dialog: Modal dialog overlay
/// - BottomSheet: Sliding panel from bottom
/// - Toast: Temporary overlay notification
/// - Banner: Top banner notification
///
/// **Key Concepts:**
/// - Different display strategies for different use cases
/// - Choosing the right display type for your feedback
class DisplayTypesScreen extends StatelessWidget {
  const DisplayTypesScreen({super.key});

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
        title: const Text('2. All Display Types'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Display Strategies',
              description:
                  'Different feedback types can be displayed in different ways. Choose the display that best fits your use case.',
            ),
            const SizedBox(height: 24),
            _DisplayTypeCard(
              title: 'SnackBar',
              description: 'Bottom notification, perfect for quick messages',
              icon: Icons.message,
              color: Colors.blue,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'This is a SnackBar notification',
                  display: FeedbackDisplay.snackBar,
                );
              },
            ),
            _DisplayTypeCard(
              title: 'Dialog',
              description: 'Modal dialog, use for important messages',
              icon: Icons.info_outline,
              color: Colors.purple,
              onTap: () {
                feedbackService.showInfo(
                  context,
                  'This is a Dialog notification',
                  display: FeedbackDisplay.dialog,
                );
              },
            ),
            _DisplayTypeCard(
              title: 'Bottom Sheet',
              description: 'Sliding panel, great for detailed information',
              icon: Icons.expand_less,
              color: Colors.orange,
              onTap: () {
                feedbackService.showInfo(
                  context,
                  'This is a Bottom Sheet notification. It can contain more detailed information.',
                  display: FeedbackDisplay.bottomSheet,
                );
              },
            ),
            _DisplayTypeCard(
              title: 'Toast',
              description: 'Temporary overlay, non-intrusive',
              icon: Icons.notifications_active,
              color: Colors.green,
              onTap: () {
                feedbackService.showSuccess(
                  context,
                  'This is a Toast notification',
                  display: FeedbackDisplay.toast,
                );
              },
            ),
            _DisplayTypeCard(
              title: 'Banner',
              description: 'Top banner, perfect for persistent notifications',
              icon: Icons.campaign,
              color: Colors.red,
              onTap: () {
                feedbackService.showWarning(
                  context,
                  'This is a Banner notification at the top',
                  display: FeedbackDisplay.banner,
                );
              },
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'How to specify display type:',
              code: '''
// Specify display type when showing feedback
feedbackService.showSuccess(
  context,
  'Message',
  display: FeedbackDisplay.snackBar, // or dialog, bottomSheet, toast, banner
);
''',
            ),
          ],
        ),
      ),
    );
  }
}

/// Display type card widget
class _DisplayTypeCard extends StatelessWidget {
  const _DisplayTypeCard({
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

