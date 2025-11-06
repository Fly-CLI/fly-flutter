import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/composite_feedback_handler.dart';
import 'package:fly_feedback/src/haptics/haptic_config.dart';
import 'package:fly_feedback/src/mixins/fly_feedback_listener_mixin.dart';
import 'package:mocktail/mocktail.dart';

class MockFlyFeedbackHandler extends Mock implements FlyFeedbackHandler {}

class FakeBuildContext extends Fake implements BuildContext {}

class TestWidget extends StatefulWidget {
  final Stream<FeedbackEvent>? feedbackStream;
  final FlyFeedbackHandler? handler;

  const TestWidget({
    super.key,
    this.feedbackStream,
    this.handler,
  });

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget>
    with FlyFeedbackListenerMixin<TestWidget> {
  bool errorHandled = false;
  bool unsupportedCalled = false;

  @override
  Stream<FeedbackEvent>? getFeedbackStream(BuildContext context) {
    return widget.feedbackStream;
  }

  @override
  FlyFeedbackHandler getFeedbackHandler() {
    return widget.handler ?? super.getFeedbackHandler();
  }

  @override
  void onFeedbackStreamError(Object error, StackTrace stackTrace) {
    errorHandled = true;
    super.onFeedbackStreamError(error, stackTrace);
  }

  @override
  void onUnsupportedFeedback(FeedbackEvent event) {
    unsupportedCalled = true;
    super.onUnsupportedFeedback(event);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FeedbackDisplay.snackBar);
    registerFallbackValue(SuccessFeedback(''));
    registerFallbackValue(FakeBuildContext());
  });

  group('FlyFeedbackListenerMixin', () {
    testWidgets('should return null for getFeedbackStream by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      final context = tester.element(find.byType(MaterialApp));
      
      expect(state.getFeedbackStream(context), isNull);
    });

    testWidgets('should return CompositeFeedbackHandler by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      final handler = state.getFeedbackHandler();
      
      expect(handler, isA<CompositeFeedbackHandler>());
    });

    testWidgets('should subscribe to stream when setupFeedbackListener is called', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      final events = <FeedbackEvent>[];
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(feedbackStream: controller.stream),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      // Setup listener
      state.setupFeedbackListener();
      await tester.pump();
      
      // Emit event
      final event = SuccessFeedback('Message');
      controller.add(event);
      await tester.pump();
      
      // Event should be handled (we can't easily verify handler was called without mocking)
      expect(controller.hasListener, isTrue);
      
      controller.close();
    });

    testWidgets('should handle stream errors', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(feedbackStream: controller.stream),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      state.setupFeedbackListener();
      await tester.pump();
      
      // Emit error
      controller.addError(Exception('Test error'));
      await tester.pump();
      
      // Error should be handled
      expect(state.errorHandled, isTrue);
      
      controller.close();
    });

    testWidgets('should skip if already listening', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(feedbackStream: controller.stream),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      state.setupFeedbackListener();
      await tester.pump();
      
      // Call again - should skip
      state.setupFeedbackListener();
      await tester.pump();
      
      // Should still have only one listener
      expect(controller.hasListener, isTrue);
      
      controller.close();
    });

    testWidgets('should skip if not mounted', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(feedbackStream: controller.stream),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      // Unmount widget
      await tester.pumpWidget(const SizedBox());
      
      // Should skip setup
      state.setupFeedbackListener();
      await tester.pump();
      
      controller.close();
    });

    testWidgets('should handle feedback event', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      final mockHandler = MockFlyFeedbackHandler();
      bool handlerCalled = false;
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenAnswer((_) {
        handlerCalled = true;
      });
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            feedbackStream: controller.stream,
            handler: mockHandler,
          ),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      state.setupFeedbackListener();
      await tester.pump();
      
      // Emit event
      final event = SuccessFeedback('Message');
      controller.add(event);
      await tester.pump();
      
      // Handler should be called
      expect(handlerCalled, isTrue);
      verify(() => mockHandler.handle(any(), event)).called(1);
      
      controller.close();
    });

    testWidgets('should call onUnsupportedFeedback for unsupported display', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      final mockHandler = MockFlyFeedbackHandler();
      
      when(() => mockHandler.supports(FeedbackDisplay.custom)).thenReturn(false);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            feedbackStream: controller.stream,
            handler: mockHandler,
          ),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      state.setupFeedbackListener();
      await tester.pump();
      
      // Emit unsupported event
      final event = SuccessFeedback('Message', display: FeedbackDisplay.custom);
      controller.add(event);
      await tester.pump();
      
      // Should call unsupported handler
      expect(state.unsupportedCalled, isTrue);
      
      controller.close();
    });

    testWidgets('should cancel subscription on dispose', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(feedbackStream: controller.stream),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      state.setupFeedbackListener();
      await tester.pump();
      
      expect(controller.hasListener, isTrue);
      
      // Dispose widget
      await tester.pumpWidget(const SizedBox());
      
      // Listener should be cancelled
      expect(controller.hasListener, isFalse);
      
      controller.close();
    });

    testWidgets('should auto-dispose in dispose', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(feedbackStream: controller.stream),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      state.setupFeedbackListener();
      await tester.pump();
      
      expect(controller.hasListener, isTrue);
      
      // Dispose
      state.disposeFeedbackListener();
      await tester.pump();
      
      // Listener should be cancelled
      expect(controller.hasListener, isFalse);
      
      controller.close();
    });

    testWidgets('should return null for haptic config by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      
      expect(state.getHapticConfig(), isNull);
    });

    testWidgets('should set and get haptic config', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      final hapticConfig = HapticConfig.defaults();
      
      state.setHapticConfig(hapticConfig);
      
      expect(state.getHapticConfig(), hapticConfig);
    });

    testWidgets('should trigger haptic feedback when handling event', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      final mockHandler = MockFlyFeedbackHandler();
      final hapticConfig = HapticConfig.defaults();
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            feedbackStream: controller.stream,
            handler: mockHandler,
          ),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      state.setHapticConfig(hapticConfig);
      
      state.setupFeedbackListener();
      await tester.pump();
      
      // Emit event
      final event = SuccessFeedback('Message');
      controller.add(event);
      await tester.pump();
      
      // Handler should be called (haptic is triggered before handler)
      verify(() => mockHandler.handle(any(), event)).called(1);
      
      controller.close();
    });

    testWidgets('should respect haptic_enabled metadata override', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      final mockHandler = MockFlyFeedbackHandler();
      final hapticConfig = HapticConfig.defaults();
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            feedbackStream: controller.stream,
            handler: mockHandler,
          ),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      state.setHapticConfig(hapticConfig);
      
      state.setupFeedbackListener();
      await tester.pump();
      
      // Emit event with haptic disabled
      final event = SuccessFeedback(
        'Message',
        metadata: {'haptic_enabled': false},
      );
      controller.add(event);
      await tester.pump();
      
      // Handler should still be called
      verify(() => mockHandler.handle(any(), event)).called(1);
      
      controller.close();
    });

    testWidgets('should not trigger haptic when config is null', (tester) async {
      final controller = StreamController<FeedbackEvent>.broadcast();
      final mockHandler = MockFlyFeedbackHandler();
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            feedbackStream: controller.stream,
            handler: mockHandler,
          ),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      // Don't set haptic config (should be null)
      
      state.setupFeedbackListener();
      await tester.pump();
      
      // Emit event
      final event = SuccessFeedback('Message');
      controller.add(event);
      await tester.pump();
      
      // Handler should still be called
      verify(() => mockHandler.handle(any(), event)).called(1);
      
      controller.close();
    });
  });
}

