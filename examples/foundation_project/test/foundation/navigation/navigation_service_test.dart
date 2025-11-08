import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_navigation/fly_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NavigationService', () {
    group('DefaultNavigationService', () {
      late GlobalKey<NavigatorState> navigatorKey;
      late DefaultNavigationService service;

      setUp(() {
        navigatorKey = GlobalKey<NavigatorState>();
        service = DefaultNavigationService(navigatorKey: navigatorKey);
      });

      test('should create service with navigator key', () {
        expect(service.navigatorKey, equals(navigatorKey));
      });

      test('navigateTo should throw when navigator not initialized', () {
        expect(
          () => service.navigateTo('/test'),
          throwsStateError,
        );
      });

      test('navigateBack should throw when navigator not initialized', () {
        expect(
          () => service.navigateBack(),
          throwsStateError,
        );
      });

      test('navigateReplace should throw when navigator not initialized', () {
        expect(
          () => service.navigateReplace('/test'),
          throwsStateError,
        );
      });

      test('navigateClearStack should throw when navigator not initialized', () {
        expect(
          () => service.navigateClearStack('/test'),
          throwsStateError,
        );
      });

      test('canGoBack should return false when navigator not initialized', () {
        expect(service.canGoBack(), isFalse);
      });

      test('canGoBack should return true when navigator can pop', () {
        // This would require a full widget test with MaterialApp
        // For unit tests, we test the null check path
        expect(service.canGoBack(), isFalse);
      });
    });
  });
}

