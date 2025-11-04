import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom error handler to prevent stack trace processing issues
class CustomErrorHandler {
  static void initialize() {
    // Override Flutter's error handling to prevent stack trace processing issues
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error without processing the stack trace
      if (kDebugMode) {
        print('Flutter Error: ${details.exception}');
        print('Library: ${details.library}');
        print('Context: ${details.context}');
        // Don't print stack trace to avoid URI parsing issues
      }

      // Report to crashlytics or other error reporting services
      _reportError(details);
    };

    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        print('Platform Error: $error');
        // Don't print stack trace to avoid URI parsing issues
      }

      _reportPlatformError(error, stack);
      return true;
    };
  }

  /// Report Flutter errors safely
  static void _reportError(FlutterErrorDetails details) {
    try {
      // Here you would typically report to crashlytics or other services
      // For now, just log safely
      if (kDebugMode) {
        print('Error reported: ${details.exception}');
      }
    } catch (e) {
      // If error reporting fails, don't crash the app
      if (kDebugMode) {
        print('Failed to report error: $e');
      }
    }
  }

  /// Report platform errors safely
  static void _reportPlatformError(Object error, StackTrace? stack) {
    try {
      // Here you would typically report to crashlytics or other services
      // For now, just log safely
      if (kDebugMode) {
        print('Platform error reported: $error');
      }
    } catch (e) {
      // If error reporting fails, don't crash the app
      if (kDebugMode) {
        print('Failed to report platform error: $e');
      }
    }
  }

  /// Handle errors in widget building
  static Widget handleWidgetError(Widget child, {String? errorMessage}) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          // Return a safe error widget instead of crashing
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  errorMessage ?? 'An error occurred while loading this widget',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to rebuild the widget
                    if (context.mounted) {
                      // This will trigger a rebuild
                      (context as Element).markNeedsBuild();
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
