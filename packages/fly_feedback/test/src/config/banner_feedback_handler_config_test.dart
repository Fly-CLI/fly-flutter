import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/config/banner_feedback_handler_config.dart';

void main() {
  group('BannerFeedbackHandlerConfig', () {
    test('should create with all parameters', () {
      final config = BannerFeedbackHandlerConfig(
        iconSize: 24.0,
        leadingPadding: const EdgeInsets.only(left: 20),
        padding: const EdgeInsets.all(16),
      );
      
      expect(config.iconSize, equals(24.0));
      expect(config.leadingPadding, equals(const EdgeInsets.only(left: 20)));
      expect(config.padding, equals(const EdgeInsets.all(16)));
    });

    test('defaults() should create config with defaults', () {
      final config = BannerFeedbackHandlerConfig.defaults();
      
      expect(config.iconSize, equals(24.0));
      expect(config.leadingPadding, equals(const EdgeInsets.only(left: 16)));
      expect(config.padding, equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)));
    });

    test('copyWith should create new config with updated values', () {
      final original = BannerFeedbackHandlerConfig.defaults();
      final updated = original.copyWith(
        iconSize: 30.0,
        padding: const EdgeInsets.all(20),
      );
      
      expect(updated.iconSize, equals(30.0));
      expect(updated.padding, equals(const EdgeInsets.all(20)));
    });
  });
}

