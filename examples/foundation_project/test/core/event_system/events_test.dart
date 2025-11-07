import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/foundation/events/app_event.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

void main() {
  group('AppEvent', () {
    test('should generate unique IDs', () {
      final event1 = NavigationStartedEvent(feature: FeatureScreenType.home);
      final event2 = NavigationStartedEvent(feature: FeatureScreenType.home);

      expect(event1.id, isNot(equals(event2.id)));
    });

    test('should set timestamp to current time', () {
      final before = DateTime.now();
      final event = NavigationStartedEvent(feature: FeatureScreenType.home);
      final after = DateTime.now();

      expect(
        event.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        event.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('should allow custom timestamp', () {
      final customTimestamp = DateTime(2024, 1, 1);
      final event = NavigationStartedEvent(
        feature: FeatureScreenType.home,
        timestamp: customTimestamp,
      );

      expect(event.timestamp, equals(customTimestamp));
    });

    test('should allow custom metadata', () {
      final metadata = {'key': 'value'};
      final event = NavigationStartedEvent(
        feature: FeatureScreenType.home,
        metadata: metadata,
      );

      expect(event.metadata, equals(metadata));
    });

    test('should be equal based on ID', () {
      const id = 'test-id';
      final event1 = NavigationStartedEvent(
        feature: FeatureScreenType.home,
        id: id,
      );
      final event2 = NavigationStartedEvent(
        feature: FeatureScreenType.tasks,
        id: id,
      );

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });
  });

  group('NavigationStartedEvent', () {
    test('should create with feature', () {
      final event = NavigationStartedEvent(feature: FeatureScreenType.home);

      expect(event.feature, FeatureScreenType.home);
      expect(event, isA<NavigationEvent>());
      expect(event, isA<AppEvent>());
    });

    test('should support JSON serialization', () {
      final event = NavigationStartedEvent(
        feature: FeatureScreenType.tasks,
        metadata: {'key': 'value'},
      );

      final json = event.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], isNotNull);
      expect(json['timestamp'], isNotNull);
      expect(json['feature'], 'tasks');
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });

    test('should deserialize from JSON', () {
      final original = NavigationStartedEvent(
        feature: FeatureScreenType.notes,
        metadata: {'key': 'value'},
      );

      final json = original.toJson();
      final deserialized = NavigationStartedEvent.fromJson(json);

      expect(deserialized.feature, FeatureScreenType.notes);
      expect(deserialized.metadata, equals(original.metadata));
    });
  });

  group('NavigationCompletedEvent', () {
    test('should create with feature and optional result', () {
      final event = NavigationCompletedEvent(
        feature: FeatureScreenType.home,
        result: 'test-result',
      );

      expect(event.feature, FeatureScreenType.home);
      expect(event.result, 'test-result');
    });

    test('should support JSON serialization', () {
      final event = NavigationCompletedEvent(
        feature: FeatureScreenType.tasks,
        result: 'result',
      );

      final json = event.toJson();

      expect(json['feature'], 'tasks');
      expect(json['result'], 'result');
    });
  });

  group('ScreenShownEvent', () {
    test('should create with screen name', () {
      final event = ScreenShownEvent(screenName: 'home');

      expect(event.screenName, 'home');
      expect(event, isA<ScreenEvent>());
      expect(event, isA<AppEvent>());
    });

    test('should support JSON serialization', () {
      final event = ScreenShownEvent(
        screenName: 'home',
        metadata: {'key': 'value'},
      );

      final json = event.toJson();

      expect(json['screenName'], 'home');
      expect(json['metadata'], isA<Map<String, dynamic>>());
    });
  });

  group('ScreenHiddenEvent', () {
    test('should create with screen name', () {
      final event = ScreenHiddenEvent(screenName: 'home');

      expect(event.screenName, 'home');
      expect(event, isA<ScreenEvent>());
    });
  });
}
