import 'package:flutter/foundation.dart';
import 'package:foundation_project/core/foundation/feedback/types/feedback_types.dart';
import 'package:foundation_project/core/navigation/fly_router.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lifecycle_events.g.dart';

// Feedback events - must be in this library to extend LifecycleEvent
// Note: FeedbackType and FeedbackDisplay enums are in feedback_types.dart

/// Base lifecycle event - pure data, no logic
///
/// All lifecycle events extend this sealed class and provide
/// information about component lifecycle events in the application.
sealed class LifecycleEvent {
  /// Unique identifier for this event
  final String id;

  /// Timestamp when the event occurred
  final DateTime timestamp;

  /// Additional metadata for the event
  final Map<String, dynamic> metadata;

  LifecycleEvent({
    String? id,
    DateTime? timestamp,
    this.metadata = const {},
  })  : id = id ?? generateId(),
        timestamp = timestamp ?? DateTime.now();

  /// Generate a unique ID for the event
  static String generateId() {
    return 'lifecycle_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
  }

  static int _idCounter = 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifecycleEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Base class for navigation events
sealed class NavigationEvent extends LifecycleEvent {
  @JsonKey(fromJson: _featureFromJson, toJson: _featureToJson)
  final FeatureScreenType feature;

  NavigationEvent({
    required this.feature,
    super.id,
    super.timestamp,
    super.metadata,
  });
}

/// Event emitted when navigation to a feature starts
@JsonSerializable()
class NavigationStartedEvent extends NavigationEvent {
  NavigationStartedEvent({
    required super.feature,
    super.id,
    super.timestamp,
    super.metadata,
  });

  factory NavigationStartedEvent.fromJson(Map<String, dynamic> json) =>
      _$NavigationStartedEventFromJson(json);

  Map<String, dynamic> toJson() => _$NavigationStartedEventToJson(this);
}

/// Event emitted when navigation to a feature completes
@JsonSerializable()
class NavigationCompletedEvent extends NavigationEvent {
  /// Optional result from the navigation
  final dynamic result;

  NavigationCompletedEvent({
    required super.feature,
    this.result,
    super.id,
    super.timestamp,
    super.metadata,
  });

  factory NavigationCompletedEvent.fromJson(Map<String, dynamic> json) =>
      _$NavigationCompletedEventFromJson(json);

  Map<String, dynamic> toJson() => _$NavigationCompletedEventToJson(this);
}

/// Base class for screen events
sealed class ScreenEvent extends LifecycleEvent {
  final String screenName;

  ScreenEvent({
    required this.screenName,
    super.id,
    super.timestamp,
    super.metadata,
  });
}

/// Event emitted when a screen is shown
@JsonSerializable()
class ScreenShownEvent extends ScreenEvent {
  ScreenShownEvent({
    required super.screenName,
    super.id,
    super.timestamp,
    super.metadata,
  });

  factory ScreenShownEvent.fromJson(Map<String, dynamic> json) =>
      _$ScreenShownEventFromJson(json);

  Map<String, dynamic> toJson() => _$ScreenShownEventToJson(this);
}

/// Event emitted when a screen is hidden
@JsonSerializable()
class ScreenHiddenEvent extends ScreenEvent {
  ScreenHiddenEvent({
    required super.screenName,
    super.id,
    super.timestamp,
    super.metadata,
  });

  factory ScreenHiddenEvent.fromJson(Map<String, dynamic> json) =>
      _$ScreenHiddenEventFromJson(json);

  Map<String, dynamic> toJson() => _$ScreenHiddenEventToJson(this);
}

/// Base class for foundation operation events
sealed class FoundationOperationEvent extends LifecycleEvent {
  final String operationId;
  final String operationName;

  FoundationOperationEvent({
    required this.operationId,
    required this.operationName,
    super.id,
    super.timestamp,
    super.metadata,
  });
}

/// Event emitted when an async operation starts
@JsonSerializable()
class AsyncOperationStartedEvent extends FoundationOperationEvent {
  AsyncOperationStartedEvent({
    required super.operationId,
    required super.operationName,
    super.id,
    super.timestamp,
    super.metadata,
  });

  factory AsyncOperationStartedEvent.fromJson(Map<String, dynamic> json) =>
      _$AsyncOperationStartedEventFromJson(json);

  Map<String, dynamic> toJson() => _$AsyncOperationStartedEventToJson(this);
}

/// Event emitted when an async operation completes successfully
@JsonSerializable()
class AsyncOperationCompletedEvent extends FoundationOperationEvent {
  final bool success;
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration duration;

  AsyncOperationCompletedEvent({
    required super.operationId,
    required super.operationName,
    required this.success,
    required this.duration,
    super.id,
    super.timestamp,
    super.metadata,
  });

