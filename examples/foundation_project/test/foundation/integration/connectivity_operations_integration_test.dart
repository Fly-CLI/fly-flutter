import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/connectivity/connectivity_service.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('Connectivity and Operations Integration', () {
    test('should check connectivity before operations', () async {
      final logger = MockFlyLogger();
      final checker = MockConnectivityChecker(hasInternetConnection: true);
      final service = ConnectivityService(checker: checker, logger: logger);

      final hasConnection = await service.hasInternetConnection();
      expect(hasConnection, isTrue);
      expect(logger.logMessages.length, greaterThan(0));
    });

    test('should handle connectivity changes', () async {
      final logger = MockFlyLogger();
      final checker = MockConnectivityChecker(hasInternetConnection: false);
      final service = ConnectivityService(checker: checker, logger: logger);

      final hasConnection = await service.hasInternetConnection();
      expect(hasConnection, isFalse);
    });
  });
}

