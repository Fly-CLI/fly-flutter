import 'package:fly_feedback/fly_feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_events/fly_events.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppEventEmitter Type-Safe Streams', () {
    late AppEventEmitter emitter;

    setUp(() {
      emitter = AppEventEmitter();
    });

    tearDown(() {
      emitter.dispose();
    });

    group('getStreamFor<T>', () {
      test('should return type-safe navigation stream', () async {
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: EventStreamManager.create<NavigationEvent>(),
        );

        final events = <NavigationEvent>[];
        final subscription = emitter.getStreamFor<NavigationEvent>().listen(events.add);

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        emitter.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, 1);
        expect(events[0], isA<NavigationEvent>());

        subscription.cancel();
      });

      test('should return empty stream when not registered', () {
        final stream = emitter.getStreamFor<NavigationEvent>();

        expect(stream, isNotNull);
        // Should not throw
      });

      test('should return type-safe feedback stream', () async {
        emitter.register<FeedbackAppEvent>(
          key: 'feedback',
          manager: EventStreamManager.create<FeedbackAppEvent>(),
        );

        final events = <FeedbackAppEvent>[];
        final subscription = emitter.getStreamFor<FeedbackAppEvent>().listen(events.add);

        final feedback = SuccessFeedback('Hello');
        emitter.emit(
          FeedbackAppEvent(
            scope: 'TestScope',
            payload: feedback,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, 1);
        expect(events.first.payload, same(feedback));

        await subscription.cancel();
      });

      test('should filter events by type using stream operations', () async {
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: EventStreamManager.create<NavigationEvent>(),
        );

        final startedEvents = <NavigationStartedEvent>[];
        final subscription = emitter
            .getStreamFor<NavigationEvent>()
            .where((event) => event is NavigationStartedEvent)
            .cast<NavigationStartedEvent>()
            .listen(startedEvents.add);

        emitter.emit(NavigationStartedEvent(feature: FeatureScreenType.home));
        emitter.emit(NavigationCompletedEvent(feature: FeatureScreenType.tasks));
        emitter.emit(NavigationStartedEvent(feature: FeatureScreenType.notes));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(startedEvents.length, 2);
        expect(startedEvents, everyElement(isA<NavigationStartedEvent>()));

        subscription.cancel();
      });
    });
  });
}
