import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/navigation/default_navigation_service.dart';
import 'package:foundation_project/foundation/navigation/navigation_service.dart';

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

