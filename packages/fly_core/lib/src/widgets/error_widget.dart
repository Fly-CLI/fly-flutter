import 'package:flutter/material.dart';

/// A standardized error widget for Fly CLI applications
class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    required this.error, super.key,
    this.onRetry,
    this.retryText = 'Retry',
    this.showDetails = false,
  });
  
  final Object error;
  final VoidCallback? onRetry;
  final String retryText;
  final bool showDetails;
  
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildErrorDetails(context),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  
  Widget _buildErrorDetails(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Details:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  
  String _getErrorMessage() {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your app permissions.';
    } else if (errorString.contains('timeout')) {
      return 'The request timed out. Please try again.';
    } else if (errorString.contains('not found')) {
      return 'The requested resource was not found.';
    } else if (errorString.contains('unauthorized')) {
      return 'You are not authorized to perform this action.';
    } else if (errorString.contains('server')) {
      return 'Server error. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// A compact error widget for inline errors
class InlineErrorWidget extends StatelessWidget {
  const InlineErrorWidget({
    required this.error, super.key,
    this.onRetry,
    this.retryText = 'Retry',
  });
  
  final Object error;
  final VoidCallback? onRetry;
  final String retryText;
  
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getErrorMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(retryText),
            ),
          ],
        ],
      ),
    );
  
  String _getErrorMessage() {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error';
    } else if (errorString.contains('permission')) {
      return 'Permission denied';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout';
    } else if (errorString.contains('not found')) {
      return 'Not found';
    } else if (errorString.contains('unauthorized')) {
      return 'Unauthorized';
    } else if (errorString.contains('server')) {
      return 'Server error';
    } else {
      return 'Error occurred';
    }
  }
}

/// A snackbar error widget
class SnackbarErrorWidget extends StatelessWidget {
  const SnackbarErrorWidget({
    required this.error, super.key,
    this.onRetry,
    this.retryText = 'Retry',
  });
  
  final Object error;
  final VoidCallback? onRetry;
  final String retryText;
  
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onError,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getErrorMessage(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  
  String _getErrorMessage() {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Connection error';
    } else if (errorString.contains('permission')) {
      return 'Permission denied';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout';
    } else if (errorString.contains('not found')) {
      return 'Not found';
    } else if (errorString.contains('unauthorized')) {
      return 'Unauthorized';
    } else if (errorString.contains('server')) {
      return 'Server error';
    } else {
      return 'Error occurred';
    }
  }
}
