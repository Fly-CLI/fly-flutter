import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/connectivity/connectivity_checker.dart';
import 'package:foundation_project/foundation/connectivity/connectivity_type.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('ConnectivityChecker', () {
    group('MockConnectivityChecker', () {
      test('should return hasInternetConnection value', () async {
        final checker = MockConnectivityChecker(hasInternetConnection: true);
        expect(await checker.hasInternetConnection(), isTrue);

        checker.setHasInternetConnection(false);
        expect(await checker.hasInternetConnection(), isFalse);
      });

      test('should return isConnectedToWifi value', () async {
        final checker = MockConnectivityChecker(isConnectedToWifi: true);
        expect(await checker.isConnectedToWifi(), isTrue);

        checker.setIsConnectedToWifi(false);
        expect(await checker.isConnectedToWifi(), isFalse);
      });

      test('should return connectivity status', () async {
        final checker = MockConnectivityChecker(
          connectivityStatus: ConnectivityType.wifi,
        );
        expect(await checker.getConnectivityStatus(), equals(ConnectivityType.wifi));

        checker.setConnectivityStatus(ConnectivityType.mobile);
        expect(await checker.getConnectivityStatus(), equals(ConnectivityType.mobile));
      });

      test('should provide connectivity change stream', () async {
        final checker = MockConnectivityChecker(
          connectivityStatus: ConnectivityType.wifi,
        );
        final stream = checker.onConnectivityChanged;
        expect(stream, isNotNull);

        final results = await stream.first;
        expect(results, isNotEmpty);
      });
    });
  });
}

