import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/foundation/events/app_event.dart';

void main() {
  group('AppEvent', () {
    test('should generate unique IDs', () {
      final event1 = ScreenShownEvent(screenName: 'Test');
      final event2 = ScreenShownEvent(screenName: 'Test');
      expect(event1.id, isNot(equals(event2.id)));
    });

    test('should use provided ID when given', () {
      final event = ScreenShownEvent(
        screenName: 'Test',
        id: 'custom-id',
      );
      expect(event.id, equals('custom-id'));
    });

    test('should use current timestamp by default', () {
      final before = DateTime.now();
      final event = ScreenShownEvent(screenName: 'Test');
      final after = DateTime.now();
      expect(event.timestamp.isAfter(before) || event.timestamp.isAtSameMomentAs(before), isTrue);
      expect(event.timestamp.isBefore(after) || event.timestamp.isAtSameMomentAs(after), isTrue);
    });

    test('should use provided timestamp when given', () {
      final timestamp = DateTime(2024, 1, 1);
      final event = ScreenShownEvent(
        screenName: 'Test',
        timestamp: timestamp,
      );
      expect(event.timestamp, equals(timestamp));
    });

    test('should store metadata', () {
      final event = ScreenShownEvent(
        screenName: 'Test',
        metadata: {'key': 'value'},
      );
      expect(event.metadata['key'], equals('value'));
    });

    test('should be equal when IDs match', () {
      final event1 = ScreenShownEvent(screenName: 'Test', id: 'same-id');
      final event2 = ScreenShownEvent(screenName: 'Test', id: 'same-id');
      expect(event1, equals(event2));
    });

    test('should not be equal when IDs differ', () {
      final event1 = ScreenShownEvent(screenName: 'Test');
      final event2 = ScreenShownEvent(screenName: 'Test');
      expect(event1, isNot(equals(event2)));
    });
  });

  group('ScreenEvent', () {
    test('should store screen name', () {
      final event = ScreenShownEvent(screenName: 'HomeScreen');
      expect(event.screenName, equals('HomeScreen'));
    });
  });

  group('ScreenShownEvent', () {
    test('should create event with screen name', () {
      final event = ScreenShownEvent(screenName: 'TestScreen');
      expect(event.screenName, equals('TestScreen'));
      expect(event, isA<ScreenEvent>());
      expect(event, isA<AppEvent>());
    });
  });

  group('ScreenHiddenEvent', () {
    test('should create event with screen name', () {
      final event = ScreenHiddenEvent(screenName: 'TestScreen');
      expect(event.screenName, equals('TestScreen'));
      expect(event, isA<ScreenEvent>());
      expect(event, isA<AppEvent>());
    });
  });
}

