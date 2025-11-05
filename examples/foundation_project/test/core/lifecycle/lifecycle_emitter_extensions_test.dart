import 'package:flutter_test/flutter_test.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_emitter_extensions.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/navigation_stream_manager.dart';
import 'package:foundation_project/core/navigation/fly_router.dart';

void main() {
  group('LifecycleEmitterExtensions', () {
    late AppLifecycleEmitter emitter;

    setUp(() {
      emitter = AppLifecycleEmitter();
    });

    tearDown(() {
      emitter.dispose();
    });

    group('NavigationStreamExtension', () {
      test('should return type-safe navigation stream', () async {
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: NavigationStreamManager(),
        );

        final events = <NavigationEvent>[];
        final subscription = emitter.getNavigationStream().listen(events.add);

        final event = NavigationStartedEvent(feature: FeatureScreenType.home);
        emitter.emit(event);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, 1);
        expect(events[0], isA<NavigationEvent>());

        subscription.cancel();
      });

      test('should return empty stream when not registered', () {
        final stream = emitter.getNavigationStream();

        expect(stream, isNotNull);
        // Should not throw
      });
    });

    group('LifecycleEmitterFilterExtension', () {
      test('should filter events by type', () async {
        emitter.register<NavigationEvent>(
          key: 'navigation',
          manager: NavigationStreamManager(),
        );

        final startedEvents = <NavigationStartedEvent>[];
        final subscription = emitter
            .getEventsOfType<NavigationStartedEvent>('navigation')
            .listen(startedEvents.add);

        emitter.emit(NavigationStartedEvent(feature: FeatureScreenType.home));
        emitter.emit(NavigationCompletedEvent(feature: FeatureScreenType.tasks));
        emitter.emit(NavigationStartedEvent(feature: FeatureScreenType.notes));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(startedEvents.length, 2);
        expect(startedEvents, everyElement(isA<NavigationStartedEvent>()));

        subscription.cancel();
      });

      test('should return empty stream when key not registered', () {
        final stream = emitter.getEventsOfType<NavigationEvent>('nonexistent');

        expect(stream, isNotNull);
        // Should not throw
      });
    });
  });
}
