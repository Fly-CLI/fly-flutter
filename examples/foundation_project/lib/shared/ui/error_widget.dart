import 'package:flutter/material.dart';

/// Custom error widget for displaying errors
/// 
/// [retryText] - Optional label for retry button. If not provided and [onRetry] is set,
/// an icon-only button will be shown.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryText;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              retryText != null
                  ? ElevatedButton(
                      onPressed: onRetry,
                      child: Text(retryText!),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRetry,
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
