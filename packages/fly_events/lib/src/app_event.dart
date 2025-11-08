// Import here so we can use FeedbackEvent in the wrapper
import 'package:fly_feedback/fly_feedback.dart' as feedback;
import 'package:json_annotation/json_annotation.dart';

part 'app_event.g.dart';

// Feedback events originate from the fly_feedback package and are wrapped
// inside app events to participate in the shared AppEventEmitter.

/// Base app event - pure data, no logic
///
/// All app events extend this abstract class and provide
/// information about component events in the application.
abstract class AppEvent {
  /// Unique identifier for this event
  final String id;

  /// Timestamp when the event occurred
  final DateTime timestamp;

  /// Additional metadata for the event
  final Map<String, dynamic> metadata;

  AppEvent({
    String? id,
    DateTime? timestamp,
    this.metadata = const {},
  })  : id = id ?? generateId(),
        timestamp = timestamp ?? DateTime.now();

  /// Generate a unique ID for the event
  static String generateId() {
    return 'app_event_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
  }

  static int _idCounter = 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Base class for screen events
abstract class ScreenEvent extends AppEvent {
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
abstract class FoundationOperationEvent extends AppEvent {
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

/// Convert Duration to JSON (milliseconds)
int _durationToJson(Duration duration) => duration.inMilliseconds;

/// Convert JSON (milliseconds) to Duration
Duration _durationFromJson(int json) => Duration(milliseconds: json);

/// App event that wraps a Fly feedback payload.
///
/// Allows feedback events to move through the shared application event
/// emitter so that listeners can handle them alongside other app events.
class FeedbackAppEvent extends AppEvent {
  FeedbackAppEvent({
    required this.scope,
    required this.payload,
    super.id,
    super.timestamp,
    super.metadata = const {},
  });

  /// Identifier used to route feedback to the appropriate listener.
  final String scope;

  /// The original feedback payload emitted by the producer (e.g., ViewModel).
  final feedback.FeedbackEvent payload;
}

