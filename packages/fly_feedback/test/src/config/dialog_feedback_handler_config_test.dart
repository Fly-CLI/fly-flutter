import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/config/dialog_feedback_handler_config.dart';
import 'package:fly_feedback/src/config/feedback_queue_config.dart';

void main() {
  group('DialogFeedbackHandlerConfig', () {
    test('should create with all parameters', () {
      final queueConfig = FeedbackQueueConfig.defaults();
      final config = DialogFeedbackHandlerConfig(
        queueConfig: queueConfig,
      );
      
      expect(config.queueConfig, equals(queueConfig));
    });

    test('defaults() should create config with defaults', () {
      final config = DialogFeedbackHandlerConfig.defaults();
      
      expect(config.queueConfig, isNotNull);
      expect(config.queueConfig, isA<FeedbackQueueConfig>());
    });

    test('copyWith should create new config with updated values', () {
      final original = DialogFeedbackHandlerConfig.defaults();
      final newQueueConfig = FeedbackQueueConfig(maxQueueSize: 5);
      final updated = original.copyWith(
        queueConfig: newQueueConfig,
      );
      
      expect(updated.queueConfig, equals(newQueueConfig));
      expect(updated.queueConfig?.maxQueueSize, equals(5));
    });

    test('merge should merge queue configs', () {
      final config1 = DialogFeedbackHandlerConfig(
        queueConfig: FeedbackQueueConfig(maxQueueSize: 5),
      );
      
      final config2 = DialogFeedbackHandlerConfig(
        queueConfig: FeedbackQueueConfig(maxQueueSize: 10),
      );
      
      final merged = config1.merge(config2);
      
      expect(merged.queueConfig?.maxQueueSize, equals(10));
    });
  });
}

