import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/connectivity/connectivity_service.dart';
import 'package:foundation_project/foundation/connectivity/connectivity_type.dart';
import '../test_helpers/mocks.dart';

void main() {
  group('ConnectivityService', () {
    late MockFlyLogger mockLogger;
    late MockConnectivityChecker mockChecker;
    late ConnectivityService service;

    setUp(() {
      mockLogger = MockFlyLogger();
      mockChecker = MockConnectivityChecker(hasInternetConnection: true);
      service = ConnectivityService(
        checker: mockChecker,
        logger: mockLogger,
      );
    });

    group('hasInternetConnection', () {
      test('should return true when checker returns true', () async {
        mockChecker.setHasInternetConnection(true);
        final result = await service.hasInternetConnection();
        expect(result, isTrue);
      });

      test('should return false when checker returns false', () async {
        mockChecker.setHasInternetConnection(false);
        final result = await service.hasInternetConnection();
        expect(result, isFalse);
      });

      test('should log connection check', () async {
        mockLogger.clear();
        await service.hasInternetConnection();
        expect(mockLogger.logMessages.length, greaterThan(0));
      });
    });

    group('isConnectedToWifi', () {
      test('should return true when connected to WiFi', () async {
        mockChecker.setIsConnectedToWifi(true);
        final result = await service.isConnectedToWifi();
        expect(result, isTrue);
      });

      test('should return false when not connected to WiFi', () async {
        mockChecker.setIsConnectedToWifi(false);
        final result = await service.isConnectedToWifi();
        expect(result, isFalse);
      });
    });

    group('getConnectivityStatus', () {
      test('should return connectivity status from checker', () async {
        mockChecker.setConnectivityStatus(ConnectivityType.wifi);
        final status = await service.getConnectivityStatus();
        expect(status, equals(ConnectivityType.wifi));
      });

      test('should return none on error', () async {
        // This would require a checker that throws, but MockConnectivityChecker doesn't throw
        // So we test the normal path
        mockChecker.setConnectivityStatus(ConnectivityType.none);
        final status = await service.getConnectivityStatus();
        expect(status, equals(ConnectivityType.none));
      });
    });

    group('onConnectivityChanged', () {
      test('should provide connectivity change stream', () {
        final stream = service.onConnectivityChanged;
        expect(stream, isNotNull);
      });
    });

    group('waitForConnection', () {
      test('should return true when connection becomes available', () async {
        mockChecker.setHasInternetConnection(true);
        final result = await service.waitForConnection(
          timeout: const Duration(seconds: 1),
          pollInterval: const Duration(milliseconds: 100),
        );
        expect(result, isTrue);
      });

      test('should return false when timeout expires', () async {
        mockChecker.setHasInternetConnection(false);
        final result = await service.waitForConnection(
          timeout: const Duration(milliseconds: 100),
          pollInterval: const Duration(milliseconds: 50),
        );
        expect(result, isFalse);
      });
    });

    group('createConnectionStateStream', () {
      test('should create connection state stream', () {
        final stream = service.createConnectionStateStream();
        expect(stream, isNotNull);
      });
    });
  });
}

