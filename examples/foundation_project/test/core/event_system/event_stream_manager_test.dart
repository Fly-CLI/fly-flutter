import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/core/event_system/managers/event_stream_manager.dart';
import 'package:foundation_project/core/navigation/fly_router.dart';

void main() {
  group('EventStreamManager', () {
    late EventStreamManager<NavigationEvent> manager;

    setUp(() {
      manager = EventStreamManager.create<NavigationEvent>();
    });

    tearDown(() {
      manager.dispose();
    });

    group('stream', () {
      test('should return broadcast stream', () {
        final stream = manager.stream;

        expect(stream, isNotNull);
        expect(stream.isBroadcast, isTrue);
      });

      test('should support multiple listeners', () async {
        final events1 = <NavigationEvent>[];
        final events2 = <NavigationEvent>[];

        final subscription1 = manager.stream.listen(events1.add);
        final subscription2 = manager.stream.listen(events2.add);

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        manager.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events1.length, 1);
        expect(events2.length, 1);

        subscription1.cancel();
        subscription2.cancel();
      });

      test('should return empty stream when disposed', () {
        manager.dispose();

        final stream = manager.stream;

        expect(stream, isNotNull);
        // Should not throw when accessed
      });
    });

    group('emit', () {
      test('should emit event to stream', () async {
        final events = <NavigationEvent>[];
        manager.stream.listen(events.add).cancel();

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = manager.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(result, isTrue);
        expect(events.length, 1);
        expect(events[0], equals(event));
      });

      test('should return false when no listeners', () {
        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = manager.emit(event);

        // No listeners, so should return false
        expect(result, isFalse);
      });

      test('should return false when disposed', () {
        manager.dispose();

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = manager.emit(event);

        expect(result, isFalse);
      });

      test('should handle errors gracefully', () async {
        final events = <NavigationEvent>[];
        final errors = <dynamic>[];

        manager.stream.listen(
          events.add,
          onError: errors.add,
        ).cancel();

        // Emit valid event
        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        manager.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, 1);
        expect(errors.length, 0);
      });
    });

    group('dispose', () {
      test('should close stream controller', () {
        final subscription = manager.stream.listen((_) {});

        manager.dispose();

        expect(manager.isDisposed, isTrue);
        // Should not throw when subscription is cancelled after dispose
        subscription.cancel();
      });

      test('should be idempotent', () {
        manager.dispose();
        manager.dispose(); // Should not throw

        expect(manager.isDisposed, isTrue);
      });

      test('should prevent further emissions after dispose', () async {
        final events = <NavigationEvent>[];
        final subscription = manager.stream.listen(events.add);

        final event1 = NavigationStartedEvent(feature: FeatureScreenType.home);
        manager.emit(event1);

        await Future.delayed(const Duration(milliseconds: 10));

        manager.dispose();

        final event2 = NavigationStartedEvent(feature: FeatureScreenType.tasks);
        manager.emit(event2);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, 1); // Only first event should be received

        subscription.cancel();
      });
    });

    group('isDisposed', () {
      test('should return false when not disposed', () {
        expect(manager.isDisposed, isFalse);
      });

      test('should return true when disposed', () {
        manager.dispose();

        expect(manager.isDisposed, isTrue);
      });
    });
  });
}
