import 'package:flutter_test/flutter_test.dart';
import 'package:fly_events/fly_events.dart';
import 'package:foundation_project/core/event_system/events.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:foundation_project/shared/navigation/feature_screen_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppEventEmitter', () {
    late AppEventEmitter emitter;

    setUp(() {
      emitter = AppEventEmitter();
    });

    tearDown(() {
      emitter.dispose();
    });

    group('registration', () {
      test('should register a controller with unique key', () {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        expect(emitter.isRegistered('navigation'), isTrue);
        expect(emitter.registeredKeys, contains('navigation'));
      });

      test('should register a controller using type-safe registration', () {
        emitter.registerType<NavigationEvent>();

        expect(emitter.isTypeRegistered<NavigationEvent>(), isTrue);
        expect(emitter.isRegistered('NavigationEvent'), isTrue);
      });

      test('should throw StateError when registering duplicate key', () {
        final manager1 = EventStreamManager.create<NavigationEvent>();
        final manager2 = EventStreamManager.create<NavigationEvent>();

        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager1,
        );

        expect(
          () => emitter.register<NavigationEvent>(
            key: 'navigation',
            manager: manager2,
          ),
          throwsStateError,
        );
      });

      test('should throw StateError when registering duplicate type', () {
        emitter.registerType<NavigationEvent>();

        expect(
          () => emitter.registerType<NavigationEvent>(),
          throwsStateError,
        );
      });

      test('should throw StateError when registering on disposed emitter', () {
        emitter.dispose();

        final manager = EventStreamManager.create<NavigationEvent>();
        expect(
          () => emitter.register<NavigationEvent>(
            key: 'navigation',
            manager: manager,
          ),
          throwsStateError,
        );
      });
    });

    group('unregister', () {
      test('should unregister a controller by key', () {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final result = emitter.unregister('navigation');

        expect(result, isTrue);
        expect(emitter.isRegistered('navigation'), isFalse);
      });

      test('should unregister a controller by type', () {
        emitter.registerType<NavigationEvent>();

        final result = emitter.unregisterType<NavigationEvent>();

        expect(result, isTrue);
        expect(emitter.isTypeRegistered<NavigationEvent>(), isFalse);
      });

      test('should return false when unregistering non-existent key', () {
        final result = emitter.unregister('nonexistent');

        expect(result, isFalse);
      });

      test('should return false when unregistering non-existent type', () {
        final result = emitter.unregisterType<NavigationEvent>();

        expect(result, isFalse);
      });

      test('should dispose manager when unregistering', () {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        emitter.unregister('navigation');

        expect(manager.isDisposed, isTrue);
      });
    });

    group('getStream', () {
      test('should return stream for registered key', () {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final stream = emitter.getStream('navigation');

        expect(stream, isNotNull);
      });

      test('should return type-safe stream using getStreamFor', () {
        emitter.registerType<NavigationEvent>();

        final stream = emitter.getStreamFor<NavigationEvent>();

        expect(stream, isNotNull);
      });

      test('should return empty stream for unregistered type', () {
        final stream = emitter.getStreamFor<NavigationEvent>();

        expect(stream, isNotNull);
        // Empty stream should not emit any events
        expect(stream.isEmpty, completion(isTrue));
      });

      test('should return null when disposed', () {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        emitter.dispose();

        final stream = emitter.getStream('navigation');

        expect(stream, isNull);
      });

      test('should return empty stream when disposed (type-safe)', () {
        emitter.registerType<NavigationEvent>();
        emitter.dispose();

        final stream = emitter.getStreamFor<NavigationEvent>();

        expect(stream.isEmpty, completion(isTrue));
      });

      test('should throw StateError for non-existent key', () {
        expect(
          () => emitter.getStream('nonexistent'),
          throwsStateError,
        );
      });
    });

    group('emit', () {
      test('should emit event to matching controller', () async {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final events = <AppEvent>[];
        final subscription = emitter.getStream('navigation')?.listen(events.add);

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = emitter.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(result, isTrue);
        expect(events.length, 1);
        expect(events[0], isA<NavigationStartedEvent>());
        expect((events[0] as NavigationStartedEvent).feature, FeatureScreenType.home);

        subscription?.cancel();
      });

      test('should emit event using type-safe stream', () async {
        emitter.registerType<NavigationEvent>();

        final events = <NavigationEvent>[];
        final subscription = emitter.getStreamFor<NavigationEvent>().listen(events.add);

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = emitter.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(result, isTrue);
        expect(events.length, 1);
        expect(events[0], isA<NavigationStartedEvent>());
        expect(events[0].feature, FeatureScreenType.home);

        subscription.cancel();
      });

      test('should match concrete events to base sealed class', () async {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final events = <AppEvent>[];
        final subscription = emitter.getStream('navigation')?.listen(events.add);

        // Emit concrete event (NavigationStartedEvent)
        // Should match base sealed class (NavigationEvent)
        final event = NavigationStartedEvent(feature: FeatureScreenType.tasks);
        emitter.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, 1);
        expect(events[0], isA<NavigationStartedEvent>());

        subscription?.cancel();
      });

      test('should not emit to non-matching controllers', () async {
        final navManager = EventStreamManager.create<NavigationEvent>();
        final screenManager = EventStreamManager.create<ScreenEvent>();

        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: navManager,
        );
        emitter.register<ScreenEvent>(
          key: 'screen',
          manager: screenManager,
        );

        final navEvents = <AppEvent>[];
        final screenEvents = <AppEvent>[];

        final navSubscription =
            emitter.getStream('navigation')?.listen(navEvents.add);
        final screenSubscription = emitter.getStream('screen')?.listen(screenEvents.add);

        final navEvent = NavigationStartedEvent(feature: FeatureScreenType.home);
        emitter.emit(navEvent);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(navEvents.length, 1);
        expect(screenEvents.length, 0);

        navSubscription?.cancel();
        screenSubscription?.cancel();
      });

      test('should emit wrapped feedback events through feedback manager', () async {
        final feedbackManager = EventStreamManager.create<FeedbackAppEvent>();
        emitter.register<FeedbackAppEvent>(
          key: 'feedback',
          manager: feedbackManager,
        );

        final received = <FeedbackAppEvent>[];
        final subscription = emitter
            .getStreamFor<FeedbackAppEvent>()
            .listen(received.add);

        final feedback = SuccessFeedback('Completed');
        final lifecycleEvent = FeedbackAppEvent(
          scope: 'TestScope',
          payload: feedback,
        );

        final emitted = emitter.emit(lifecycleEvent);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(emitted, isTrue);
        expect(received, hasLength(1));
        expect(received.first.payload, same(feedback));
        expect(received.first.scope, 'TestScope');

        await subscription.cancel();
      });

      test('should return false when no matching controller', () {
        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = emitter.emit(event);

        expect(result, isFalse);
      });

      test('should return false when disposed', () {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        emitter.dispose();

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = emitter.emit(event);

        expect(result, isFalse);
      });
    });

    group('dispose', () {
      test('should dispose all controllers', () {
        final manager1 = EventStreamManager.create<NavigationEvent>();
        final manager2 = EventStreamManager.create<ScreenEvent>();

        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager1,
        );
        emitter.register<ScreenEvent>(
          key: 'screen',
          manager: manager2,
        );

        emitter.dispose();

        expect(manager1.isDisposed, isTrue);
        expect(manager2.isDisposed, isTrue);
        expect(emitter.isDisposed, isTrue);
        expect(emitter.registeredKeys, isEmpty);
      });

      test('should be idempotent', () {
        final manager = EventStreamManager.create<NavigationEvent>();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        emitter.dispose();
        emitter.dispose(); // Should not throw

        expect(emitter.isDisposed, isTrue);
      });
    });

    group('registeredKeys', () {
      test('should return list of registered keys', () {
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: EventStreamManager.create<NavigationEvent>(),
        );
        emitter.register<ScreenEvent>(
          key: 'screen',
          manager: EventStreamManager.create<ScreenEvent>(),
        );

        final keys = emitter.registeredKeys;

        expect(keys.length, 2);
        expect(keys, containsAll(['navigation', 'screen']));
      });

      test('should return empty list when no controllers registered', () {
        expect(emitter.registeredKeys, isEmpty);
      });
    });

    group('isRegistered', () {
      test('should return true for registered key', () {
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: EventStreamManager.create<NavigationEvent>(),
        );

        expect(emitter.isRegistered('navigation'), isTrue);
      });

      test('should return false for non-registered key', () {
        expect(emitter.isRegistered('nonexistent'), isFalse);
      });
    });

    group('isTypeRegistered', () {
      test('should return true for registered type', () {
        emitter.registerType<NavigationEvent>();

        expect(emitter.isTypeRegistered<NavigationEvent>(), isTrue);
      });

      test('should return false for non-registered type', () {
        expect(emitter.isTypeRegistered<NavigationEvent>(), isFalse);
      });
    });
  });
}
