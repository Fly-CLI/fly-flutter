import 'package:foundation_project/shared/navigation/feature_screen_type.dart';
import 'package:foundation_project/foundation/events/app_event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'events.g.dart';

/// Base class for navigation events
///
/// This is an example-specific event type that uses FeatureScreenType.
/// For generic navigation events, extend AppEvent directly in your application.
sealed class NavigationEvent extends AppEvent {
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