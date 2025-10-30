import 'package:flutter_test/flutter_test.dart';
import 'package:fly_core/src/retry/retryable_exception.dart';

void main() {
  group('RetryableExceptionChecker', () {
    test('identifies SocketException as retryable', () {
      final exception = Exception('SocketException: Connection failed');
      expect(RetryableExceptionChecker.isRetryable(exception), true);
    });

    test('identifies TimeoutException as retryable', () {
      final exception = Exception('TimeoutException: Operation timed out');
      expect(RetryableExceptionChecker.isRetryable(exception), true);
    });

    test('identifies HttpException as retryable', () {
      final exception = Exception('HttpException: Failed request');
      expect(RetryableExceptionChecker.isRetryable(exception), true);
    });

    test('identifies connection errors as retryable', () {
      expect(RetryableExceptionChecker.isRetryable(
        Exception('Connection refused'),
      ), true);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('Connection reset'),
      ), true);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('Connection timed out'),
      ), true);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('Network is unreachable'),
      ), true);
    });

    test('identifies HTTP 5xx errors as retryable', () {
      expect(RetryableExceptionChecker.isRetryable(
        Exception('504 Gateway Timeout'),
      ), true);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('503 Service Unavailable'),
      ), true);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('502 Bad Gateway'),
      ), true);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('429 Too Many Requests'),
      ), true);
    });

    test('identifies non-retryable exceptions', () {
      expect(RetryableExceptionChecker.isRetryable(
        Exception('Invalid input'),
      ), false);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('File not found'),
      ), false);
      expect(RetryableExceptionChecker.isRetryable(
        Exception('Permission denied'),
      ), false);
    });

    test('provides retry reasons for common errors', () {
      expect(
        RetryableExceptionChecker.getRetryReason(
          Exception('TimeoutException: Operation timed out'),
        ),
        'Operation timed out',
      );
      
      expect(
        RetryableExceptionChecker.getRetryReason(
          Exception('Connection error'),
        ),
        'Network connection issue',
      );
      
      expect(
        RetryableExceptionChecker.getRetryReason(
          Exception('503 error'),
        ),
        'Server temporarily unavailable',
      );
      
      expect(
        RetryableExceptionChecker.getRetryReason(
          Exception('429 rate limit'),
        ),
        'Rate limited, will retry',
      );
    });
  });

  group('RetryableExceptionClassifier', () {
    test('stores retryable status and message', () {
      final classifier = RetryableExceptionClassifier(true, 'Test message');
      expect(classifier.isRetryable, true);
      expect(classifier.message, 'Test message');
    });

    test('stores retryable status without message', () {
      final classifier = RetryableExceptionClassifier(false);
      expect(classifier.isRetryable, false);
      expect(classifier.message, null);
    });
  });
}

