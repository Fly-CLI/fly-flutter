import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_navigation/fly_navigation.dart';

void main() {
  group('DefaultNavigationService', () {
    test('should implement NavigationService<String>', () {
      final navigatorKey = GlobalKey<NavigatorState>();
      final service = DefaultNavigationService(navigatorKey: navigatorKey);
      expect(service, isA<NavigationService<String>>());
    });

    test('should store navigator key', () {
      final navigatorKey = GlobalKey<NavigatorState>();
      final service = DefaultNavigationService(navigatorKey: navigatorKey);
      expect(service.navigatorKey, equals(navigatorKey));
    });
  });
}

