import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/localization/default_foundation_localization_provider.dart';

void main() {
  group('DefaultFoundationLocalizationProvider', () {
    test('should be a singleton', () {
      final instance1 = DefaultFoundationLocalizationProvider();
      final instance2 = DefaultFoundationLocalizationProvider();
      expect(instance1, same(instance2));
    });

    test('should provide all required English messages', () {
      final provider = DefaultFoundationLocalizationProvider();
      expect(provider.networkErrorConnectionRecovery, isNotEmpty);
      expect(provider.networkErrorTimeoutRecovery, isNotEmpty);
      expect(provider.networkErrorDnsRecovery, isNotEmpty);
      expect(provider.networkErrorNoInternetRecovery, isNotEmpty);
      expect(provider.networkErrorAuthRecovery, isNotEmpty);
      expect(provider.networkErrorNotFoundRecovery, isNotEmpty);
      expect(provider.networkErrorRateLimitRecovery, isNotEmpty);
      expect(provider.networkErrorServerRecovery, isNotEmpty);
      expect(provider.networkErrorCertificateRecovery, isNotEmpty);
      expect(provider.networkErrorUnknownRecovery, isNotEmpty);
      expect(provider.networkErrorHttpRecovery, isNotEmpty);
      expect(provider.networkConnectionFailed, isNotEmpty);
      expect(provider.networkNoInternet, isNotEmpty);
      expect(provider.networkTimeout, isNotEmpty);
      expect(provider.networkDnsFailed, isNotEmpty);
      expect(provider.networkCaptivePortal, isNotEmpty);
      expect(provider.networkCertificateError, isNotEmpty);
      expect(provider.networkUnknownError, isNotEmpty);
      expect(provider.networkHttpClientError, isNotEmpty);
      expect(provider.networkHttpServerError, isNotEmpty);
      expect(provider.operationTimedOut, isNotEmpty);
      expect(provider.invalidResponseFormat, isNotEmpty);
      expect(provider.databaseErrorPleaseTryAgain, isNotEmpty);
      expect(provider.permissionDenied, isNotEmpty);
      expect(provider.noInternetConnectionQueuedShort, isNotEmpty);
      expect(provider.noInternetConnectionQueuedLong, isNotEmpty);
      expect(provider.networkOperationFailedAfterRetries, isNotEmpty);
      expect(provider.networkOperationDefault, isNotEmpty);
      expect(provider.unexpectedErrorOccurred, isNotEmpty);
    });

    test('should provide user-friendly error messages', () {
      final provider = DefaultFoundationLocalizationProvider();
      expect(provider.networkErrorConnectionRecovery, contains('Connection failed'));
      expect(provider.networkErrorTimeoutRecovery, contains('timed out'));
      expect(provider.networkErrorNoInternetRecovery, contains('No internet'));
      expect(provider.unexpectedErrorOccurred, contains('unexpected error'));
    });
  });
}

