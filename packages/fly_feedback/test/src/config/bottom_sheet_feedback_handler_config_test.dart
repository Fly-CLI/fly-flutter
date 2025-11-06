import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/config/bottom_sheet_feedback_handler_config.dart';
import 'package:fly_feedback/src/config/feedback_queue_config.dart';

void main() {
  group('BottomSheetFeedbackHandlerConfig', () {
    test('should create with all parameters', () {
      final queueConfig = FeedbackQueueConfig.defaults();
      final config = BottomSheetFeedbackHandlerConfig(
        iconSize: 24.0,
        borderRadius: 16.0,
        contentPadding: const EdgeInsets.all(16),
        queueConfig: queueConfig,
      );
      
      expect(config.iconSize, equals(24.0));
      expect(config.borderRadius, equals(16.0));
      expect(config.contentPadding, equals(const EdgeInsets.all(16)));
      expect(config.queueConfig, equals(queueConfig));
    });

    test('defaults() should create config with defaults', () {
      final config = BottomSheetFeedbackHandlerConfig.defaults();
      
      expect(config, isNotNull);
      expect(config.queueConfig, isNotNull);
    });

    test('copyWith should create new config with updated values', () {
      final original = BottomSheetFeedbackHandlerConfig.defaults();
      final updated = original.copyWith(
        iconSize: 30.0,
        borderRadius: 20.0,
      );
      
      expect(updated.iconSize, equals(30.0));
      expect(updated.borderRadius, equals(20.0));
    });
  });
}

