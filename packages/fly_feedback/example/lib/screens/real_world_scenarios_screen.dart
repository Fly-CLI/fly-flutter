import 'package:flutter/material.dart';
import 'package:fly_feedback/fly_feedback.dart';

/// Real-World Scenarios Example
///
/// This screen demonstrates practical usage patterns:
/// - API calls with loading states
/// - Form validation
/// - File operations
/// - Network errors
/// - Confirmation dialogs
///
/// **Key Concepts:**
/// - Real-world patterns and best practices
/// - Handling different error scenarios
/// - User-friendly error messages
/// - Retry mechanisms
class RealWorldScenariosScreen extends StatelessWidget {
  const RealWorldScenariosScreen({super.key});

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
        title: const Text('6. Real-World Scenarios'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader(
              title: 'Practical Examples',
              description:
                  'Real-world scenarios you\'ll encounter in production apps. '
                  'These examples show best practices for common use cases.',
            ),
            const SizedBox(height: 24),
            _ScenarioCard(
              title: 'API Call Success',
              description: 'Handle successful API responses',
              icon: Icons.cloud_done,
              color: Colors.green,
              onTap: () => _simulateApiCall(feedbackService, context),
            ),
            _ScenarioCard(
              title: 'API Call Failure',
              description: 'Handle API errors with retry',
              icon: Icons.cloud_off,
              color: Colors.red,
              onTap: () => _simulateApiError(feedbackService, context),
            ),
            _ScenarioCard(
              title: 'Form Validation',
              description: 'Validate form inputs',
              icon: Icons.assignment,
              color: Colors.orange,
              onTap: () => _simulateFormValidation(feedbackService, context),
            ),
            _ScenarioCard(
              title: 'File Upload',
              description: 'Handle file operations',
              icon: Icons.upload_file,
              color: Colors.blue,
              onTap: () => _simulateFileUpload(feedbackService, context),
            ),
            _ScenarioCard(
              title: 'Network Error',
              description: 'Handle network connectivity issues',
              icon: Icons.wifi_off,
              color: Colors.purple,
              onTap: () => _simulateNetworkError(feedbackService, context),
            ),
            _ScenarioCard(
              title: 'Delete Confirmation',
              description: 'Confirm destructive actions',
              icon: Icons.delete,
              color: Colors.red,
              onTap: () => _simulateDeleteConfirmation(
                feedbackService,
                context,
              ),
            ),
            const SizedBox(height: 32),
            const _CodeExample(
              title: 'API call example:',
              code: '''
Future<void> fetchUserData() async {
  try {
    final user = await apiService.getUser();
    feedbackService.showSuccess(
      context,
      'User data loaded successfully!',
    );
  } catch (e) {
    feedbackService.showError(
      context,
      'Failed to load user data',
      retryAction: () => fetchUserData(),
      retryLabel: 'Retry',
    );
  }
}
''',
            ),
          ],
        ),
      ),
    );
  }

  /// Simulate a successful API call
  Future<void> _simulateApiCall(
    DefaultFeedbackService service,
    BuildContext context,
  ) async {
    service.showInfo(
      context,
      'Loading user data...',
      display: FeedbackDisplay.toast,
    );

    await Future.delayed(const Duration(seconds: 1));

    service.showSuccess(
      context,
      'User data loaded successfully!',
      display: FeedbackDisplay.snackBar,
    );
  }

  /// Simulate an API error with retry
  void _simulateApiError(
    DefaultFeedbackService service,
    BuildContext context,
  ) {
    service.showError(
      context,
      'Failed to load data. Please check your connection and try again.',
      retryAction: () {
        service.showInfo(context, 'Retrying...');
        Future.delayed(const Duration(seconds: 1), () {
          service.showSuccess(context, 'Data loaded successfully!');
        });
      },
      retryLabel: 'Retry',
      technicalDetails: 'HTTP 500: Internal Server Error',
      showTechnicalDetails: false,
    );
  }

  /// Simulate form validation
  void _simulateFormValidation(
    DefaultFeedbackService service,
    BuildContext context,
  ) {
    // Simulate validation errors
    service.showError(
      context,
      'Please fill in all required fields',
      display: FeedbackDisplay.banner,
    );

    Future.delayed(const Duration(seconds: 2), () {
      service.showWarning(
        context,
        'Email format is invalid',
        display: FeedbackDisplay.snackBar,
      );
    });
  }

  /// Simulate file upload
  Future<void> _simulateFileUpload(
    DefaultFeedbackService service,
    BuildContext context,
  ) async {
    service.showInfo(
      context,
      'Uploading file...',
      display: FeedbackDisplay.toast,
    );

    await Future.delayed(const Duration(seconds: 1));

    // Simulate upload progress
    service.showInfo(
      context,
      'Upload progress: 50%',
      display: FeedbackDisplay.snackBar,
    );

    await Future.delayed(const Duration(seconds: 1));

    service.showSuccess(
      context,
      'File uploaded successfully!',
      display: FeedbackDisplay.snackBar,
      action: () {
        service.showInfo(context, 'Opening file...');
      },
      actionLabel: 'Open',
    );
  }

  /// Simulate network error
  void _simulateNetworkError(
    DefaultFeedbackService service,
    BuildContext context,
  ) {
    service.showError(
      context,
      'No internet connection. Please check your network settings.',
      display: FeedbackDisplay.dialog,
      retryAction: () {
        service.showInfo(context, 'Checking connection...');
        Future.delayed(const Duration(seconds: 1), () {
          service.showSuccess(context, 'Connection restored!');
        });
      },
      retryLabel: 'Check Again',
    );
  }

  /// Simulate delete confirmation
  void _simulateDeleteConfirmation(
    DefaultFeedbackService service,
    BuildContext context,
  ) {
    service.showConfirmation(
      context: context,
      title: 'Delete Item',
      message:
          'Are you sure you want to delete this item? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDangerous: true,
      onConfirm: () {
        service.showSuccess(
          context,
          'Item deleted successfully',
        );
      },
      onCancel: () {
        service.showInfo(context, 'Deletion cancelled');
      },
    );
  }
}

/// Scenario card widget
class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
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

