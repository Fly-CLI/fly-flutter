import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/error/error_message_formatter.dart';
import 'package:foundation_project/foundation/error/network_errors.dart';
import '../test_helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Error Handling Integration', () {
    test('should format network errors with localization', () {
      final logger = MockFlyLogger();
      final localizations = MockFoundationLocalizationProvider();
      final formatter = ErrorMessageFormatter(
        logger: logger,
        defaultLocalizations: localizations,
      );

      final error = ConnectionError(localizations: localizations);
      final formatted = formatter.format(error);
      expect(formatted, isNotEmpty);
      // NetworkError falls back to its message since it's not in the registry
      // The message comes from localizations.networkConnectionFailed
      expect(formatted, equals(localizations.networkConnectionFailed));
    });

    test('should classify and format various error types', () {
      final logger = MockFlyLogger();
      final formatter = ErrorMessageFormatter(logger: logger);

      final connectionError = ConnectionError();
      final timeoutError = TimeoutError(timeout: const Duration(seconds: 30));
      final dnsError = DnsError();

      expect(formatter.format(connectionError), isNotEmpty);
      expect(formatter.format(timeoutError), isNotEmpty);
      expect(formatter.format(dnsError), isNotEmpty);
    });
  });
}

