import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/src/haptics/haptic_config.dart';
import 'package:fly_feedback/src/haptics/haptic_feedback_service.dart';
import 'package:fly_feedback/src/haptics/haptic_types.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticFeedbackService', () {
    late HapticFeedbackService service;

    setUp(() {
      service = const HapticFeedbackService();
    });

    test('should create service', () {
      expect(service, isNotNull);
    });

    test('should trigger haptic for feedback type', () {
      final config = HapticConfig.defaults();

      // This test verifies the method doesn't throw
      // Actual haptic feedback requires a device or emulator
      expect(
        () => service.triggerHapticForFeedback(FeedbackType.success, config),
        returnsNormally,
      );
    });

    test('should trigger haptic type', () {
      // This test verifies the method doesn't throw
      // Actual haptic feedback requires a device or emulator
      expect(
        () => service.triggerHaptic(HapticType.lightImpact),
        returnsNormally,
      );
      expect(
        () => service.triggerHaptic(HapticType.mediumImpact),
        returnsNormally,
      );
      expect(
        () => service.triggerHaptic(HapticType.heavyImpact),
        returnsNormally,
      );
      expect(
        () => service.triggerHaptic(HapticType.selectionClick),
        returnsNormally,
      );
    });

    test('should not throw for none haptic type', () {
      expect(
        () => service.triggerHaptic(HapticType.none),
        returnsNormally,
      );
    });

    test('should handle vibrate type gracefully', () {
      // Vibrate may not work on all platforms, but should not throw
      expect(
        () => service.triggerHaptic(HapticType.vibrate),
        returnsNormally,
      );
    });
  });
}

