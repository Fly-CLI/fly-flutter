import 'package:flutter_test/flutter_test.dart';
import 'package:fly_localization/fly_localization.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('FoundationLocalizationProvider', () {
    group('MockFoundationLocalizationProvider', () {
      test('should provide all required getters', () {
        final provider = MockFoundationLocalizationProvider();
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
    });
  });
}