  factory AsyncOperationCompletedEvent.fromJson(Map<String, dynamic> json) =>
      _$AsyncOperationCompletedEventFromJson(json);

  Map<String, dynamic> toJson() => _$AsyncOperationCompletedEventToJson(this);
}

/// Event emitted when an async operation fails
@JsonSerializable()
class AsyncOperationFailedEvent extends FoundationOperationEvent {
  final String error;
  @JsonKey(fromJson: _durationFromJson, toJson: _durationToJson)
  final Duration duration;

  AsyncOperationFailedEvent({
    required super.operationId,
    required super.operationName,
    required this.error,
    required this.duration,
    super.id,
    super.timestamp,
    super.metadata,
  });

  factory AsyncOperationFailedEvent.fromJson(Map<String, dynamic> json) =>
      _$AsyncOperationFailedEventFromJson(json);

  Map<String, dynamic> toJson() => _$AsyncOperationFailedEventToJson(this);
}

// Helper functions for JSON serialization

/// Convert Feature enum to JSON string
String _featureToJson(FeatureScreenType feature) => feature.name;

/// Convert JSON string to Feature enum
FeatureScreenType _featureFromJson(String json) {
  try {
    return FeatureScreenType.values.firstWhere((f) => f.name == json);
  } catch (e) {
    return FeatureScreenType.home; // Default fallback
  }
}

/// Convert Duration to JSON (milliseconds)
int _durationToJson(Duration duration) => duration.inMilliseconds;

/// Convert JSON (milliseconds) to Duration
Duration _durationFromJson(int json) => Duration(milliseconds: json);

// ============================================================================
// Feedback Events
// ============================================================================

/// Base feedback event - pure data, no logic
/// Extends LifecycleEvent to integrate with the lifecycle system
///
/// This class is abstract (not sealed) to allow custom feedback types
/// to be created in other libraries, enabling the generic FeedbackService<F>
/// pattern to work with custom feedback implementations.
abstract class FeedbackEvent extends LifecycleEvent {
  final String message; // Already localized string from ViewModel
  final FeedbackType type;
  final FeedbackDisplay display;
  final Duration? duration;
  final String? title; // Optional title for dialog display - user provides localization
  final String? okLabel; // Optional OK button label for alert dialogs - user provides localization

  FeedbackEvent({
    super.id, // Inherited from LifecycleEvent
    required this.message,
    required this.type,
    this.display = FeedbackDisplay.snackBar,
    this.duration,
    this.title, // Optional - user provides if they want dialog title
    this.okLabel, // Optional - user provides if they want OK button with text
    super.timestamp, // Inherited from LifecycleEvent
    super.metadata = const {}, // Inherited from LifecycleEvent
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Success feedback
class SuccessFeedback extends FeedbackEvent {
  final VoidCallback? action;
  final String? actionLabel;

  SuccessFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackBar,
    super.duration,
    this.action,
    this.actionLabel,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.success,
        );
}

/// Error feedback
class ErrorFeedback extends FeedbackEvent {
  final String? technicalDetails;
  final VoidCallback? retryAction;
  final String? retryLabel; // Optional - user provides localization
  final bool showTechnicalDetails; // Control detail visibility

  ErrorFeedback(
    String message, {
    super.id,
    this.technicalDetails,
    this.retryAction,
    this.retryLabel, // Optional - user must provide if they want retry button with text
    this.showTechnicalDetails = false, // Hidden by default
    super.display = FeedbackDisplay.snackBar,
    super.duration,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.error,
        );
}

/// Warning feedback
class WarningFeedback extends FeedbackEvent {
  WarningFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackBar,
    super.duration,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.warning,
        );
}

/// Info feedback
class InfoFeedback extends FeedbackEvent {
  InfoFeedback(
    String message, {
    super.id,
    super.display = FeedbackDisplay.snackBar,
    super.duration,
    super.timestamp,
    super.metadata = const {},
  }) : super(
          message: message,
          type: FeedbackType.info,
        );
}

/// Confirmation dialog feedback
class ConfirmationFeedback extends FeedbackEvent {
  final String? confirmLabel; // Optional - user provides localization
  final String? cancelLabel; // Optional - user provides localization
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDangerous;
  final bool barrierDismissible; // Control dialog dismissal

  ConfirmationFeedback({
    super.id,
    required String title, // Title is required for confirmation dialogs
    required super.message,
    this.confirmLabel, // Optional - user must provide if they want button text
    this.cancelLabel, // Optional - user must provide if they want button text
    this.onConfirm,
    this.onCancel,
    this.isDangerous = false,
    this.barrierDismissible = true, // Default dismissible
    super.timestamp,
    super.metadata = const {},
  }) : super(
          type: FeedbackType.info,
          display: FeedbackDisplay.dialog,
          title: title, // Pass title to base class
        );
}

