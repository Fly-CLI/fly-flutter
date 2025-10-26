import 'dart:async';
import 'dart:io';

/// Retry policy for network operations with exponential backoff
class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  /// Execute action with retry logic
  Future<T> execute<T>(Future<T> Function() action) async {
    var attempt = 0;
    var delay = initialDelay;

    while (true) {
      try {
        return await action().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Network request timed out'),
        );
      } catch (e) {
        attempt++;

        if (attempt >= maxAttempts || !_isRetryable(e)) {
          rethrow;
        }

        print('Attempt $attempt failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);

        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
        if (delay > maxDelay) delay = maxDelay;
      }
    }
  }

  /// Check if error is retryable
  bool _isRetryable(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException;
  }
}

/// Connectivity checker for network status detection
class ConnectivityChecker {
  /// Check if online
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('pub.dev').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if can reach registry
  Future<bool> canReachRegistry() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://pub.dev'));
      final response = await request.close().timeout(const Duration(seconds: 5));
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
