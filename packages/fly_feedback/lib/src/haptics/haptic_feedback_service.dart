import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fly_feedback/src/haptics/haptic_config.dart';
import 'package:fly_feedback/src/haptics/haptic_types.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Service for triggering haptic feedback
///
/// This service provides a unified interface for triggering haptic feedback
/// across different platforms. It handles platform-specific behavior and
/// provides graceful degradation when haptics are unavailable.
///
/// Example usage:
/// ```dart
/// final service = HapticFeedbackService();
/// service.triggerHaptic(HapticType.lightImpact);
///
/// // Or use with config
/// final config = HapticConfig.defaults();
/// service.triggerHapticForFeedback(FeedbackType.success, config);
/// ```
class HapticFeedbackService {
  /// Create a haptic feedback service
  const HapticFeedbackService();

  /// Trigger haptic feedback of the specified type
  ///
  /// [type] - The type of haptic feedback to trigger
  ///
  /// This method handles platform-specific behavior:
  /// - [HapticType.vibrate] only works on Android
  /// - Other haptic types work on iOS and may work on other platforms
  /// - If haptics are unavailable, this method does nothing (graceful degradation)
  void triggerHaptic(HapticType type) {
    if (type == HapticType.none) {
      return;
    }

    try {
      switch (type) {
        case HapticType.none:
          // Already handled above
          break;
        case HapticType.lightImpact:
          HapticFeedback.lightImpact();
        case HapticType.mediumImpact:
          HapticFeedback.mediumImpact();
        case HapticType.heavyImpact:
          HapticFeedback.heavyImpact();
        case HapticType.selectionClick:
          HapticFeedback.selectionClick();
        case HapticType.vibrate:
          // Vibrate only works on Android
          if (kIsWeb) {
            // Web doesn't support vibration
            return;
          }
          if (Platform.isAndroid) {
            HapticFeedback.vibrate();
          } else {
            // On iOS and other platforms, vibrate may not be available
            // Fall back to medium impact as a reasonable alternative
            HapticFeedback.mediumImpact();
          }
      }
    } catch (e) {
      // Graceful degradation: if haptics fail, just log and continue
      debugPrint('⚠️ Failed to trigger haptic feedback ($type): $e');
    }
  }

  /// Trigger haptic feedback for a specific feedback type using configuration
  ///
  /// [feedbackType] - The feedback type to get haptic for
  /// [config] - The haptic configuration to use
  ///
  /// This method looks up the appropriate haptic type from the configuration
  /// and triggers it. If haptics are disabled in the config, nothing happens.
  void triggerHapticForFeedback(
    FeedbackType feedbackType,
    HapticConfig config,
  ) {
    final hapticType = config.getHapticType(feedbackType);
    triggerHaptic(hapticType);
  }
}

