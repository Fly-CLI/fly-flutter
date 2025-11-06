import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/src/haptics/haptic_config.dart';
import 'package:fly_feedback/src/haptics/haptic_types.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

void main() {
  group('HapticConfig', () {
    test('should create with default values', () {
      const config = HapticConfig();

      expect(config.enabled, true);
      expect(config.defaultType, HapticType.lightImpact);
      expect(config.typeMapping, isEmpty);
    });

    test('should create with defaults factory', () {
      final config = HapticConfig.defaults();

      expect(config.enabled, true);
      expect(config.defaultType, HapticType.lightImpact);
      expect(config.typeMapping, {
        FeedbackType.success: HapticType.lightImpact,
        FeedbackType.error: HapticType.mediumImpact,
        FeedbackType.warning: HapticType.lightImpact,
        FeedbackType.info: HapticType.selectionClick,
      });
    });

    test('should create disabled config', () {
      final config = HapticConfig.disabled();

      expect(config.enabled, false);
      expect(config.defaultType, HapticType.none);
      expect(config.typeMapping, isEmpty);
    });

    test('should get haptic type for feedback type', () {
      final config = HapticConfig(
        typeMapping: {
          FeedbackType.success: HapticType.lightImpact,
          FeedbackType.error: HapticType.mediumImpact,
        },
        defaultType: HapticType.selectionClick,
      );

      expect(config.getHapticType(FeedbackType.success), HapticType.lightImpact);
      expect(config.getHapticType(FeedbackType.error), HapticType.mediumImpact);
      expect(config.getHapticType(FeedbackType.warning), HapticType.selectionClick);
      expect(config.getHapticType(FeedbackType.info), HapticType.selectionClick);
    });

    test('should return none when disabled', () {
      final config = HapticConfig.disabled();

      expect(config.getHapticType(FeedbackType.success), HapticType.none);
      expect(config.getHapticType(FeedbackType.error), HapticType.none);
    });

    test('should copy with new values', () {
      final config = HapticConfig.defaults();
      final copied = config.copyWith(
        enabled: false,
        defaultType: HapticType.heavyImpact,
      );

      expect(copied.enabled, false);
      expect(copied.defaultType, HapticType.heavyImpact);
      expect(copied.typeMapping, config.typeMapping);
    });

    test('should merge with other config', () {
      final config1 = HapticConfig(
        typeMapping: {
          FeedbackType.success: HapticType.lightImpact,
        },
      );
      final config2 = HapticConfig(
        typeMapping: {
          FeedbackType.error: HapticType.mediumImpact,
        },
        defaultType: HapticType.heavyImpact,
      );

      final merged = config1.merge(config2);

      expect(merged.enabled, config2.enabled);
      expect(merged.defaultType, HapticType.heavyImpact);
      expect(merged.typeMapping, {
        FeedbackType.success: HapticType.lightImpact,
        FeedbackType.error: HapticType.mediumImpact,
      });
    });

    test('should merge with null returns original', () {
      final config = HapticConfig.defaults();
      final merged = config.merge(null);

      expect(merged, config);
    });

    test('should be equal when values are same', () {
      final config1 = HapticConfig(
        enabled: true,
        defaultType: HapticType.lightImpact,
        typeMapping: {
          FeedbackType.success: HapticType.lightImpact,
        },
      );
      final config2 = HapticConfig(
        enabled: true,
        defaultType: HapticType.lightImpact,
        typeMapping: {
          FeedbackType.success: HapticType.lightImpact,
        },
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should not be equal when values differ', () {
      final config1 = HapticConfig(
        enabled: true,
        defaultType: HapticType.lightImpact,
      );
      final config2 = HapticConfig(
        enabled: false,
        defaultType: HapticType.lightImpact,
      );

      expect(config1, isNot(equals(config2)));
    });
  });
}

