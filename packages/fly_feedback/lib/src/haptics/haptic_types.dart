/// Haptic feedback types supported by the feedback system
///
/// These types map to Flutter's built-in [HapticFeedback] class methods.
/// Not all haptic types are available on all platforms.
enum HapticType {
  /// No haptic feedback
  none,

  /// Light haptic feedback
  ///
  /// Provides a subtle tactile response, suitable for positive actions
  /// like success messages.
  lightImpact,

  /// Medium haptic feedback
  ///
  /// Provides a moderate tactile response, suitable for important
  /// feedback like errors.
  mediumImpact,

  /// Heavy haptic feedback
  ///
  /// Provides a strong tactile response, suitable for critical
  /// feedback or important confirmations.
  heavyImpact,

  /// Selection click feedback
  ///
  /// Provides a minimal tactile response, suitable for informational
  /// feedback or selection actions.
  selectionClick,

  /// Platform vibration
  ///
  /// Provides platform-specific vibration. On Android, this triggers
  /// the system vibration. On iOS and other platforms, this may have
  /// no effect or fall back to another haptic type.
  vibrate,
}

