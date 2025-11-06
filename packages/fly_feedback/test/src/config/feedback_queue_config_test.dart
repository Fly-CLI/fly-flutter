import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/config/feedback_queue_config.dart';
import 'package:fly_feedback/src/types/feedback_priority.dart';

void main() {
  group('FeedbackQueueConfig', () {
    test('should create with all parameters', () {
      final onItemDropped = (FeedbackEvent event) {};
      final onStaleItemRemoved = (FeedbackEvent event) {};
      final priorityMapping = {
        FeedbackType.success: FeedbackPriority.critical,
      };
      
      final config = FeedbackQueueConfig(
        queueRetryDelay: const Duration(milliseconds: 100),
        maxQueueWait: const Duration(seconds: 10),
        maxQueueSize: 5,
        enablePrioritySorting: false,
        enableDuplicatePrevention: false,
        enableStaleItemRemoval: false,
        enableContextValidation: false,
        priorityMapping: priorityMapping,
        onItemDropped: onItemDropped,
        onStaleItemRemoved: onStaleItemRemoved,
      );
      
      expect(config.queueRetryDelay, equals(const Duration(milliseconds: 100)));
      expect(config.maxQueueWait, equals(const Duration(seconds: 10)));
      expect(config.maxQueueSize, equals(5));
      expect(config.enablePrioritySorting, isFalse);
      expect(config.enableDuplicatePrevention, isFalse);
      expect(config.enableStaleItemRemoval, isFalse);
      expect(config.enableContextValidation, isFalse);
      expect(config.priorityMapping, equals(priorityMapping));
      expect(config.onItemDropped, equals(onItemDropped));
      expect(config.onStaleItemRemoved, equals(onStaleItemRemoved));
    });

    test('defaults() should create config with defaults', () {
      final config = FeedbackQueueConfig.defaults();
      
      expect(config.queueRetryDelay, equals(const Duration(milliseconds: 300)));
      expect(config.maxQueueWait, equals(const Duration(seconds: 5)));
      expect(config.maxQueueSize, equals(10));
      expect(config.enablePrioritySorting, isTrue);
      expect(config.enableDuplicatePrevention, isTrue);
      expect(config.enableStaleItemRemoval, isTrue);
      expect(config.enableContextValidation, isTrue);
    });

    test('copyWith should create new config with updated values', () {
      final original = FeedbackQueueConfig.defaults();
      final updated = original.copyWith(
        maxQueueSize: 20,
        enablePrioritySorting: false,
      );
      
      expect(updated.maxQueueSize, equals(20));
      expect(updated.enablePrioritySorting, isFalse);
      expect(updated.queueRetryDelay, equals(original.queueRetryDelay));
      expect(updated.maxQueueWait, equals(original.maxQueueWait));
    });

    test('merge should merge with another config', () {
      final config1 = FeedbackQueueConfig(
        maxQueueSize: 5,
        enablePrioritySorting: true,
      );
      
      final config2 = FeedbackQueueConfig(
        maxQueueSize: 10,
        enableDuplicatePrevention: false,
      );
      
      final merged = config1.merge(config2);
      
      expect(merged.maxQueueSize, equals(10)); // From config2
      expect(merged.enablePrioritySorting, isTrue); // From config1
      expect(merged.enableDuplicatePrevention, isFalse); // From config2
    });

    test('merge should return original when other is null', () {
      final config = FeedbackQueueConfig.defaults();
      final merged = config.merge(null);
      
      expect(merged, equals(config));
    });

    test('merge should merge priority mappings', () {
      final config1 = FeedbackQueueConfig(
        priorityMapping: {
          FeedbackType.success: FeedbackPriority.critical,
        },
      );
      
      final config2 = FeedbackQueueConfig(
        priorityMapping: {
          FeedbackType.error: FeedbackPriority.high,
        },
      );
      
      final merged = config1.merge(config2);
      
      expect(merged.priorityMapping?.length, equals(2));
      expect(merged.priorityMapping?[FeedbackType.success], equals(FeedbackPriority.critical));
      expect(merged.priorityMapping?[FeedbackType.error], equals(FeedbackPriority.high));
    });

    test('effectiveQueueRetryDelay should return default when null', () {
      final config = FeedbackQueueConfig(queueRetryDelay: null);
      
      expect(
        config.effectiveQueueRetryDelay,
        equals(const Duration(milliseconds: 300)),
      );
    });

    test('effectiveQueueRetryDelay should return value when set', () {
      final config = FeedbackQueueConfig(
        queueRetryDelay: const Duration(milliseconds: 500),
      );
      
      expect(
        config.effectiveQueueRetryDelay,
        equals(const Duration(milliseconds: 500)),
      );
    });

    test('effectiveMaxQueueWait should return default when null', () {
      final config = FeedbackQueueConfig(maxQueueWait: null);
      
      expect(
        config.effectiveMaxQueueWait,
        equals(const Duration(seconds: 5)),
      );
    });

    test('effectiveMaxQueueWait should return value when set', () {
      final config = FeedbackQueueConfig(
        maxQueueWait: const Duration(seconds: 10),
      );
      
      expect(
        config.effectiveMaxQueueWait,
        equals(const Duration(seconds: 10)),
      );
    });

    test('effectiveMaxQueueSize should return default when null', () {
      final config = FeedbackQueueConfig(maxQueueSize: null);
      
      expect(config.effectiveMaxQueueSize, equals(10));
    });

    test('effectiveMaxQueueSize should return value when set', () {
      final config = FeedbackQueueConfig(maxQueueSize: 20);
      
      expect(config.effectiveMaxQueueSize, equals(20));
    });

    test('effectiveEnablePrioritySorting should return default when null', () {
      final config = FeedbackQueueConfig(enablePrioritySorting: null);
      
      expect(config.effectiveEnablePrioritySorting, isTrue);
    });

    test('effectiveEnablePrioritySorting should return value when set', () {
      final config = FeedbackQueueConfig(enablePrioritySorting: false);
      
      expect(config.effectiveEnablePrioritySorting, isFalse);
    });

    test('effectiveEnableDuplicatePrevention should return default when null', () {
      final config = FeedbackQueueConfig(enableDuplicatePrevention: null);
      
      expect(config.effectiveEnableDuplicatePrevention, isTrue);
    });

    test('effectiveEnableDuplicatePrevention should return value when set', () {
      final config = FeedbackQueueConfig(enableDuplicatePrevention: false);
      
      expect(config.effectiveEnableDuplicatePrevention, isFalse);
    });

    test('effectiveEnableStaleItemRemoval should return default when null', () {
      final config = FeedbackQueueConfig(enableStaleItemRemoval: null);
      
      expect(config.effectiveEnableStaleItemRemoval, isTrue);
    });

    test('effectiveEnableStaleItemRemoval should return value when set', () {
      final config = FeedbackQueueConfig(enableStaleItemRemoval: false);
      
      expect(config.effectiveEnableStaleItemRemoval, isFalse);
    });

    test('effectiveEnableContextValidation should return default when null', () {
      final config = FeedbackQueueConfig(enableContextValidation: null);
      
      expect(config.effectiveEnableContextValidation, isTrue);
    });

    test('effectiveEnableContextValidation should return value when set', () {
      final config = FeedbackQueueConfig(enableContextValidation: false);
      
      expect(config.effectiveEnableContextValidation, isFalse);
    });
  });
}

