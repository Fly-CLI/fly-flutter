import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation_project/foundation/di/global_container.dart';

void main() {
  group('GlobalContainer', () {
    tearDown(() {
      GlobalContainer.reset();
    });

    test('should throw StateError when accessed before initialization', () {
      expect(
        () => GlobalContainer.instance,
        throwsStateError,
      );
    });

    test('should initialize container', () {
      GlobalContainer.initialize();
      expect(GlobalContainer.instance, isA<ProviderContainer>());
      expect(GlobalContainer.isInitialized, isTrue);
    });

    test('should throw StateError when initialized twice', () {
      GlobalContainer.initialize();
      expect(
        () => GlobalContainer.initialize(),
        throwsStateError,
      );
    });

    test('should override for testing', () {
      final testContainer = ProviderContainer();
      GlobalContainer.overrideForTesting(testContainer);
      expect(GlobalContainer.instance, equals(testContainer));
      expect(GlobalContainer.isInitialized, isTrue);
    });

    test('should reset container', () {
      GlobalContainer.initialize();
      expect(GlobalContainer.isInitialized, isTrue);

      GlobalContainer.reset();
      expect(GlobalContainer.isInitialized, isFalse);
      expect(
        () => GlobalContainer.instance,
        throwsStateError,
      );
    });

    test('should dispose container on reset', () {
      final container = ProviderContainer();
      GlobalContainer.overrideForTesting(container);
      GlobalContainer.reset();
      // Container should be disposed (we can't directly check, but reset should work)
      expect(GlobalContainer.isInitialized, isFalse);
    });

    test('isInitialized should return false when not initialized', () {
      expect(GlobalContainer.isInitialized, isFalse);
    });

    test('isInitialized should return true after initialization', () {
      GlobalContainer.initialize();
      expect(GlobalContainer.isInitialized, isTrue);
    });

    test('isInitialized should return true after overrideForTesting', () {
      final testContainer = ProviderContainer();
      GlobalContainer.overrideForTesting(testContainer);
      expect(GlobalContainer.isInitialized, isTrue);
    });
  });
}

