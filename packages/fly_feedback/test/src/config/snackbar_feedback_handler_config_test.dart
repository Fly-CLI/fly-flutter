import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/config/snackbar_feedback_handler_config.dart';

void main() {
  group('SnackbarFeedbackHandlerConfig', () {
    test('should create with all parameters', () {
      final config = SnackbarFeedbackHandlerConfig(
        backgroundColors: {FeedbackType.success: Colors.green},
        icons: {FeedbackType.success: Icons.check},
        iconColors: {FeedbackType.success: Colors.white},
        textColors: {FeedbackType.success: Colors.white},
        defaultDurations: {FeedbackType.success: const Duration(seconds: 5)},
        iconSize: 24.0,
        behavior: SnackBarBehavior.fixed,
      );
      
      expect(config.backgroundColors[FeedbackType.success], equals(Colors.green));
      expect(config.icons[FeedbackType.success], equals(Icons.check));
      expect(config.iconSize, equals(24.0));
      expect(config.behavior, equals(SnackBarBehavior.fixed));
    });

    test('defaults() should create config with defaults', () {
      final config = SnackbarFeedbackHandlerConfig.defaults();
      
      expect(config.icons[FeedbackType.success], equals(Icons.check_circle));
      expect(config.icons[FeedbackType.error], equals(Icons.error_outline));
      expect(config.icons[FeedbackType.warning], equals(Icons.warning_amber));
      expect(config.icons[FeedbackType.info], equals(Icons.info_outline));
      expect(config.iconSize, equals(20.0));
      expect(config.behavior, equals(SnackBarBehavior.floating));
    });

    test('copyWith should create new config with updated values', () {
      final original = SnackbarFeedbackHandlerConfig.defaults();
      final updated = original.copyWith(
        iconSize: 30.0,
        behavior: SnackBarBehavior.fixed,
      );
      
      expect(updated.iconSize, equals(30.0));
      expect(updated.behavior, equals(SnackBarBehavior.fixed));
      expect(updated.icons, equals(original.icons));
    });

    test('getBackgroundColor should return configured color', () {
      final config = SnackbarFeedbackHandlerConfig(
        backgroundColors: {FeedbackType.success: Colors.green},
      );
      final colors = ColorScheme.light();
      
      expect(
        config.getBackgroundColor(FeedbackType.success, colors),
        equals(Colors.green),
      );
    });

    test('getIcon should return configured icon', () {
      final config = SnackbarFeedbackHandlerConfig(
        icons: {FeedbackType.success: Icons.check},
      );
      
      expect(config.getIcon(FeedbackType.success), equals(Icons.check));
    });

    test('getIconColor should return configured color', () {
      final config = SnackbarFeedbackHandlerConfig(
        iconColors: {FeedbackType.success: Colors.white},
      );
      final colors = ColorScheme.light();
      
      expect(
        config.getIconColor(FeedbackType.success, colors),
        equals(Colors.white),
      );
    });

    test('getTextColor should return configured color', () {
      final config = SnackbarFeedbackHandlerConfig(
        textColors: {FeedbackType.success: Colors.white},
      );
      final colors = ColorScheme.light();
      
      expect(
        config.getTextColor(FeedbackType.success, colors),
        equals(Colors.white),
      );
    });

    test('getDefaultDuration should return configured duration', () {
      final config = SnackbarFeedbackHandlerConfig(
        defaultDurations: {FeedbackType.success: const Duration(seconds: 5)},
      );
      
      expect(
        config.getDefaultDuration(FeedbackType.success),
        equals(const Duration(seconds: 5)),
      );
    });
  });
}

