import 'package:flutter/foundation.dart';

/// Simplified crashlytics manager for foundation project
/// In production, this would integrate with Firebase Crashlytics
class CrashlyticsManager {
  static final CrashlyticsManager instance = CrashlyticsManager._();
  CrashlyticsManager._();

  void recordErrorWithCustomKeys(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, String>? customKeys,
  }) {
    // In production, this would send to Crashlytics
    // For foundation project, we just log to console
    debugPrint('Crashlytics: $reason');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    if (customKeys != null) {
      debugPrint('Custom keys: $customKeys');
    }
  }
}

