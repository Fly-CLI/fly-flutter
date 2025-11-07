import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/error/network_errors.dart';
import 'package:foundation_project/foundation/localization/foundation_localization_provider.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('NetworkError', () {
    test('should create network error with required properties', () {
      final error = ConnectionError();
      expect(error.message, isNotEmpty);
      expect(error.isRetryable, isTrue);
      expect(error.errorCode, equals('network_connection_failed'));
      expect(error.statusCode, isNull);
    });

    test('toString should include error details', () {
      final error = ConnectionError();
      final str = error.toString();
      expect(str, contains('NetworkError'));
      expect(str, contains('network_connection_failed'));
      expect(str, contains('retryable'));
    });
  });

  group('TimeoutError', () {
    test('should create timeout error with duration', () {
      final timeout = const Duration(seconds: 30);
      final error = TimeoutError(timeout: timeout);
      expect(error.timeout, equals(timeout));
      expect(error.isRetryable, isTrue);
      expect(error.errorCode, equals('network_timeout'));
    });

    test('should use custom message when provided', () {
      final error = TimeoutError(
        timeout: const Duration(seconds: 10),
        customMessage: 'Custom timeout message',
      );
      expect(error.message, equals('Custom timeout message'));
    });

    test('toString should include timeout duration', () {
      final error = TimeoutError(timeout: const Duration(seconds: 30));
      expect(error.toString(), contains('30'));
    });

    test('recoverySuggestionKey should return correct key', () {
      final error = TimeoutError(timeout: const Duration(seconds: 10));
      expect(error.recoverySuggestionKey, equals('networkErrorTimeoutRecovery'));
    });
  });

  group('ConnectionError', () {
    test('should create connection error', () {
      final error = ConnectionError();
      expect(error.isRetryable, isTrue);
      expect(error.errorCode, equals('network_connection_failed'));
    });

    test('should use custom message when provided', () {
      final error = ConnectionError(customMessage: 'Custom connection error');
      expect(error.message, equals('Custom connection error'));
    });

    test('recoverySuggestionKey should return correct key', () {
      final error = ConnectionError();
      expect(error.recoverySuggestionKey, equals('networkErrorConnectionRecovery'));
    });
  });

  group('NoInternetError', () {
    test('should create no internet error', () {
      final error = NoInternetError();
      expect(error.isRetryable, isFalse);
      expect(error.errorCode, equals('network_no_internet'));
    });

    test('recoverySuggestionKey should return correct key', () {
      final error = NoInternetError();
      expect(error.recoverySuggestionKey, equals('networkErrorNoInternetRecovery'));
    });
  });

  group('HttpError', () {
    test('should create HTTP error with status code', () {
      final error = HttpError(statusCode: 404);
      expect(error.statusCode, equals(404));
      expect(error.isRetryable, isFalse);
      expect(error.errorCode, equals('network_http_client_error'));
    });

    test('should mark 5xx errors as retryable', () {
      final error = HttpError(statusCode: 500);
      expect(error.isRetryable, isTrue);
      expect(error.errorCode, equals('network_http_server_error'));
    });

    test('should mark 408 as retryable', () {
      final error = HttpError(statusCode: 408);
      expect(error.isRetryable, isTrue);
    });

    test('should mark 429 as retryable', () {
      final error = HttpError(statusCode: 429);
      expect(error.isRetryable, isTrue);
    });

    test('recoverySuggestionKey should return correct key for 5xx', () {
      final error = HttpError(statusCode: 500);
      expect(error.recoverySuggestionKey, equals('networkErrorServerRecovery'));
    });

    test('recoverySuggestionKey should return correct key for 401', () {
      final error = HttpError(statusCode: 401);
      expect(error.recoverySuggestionKey, equals('networkErrorAuthRecovery'));
    });

    test('recoverySuggestionKey should return correct key for 404', () {
      final error = HttpError(statusCode: 404);
      expect(error.recoverySuggestionKey, equals('networkErrorNotFoundRecovery'));
    });

    test('recoverySuggestionKey should return correct key for 429', () {
      final error = HttpError(statusCode: 429);
      expect(error.recoverySuggestionKey, equals('networkErrorRateLimitRecovery'));
    });

    test('should include response body when provided', () {
      final error = HttpError(
        statusCode: 400,
        responseBody: '{"error": "Bad request"}',
      );
      expect(error.responseBody, equals('{"error": "Bad request"}'));
    });
  });

  group('DnsError', () {
    test('should create DNS error', () {
      final error = DnsError(hostname: 'example.com');
      expect(error.hostname, equals('example.com'));
      expect(error.isRetryable, isTrue);
      expect(error.errorCode, equals('network_dns_failed'));
    });

    test('toString should include hostname', () {
      final error = DnsError(hostname: 'example.com');
      expect(error.toString(), contains('example.com'));
    });

    test('recoverySuggestionKey should return correct key', () {
      final error = DnsError();
      expect(error.recoverySuggestionKey, equals('networkErrorDnsRecovery'));
    });
  });

  group('CaptivePortalError', () {
    test('should create captive portal error', () {
      final error = CaptivePortalError();
      expect(error.isRetryable, isFalse);
      expect(error.errorCode, equals('network_captive_portal'));
    });

    test('recoverySuggestionKey should return correct key', () {
      final error = CaptivePortalError();
      expect(error.recoverySuggestionKey, equals('networkErrorCaptivePortalRecovery'));
    });
  });

  group('CertificateError', () {
    test('should create certificate error', () {
      final error = CertificateError();
      expect(error.isRetryable, isFalse);
      expect(error.errorCode, equals('network_certificate_error'));
    });

    test('recoverySuggestionKey should return correct key', () {
      final error = CertificateError();
      expect(error.recoverySuggestionKey, equals('networkErrorCertificateRecovery'));
    });
  });

  group('UnknownNetworkError', () {
    test('should create unknown network error', () {
      final originalError = Exception('Original error');
      final error = UnknownNetworkError(originalError: originalError);
      expect(error.originalError, equals(originalError));
      expect(error.isRetryable, isTrue);
      expect(error.errorCode, equals('network_unknown_error'));
    });

    test('toString should include original error', () {
      final originalError = Exception('Original error');
      final error = UnknownNetworkError(originalError: originalError);
      expect(error.toString(), contains('Original error'));
    });

    test('recoverySuggestionKey should return correct key', () {
      final error = UnknownNetworkError();
      expect(error.recoverySuggestionKey, equals('networkErrorUnknownRecovery'));
    });
  });

  group('NetworkErrorClassifier', () {
    test('should return NetworkError as-is', () {
      final error = ConnectionError();
      final classified = NetworkErrorClassifier.classifyError(error);
      expect(classified, equals(error));
    });

    test('should classify TimeoutException', () {
      final error = TimeoutException('Operation timed out', const Duration(seconds: 30));
      final classified = NetworkErrorClassifier.classifyError(
        error,
        timeout: const Duration(seconds: 30),
      );
      expect(classified, isA<TimeoutError>());
      expect((classified as TimeoutError).timeout, equals(const Duration(seconds: 30)));
    });

    test('should classify SocketException as DNS error for host lookup failures', () {
      final error = SocketException('Failed host lookup: example.com');
      final classified = NetworkErrorClassifier.classifyError(error);
      expect(classified, isA<DnsError>());
    });

    test('should classify SocketException as ConnectionError for other cases', () {
      final error = SocketException('Connection refused');
      final classified = NetworkErrorClassifier.classifyError(error);
      expect(classified, isA<ConnectionError>());
    });

    test('should classify FormatException as HttpError', () {
      final error = const FormatException('Invalid format');
      final classified = NetworkErrorClassifier.classifyError(error);
      expect(classified, isA<HttpError>());
      expect((classified as HttpError).statusCode, equals(502));
    });

    test('should classify certificate errors', () {
      final error = Exception('Certificate verification failed');
      final classified = NetworkErrorClassifier.classifyError(error);
      expect(classified, isA<CertificateError>());
    });

    test('should classify unknown errors as UnknownNetworkError', () {
      final error = Exception('Unknown error');
      final classified = NetworkErrorClassifier.classifyError(error);
      expect(classified, isA<UnknownNetworkError>());
      expect((classified as UnknownNetworkError).originalError, equals(error));
    });

    test('isRetryable should return true for retryable errors', () {
      final retryableError = ConnectionError();
      expect(NetworkErrorClassifier.isRetryable(retryableError), isTrue);
    });

    test('isRetryable should return false for non-retryable errors', () {
      final nonRetryableError = NoInternetError();
      expect(NetworkErrorClassifier.isRetryable(nonRetryableError), isFalse);
    });

    test('isRetryable should return true for unknown errors', () {
      final unknownError = Exception('Unknown');
      expect(NetworkErrorClassifier.isRetryable(unknownError), isTrue);
    });
  });
}

