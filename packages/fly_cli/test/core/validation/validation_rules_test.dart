import 'package:fly_cli/src/core/validation/validation_rules.dart';
import 'package:test/test.dart';

void main() {
  group('NameValidationRule', () {
    group('Project Name Validation', () {
      test('should accept valid project names', () {
        final validNames = [
          'my_app',
          'flutter_app',
          'test_project',
          'sample_app',
          'demo_app',
          'hello_world',
          'counter_app',
          'todo_app',
          'weather_app',
          'news_app',
        ];

        for (final name in validNames) {
          final result = NameValidationRule.validateProjectName(name);
          expect(
            result.isValid,
            isTrue,
            reason: 'Project name "$name" should be valid',
          );
          expect(NameValidationRule.isValidProjectName(name), isTrue);
        }
      });

      test('should reject invalid project names', () {
        final invalidNames = [
          'MyApp', // uppercase
          'my-app', // hyphen
          'my.app', // dot
          'my app', // space
          '123app', // starts with number
          'app@test', // special character
          'a', // too short
          'a' * 51, // too long (51 characters)
          '', // empty
        ];

        for (final name in invalidNames) {
          final result = NameValidationRule.validateProjectName(name);
          expect(
            result.isValid,
            isFalse,
            reason: 'Project name "$name" should be invalid',
          );
          expect(NameValidationRule.isValidProjectName(name), isFalse);
        }
      });

      test('should provide detailed error messages', () {
        final result = NameValidationRule.validateProjectName('MyApp');
        expect(result.isValid, isFalse);
        expect(
          result.errors,
          contains(
            'Project name must contain only lowercase letters, numbers, and underscores',
          ),
        );
        expect(
          result.errors,
          contains('Project name must start with a letter'),
        );
      });
    });

    group('Screen Name Validation', () {
      test('should accept valid screen names', () {
        final validNames = [
          'home',
          'login',
          'profile',
          'settings',
          'dashboard',
          'user_profile',
          'product_list',
          'order_detail',
          'payment_screen',
          'search_results',
        ];

        for (final name in validNames) {
          final result = NameValidationRule.validateScreenName(name);
          expect(
            result.isValid,
            isTrue,
            reason: 'Screen name "$name" should be valid',
          );
          expect(NameValidationRule.isValidScreenName(name), isTrue);
        }
      });

      test('should reject invalid screen names', () {
        final invalidNames = [
          'Home', // uppercase
          'home-screen', // hyphen
          'home.screen', // dot
          'home screen', // space
          '123screen', // starts with number
          'screen@test', // special character
          'a', // too short
          '', // empty
        ];

        for (final name in invalidNames) {
          final result = NameValidationRule.validateScreenName(name);
          expect(
            result.isValid,
            isFalse,
            reason: 'Screen name "$name" should be invalid',
          );
          expect(NameValidationRule.isValidScreenName(name), isFalse);
        }
      });
    });

    group('Service Name Validation', () {
      test('should accept valid service names', () {
        final validNames = [
          'auth',
          'api',
          'database',
          'storage',
          'notification',
          'payment',
          'analytics',
          'crash_reporting',
          'user_service',
          'product_service',
        ];

        for (final name in validNames) {
          final result = NameValidationRule.validateServiceName(name);
          expect(
            result.isValid,
            isTrue,
            reason: 'Service name "$name" should be valid',
          );
          expect(NameValidationRule.isValidServiceName(name), isTrue);
        }
      });

      test('should reject invalid service names', () {
        final invalidNames = [
          'Auth', // uppercase
          'auth-service', // hyphen
          'auth.service', // dot
          'auth service', // space
          '123service', // starts with number
          'service@test', // special character
          'a', // too short
          '', // empty
        ];

        for (final name in invalidNames) {
          final result = NameValidationRule.validateServiceName(name);
          expect(
            result.isValid,
            isFalse,
            reason: 'Service name "$name" should be invalid',
          );
          expect(NameValidationRule.isValidServiceName(name), isFalse);
        }
      });
    });

    group('Feature Name Validation', () {
      test('should accept valid feature names', () {
        final validNames = [
          'authentication',
          'user_management',
          'product_catalog',
          'shopping_cart',
          'order_management',
          'payment_processing',
          'notification_system',
          'analytics_dashboard',
          'admin_panel',
          'search_functionality',
        ];

        for (final name in validNames) {
          final result = NameValidationRule.validateFeatureName(name);
          expect(
            result.isValid,
            isTrue,
            reason: 'Feature name "$name" should be valid',
          );
          expect(NameValidationRule.isValidFeatureName(name), isTrue);
        }
      });

      test('should reject invalid feature names', () {
        final invalidNames = [
          'Authentication', // uppercase
          'user-management', // hyphen
          'user.management', // dot
          'user management', // space
          '123feature', // starts with number
          'feature@test', // special character
          'a', // too short
          '', // empty
        ];

        for (final name in invalidNames) {
          final result = NameValidationRule.validateFeatureName(name);
          expect(
            result.isValid,
            isFalse,
            reason: 'Feature name "$name" should be invalid',
          );
          expect(NameValidationRule.isValidFeatureName(name), isFalse);
        }
      });
    });
  });
}
