import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/config/toast_feedback_handler_config.dart';

void main() {
  group('ToastFeedbackHandlerConfig', () {
    test('should create with all parameters', () {
      final config = ToastFeedbackHandlerConfig(
        iconSize: 24.0,
        topOffset: 50.0,
        horizontalPadding: 16.0,
        verticalPadding: 12.0,
        borderRadius: 8.0,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        slideBeginOffset: const Offset(0, -1),
        shadowColor: Colors.black,
        shadowBlurRadius: 4.0,
        shadowOffset: const Offset(0, 2),
        fontSize: 14.0,
      );
      
      expect(config.iconSize, equals(24.0));
      expect(config.topOffset, equals(50.0));
      expect(config.horizontalPadding, equals(16.0));
      expect(config.verticalPadding, equals(12.0));
      expect(config.borderRadius, equals(8.0));
      expect(config.animationDuration, equals(const Duration(milliseconds: 300)));
      expect(config.animationCurve, equals(Curves.easeInOut));
      expect(config.slideBeginOffset, equals(const Offset(0, -1)));
      expect(config.shadowColor, equals(Colors.black));
      expect(config.shadowBlurRadius, equals(4.0));
      expect(config.shadowOffset, equals(const Offset(0, 2)));
      expect(config.fontSize, equals(14.0));
    });

    test('defaults() should create config with defaults', () {
      final config = ToastFeedbackHandlerConfig.defaults();
      
      expect(config, isNotNull);
      expect(config.icons[FeedbackType.success], equals(Icons.check_circle));
    });

    test('copyWith should create new config with updated values', () {
      final original = ToastFeedbackHandlerConfig.defaults();
      final updated = original.copyWith(
        iconSize: 30.0,
        topOffset: 100.0,
      );
      
      expect(updated.iconSize, equals(30.0));
      expect(updated.topOffset, equals(100.0));
    });
  });
}

