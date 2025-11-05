import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/navigation_stream_manager.dart';
import 'package:foundation_project/core/lifecycle/managers/screen_stream_manager.dart';
import 'package:foundation_project/core/navigation/fly_router.dart';

void main() {
  group('AppLifecycleEmitter', () {
    late AppLifecycleEmitter emitter;

    setUp(() {
      emitter = AppLifecycleEmitter();
    });

    tearDown(() {
      emitter.dispose();
    });

    group('registration', () {
      test('should register a controller with unique key', () {
        final manager = NavigationStreamManager();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        expect(emitter.isRegistered('navigation'), isTrue);
        expect(emitter.registeredKeys, contains('navigation'));
      });

      test('should throw StateError when registering duplicate key', () {
        final manager1 = NavigationStreamManager();
        final manager2 = NavigationStreamManager();

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

      test('should throw StateError when registering on disposed emitter', () {
        emitter.dispose();

        final manager = NavigationStreamManager();
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
        final manager = NavigationStreamManager();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final result = emitter.unregister('navigation');

        expect(result, isTrue);
        expect(emitter.isRegistered('navigation'), isFalse);
      });

      test('should return false when unregistering non-existent key', () {
        final result = emitter.unregister('nonexistent');

        expect(result, isFalse);
      });

      test('should dispose manager when unregistering', () {
        final manager = NavigationStreamManager();
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
        final manager = NavigationStreamManager();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final stream = emitter.getStream('navigation');

        expect(stream, isNotNull);
      });

      test('should return null when disposed', () {
        final manager = NavigationStreamManager();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        emitter.dispose();

        final stream = emitter.getStream('navigation');

        expect(stream, isNull);
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
        final manager = NavigationStreamManager();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final events = <LifecycleEvent>[];
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

      test('should match concrete events to base sealed class', () async {
        final manager = NavigationStreamManager();
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: manager,
        );

        final events = <LifecycleEvent>[];
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
        final navManager = NavigationStreamManager();
        final screenManager = ScreenStreamManager();

        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: navManager,
        );
        emitter.register<ScreenEvent>(
          key: 'screen',
          manager: screenManager,
        );

        final navEvents = <LifecycleEvent>[];
        final screenEvents = <LifecycleEvent>[];

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

      test('should return false when no matching controller', () {
        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        final result = emitter.emit(event);

        expect(result, isFalse);
      });

      test('should return false when disposed', () {
        final manager = NavigationStreamManager();
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
        final manager1 = NavigationStreamManager();
        final manager2 = ScreenStreamManager();

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
        final manager = NavigationStreamManager();
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
          manager: NavigationStreamManager(),
        );
        emitter.register<ScreenEvent>(
          key: 'screen',
          manager: ScreenStreamManager(),
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
          manager: NavigationStreamManager(),
        );

        expect(emitter.isRegistered('navigation'), isTrue);
      });

      test('should return false for non-registered key', () {
        expect(emitter.isRegistered('nonexistent'), isFalse);
      });
    });
  });
}
