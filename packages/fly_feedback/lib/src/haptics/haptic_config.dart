import 'package:flutter/foundation.dart';
import 'package:fly_feedback/src/haptics/haptic_types.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

/// Configuration for haptic feedback behavior
///
/// This class allows configuring haptic feedback globally and per feedback type.
/// Haptic feedback can be enabled or disabled, and different haptic types can
/// be assigned to different feedback types.
///
/// Example usage:
/// ```dart
/// final hapticConfig = HapticConfig(
///   enabled: true,
///   defaultType: HapticType.lightImpact,
///   typeMapping: {
///     FeedbackType.success: HapticType.lightImpact,
///     FeedbackType.error: HapticType.mediumImpact,
///     FeedbackType.warning: HapticType.lightImpact,
///     FeedbackType.info: HapticType.selectionClick,
///   },
/// );
/// ```
class HapticConfig {
  /// Whether haptic feedback is enabled globally
  final bool enabled;

  /// Default haptic type to use when no specific mapping is provided
  final HapticType defaultType;

  /// Mapping of feedback types to haptic types
  ///
  /// If a feedback type is not in this map, [defaultType] will be used.
  final Map<FeedbackType, HapticType> typeMapping;

  /// Create a haptic configuration
  const HapticConfig({
    this.enabled = true,
    this.defaultType = HapticType.lightImpact,
    this.typeMapping = const {},
  });

  /// Create a haptic configuration with default mappings
  ///
  /// Default mappings:
  /// - [FeedbackType.success]: [HapticType.lightImpact]
  /// - [FeedbackType.error]: [HapticType.mediumImpact]
  /// - [FeedbackType.warning]: [HapticType.lightImpact]
  /// - [FeedbackType.info]: [HapticType.selectionClick]
  factory HapticConfig.defaults() {
    return const HapticConfig(
      enabled: true,
      defaultType: HapticType.lightImpact,
      typeMapping: {
        FeedbackType.success: HapticType.lightImpact,
        FeedbackType.error: HapticType.mediumImpact,
        FeedbackType.warning: HapticType.lightImpact,
        FeedbackType.info: HapticType.selectionClick,
      },
    );
  }

  /// Create a haptic configuration with haptics disabled
  factory HapticConfig.disabled() {
    return const HapticConfig(
      enabled: false,
      defaultType: HapticType.none,
      typeMapping: {},
    );
  }

  /// Get the haptic type for a specific feedback type
  ///
  /// Returns the mapped haptic type if available, otherwise returns
  /// [defaultType]. If haptics are disabled, returns [HapticType.none].
  HapticType getHapticType(FeedbackType feedbackType) {
    if (!enabled) {
      return HapticType.none;
    }

    return typeMapping[feedbackType] ?? defaultType;
  }

  /// Create a copy of this configuration with updated values
  HapticConfig copyWith({
    bool? enabled,
    HapticType? defaultType,
    Map<FeedbackType, HapticType>? typeMapping,
  }) {
    return HapticConfig(
      enabled: enabled ?? this.enabled,
      defaultType: defaultType ?? this.defaultType,
      typeMapping: typeMapping ?? this.typeMapping,
    );
  }

  /// Merge this configuration with another
  ///
  /// Values from [other] take precedence over this configuration's values.
  HapticConfig merge(HapticConfig? other) {
    if (other == null) return this;

    return HapticConfig(
      enabled: other.enabled,
      defaultType: other.defaultType,
      typeMapping: {...typeMapping, ...other.typeMapping},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HapticConfig &&
        other.enabled == enabled &&
        other.defaultType == defaultType &&
        mapEquals(other.typeMapping, typeMapping);
  }

  @override
  int get hashCode {
    // Compute hash code from map entries in a consistent order
    // Sort entries by key to ensure consistent hash codes
    final sortedEntries = typeMapping.entries.toList()
      ..sort((a, b) => a.key.name.compareTo(b.key.name));
    final mapHash = sortedEntries
        .map((e) => Object.hash(e.key, e.value))
        .fold(0, (a, b) => a ^ b);
    return Object.hash(enabled, defaultType, mapHash);
  }

  @override
  String toString() {
    return 'HapticConfig(enabled: $enabled, defaultType: $defaultType, '
        'typeMapping: $typeMapping)';
  }
}

