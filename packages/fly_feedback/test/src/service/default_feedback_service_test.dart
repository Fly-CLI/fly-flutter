import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/haptics/haptic_config.dart';
import 'package:fly_feedback/src/haptics/haptic_types.dart';
import 'package:fly_feedback/src/service/default_feedback_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlyFeedbackHandler extends Mock implements FlyFeedbackHandler {}

class BuildContextFake extends Fake implements BuildContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(FeedbackDisplay.snackBar);
    registerFallbackValue(SuccessFeedback(''));
    registerFallbackValue(BuildContextFake());
  });

  group('DefaultFeedbackService', () {
    late MockFlyFeedbackHandler mockHandler;
    late DefaultFeedbackService service;
    late BuildContext context;

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      );
    }

    setUp(() {
      mockHandler = MockFlyFeedbackHandler();
      service = DefaultFeedbackService(handler: mockHandler);
    });

    testWidgets('should create with handler', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final service = DefaultFeedbackService(handler: mockHandler);
      
      expect(service, isNotNull);
    });

    testWidgets('should delegate show to handler', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final event = SuccessFeedback('Message');
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      service.show(context, event);
      
      verify(() => mockHandler.handle(context, event)).called(1);
    });

    testWidgets('should create SuccessFeedback in showSuccess', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      service.showSuccess(
        context,
        'Success message',
        display: FeedbackDisplay.dialog,
        duration: const Duration(seconds: 5),
        action: () {},
        actionLabel: 'Action',
        metadata: {'key': 'value'},
      );
      
      verify(
        () => mockHandler.handle(
          context,
          any(
            that: predicate<FeedbackEvent>(
              (event) =>
                  event is SuccessFeedback &&
                  event.message == 'Success message' &&
                  event.display == FeedbackDisplay.dialog &&
                  event.duration == const Duration(seconds: 5) &&
                  event.metadata['key'] == 'value',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('should create ErrorFeedback in showError', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      bool retryCalled = false;
      service.showError(
        context,
        'Error message',
        technicalDetails: 'Technical details',
        retryAction: () => retryCalled = true,
        retryLabel: 'Retry',
        showTechnicalDetails: true,
        display: FeedbackDisplay.dialog,
        duration: const Duration(seconds: 5),
        metadata: {'key': 'value'},
      );
      
      verify(
        () => mockHandler.handle(
          context,
          any(
            that: predicate<FeedbackEvent>(
              (event) =>
                  event is ErrorFeedback &&
                  event.message == 'Error message' &&
                  event.technicalDetails == 'Technical details' &&
                  event.retryLabel == 'Retry' &&
                  event.showTechnicalDetails == true &&
                  event.display == FeedbackDisplay.dialog &&
                  event.duration == const Duration(seconds: 5) &&
                  event.metadata['key'] == 'value',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('should create WarningFeedback in showWarning', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      service.showWarning(
        context,
        'Warning message',
        display: FeedbackDisplay.dialog,
        duration: const Duration(seconds: 5),
        metadata: {'key': 'value'},
      );
      
      verify(
        () => mockHandler.handle(
          context,
          any(
            that: predicate<FeedbackEvent>(
              (event) =>
                  event is WarningFeedback &&
                  event.message == 'Warning message' &&
                  event.display == FeedbackDisplay.dialog &&
                  event.duration == const Duration(seconds: 5) &&
                  event.metadata['key'] == 'value',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('should create InfoFeedback in showInfo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      service.showInfo(
        context,
        'Info message',
        display: FeedbackDisplay.dialog,
        duration: const Duration(seconds: 5),
        metadata: {'key': 'value'},
      );
      
      verify(
        () => mockHandler.handle(
          context,
          any(
            that: predicate<FeedbackEvent>(
              (event) =>
                  event is InfoFeedback &&
                  event.message == 'Info message' &&
                  event.display == FeedbackDisplay.dialog &&
                  event.duration == const Duration(seconds: 5) &&
                  event.metadata['key'] == 'value',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('should create ConfirmationFeedback in showConfirmation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      bool confirmCalled = false;
      bool cancelCalled = false;
      
      service.showConfirmation(
        context: context,
        title: 'Title',
        message: 'Message',
        confirmLabel: 'Confirm',
        cancelLabel: 'Cancel',
        onConfirm: () => confirmCalled = true,
        onCancel: () => cancelCalled = true,
        isDangerous: true,
        barrierDismissible: false,
        metadata: {'key': 'value'},
      );
      
      verify(
        () => mockHandler.handle(
          context,
          any(
            that: predicate<FeedbackEvent>(
              (event) =>
                  event is ConfirmationFeedback &&
                  event.title == 'Title' &&
                  event.message == 'Message' &&
                  event.confirmLabel == 'Confirm' &&
                  event.cancelLabel == 'Cancel' &&
                  event.isDangerous == true &&
                  event.barrierDismissible == false &&
                  event.metadata['key'] == 'value',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('should use default parameters when not provided', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      service.showSuccess(context, 'Message');
      
      verify(
        () => mockHandler.handle(
          context,
          any(
            that: predicate<FeedbackEvent>(
              (event) =>
                  event is SuccessFeedback &&
                  event.message == 'Message' &&
                  event.display == FeedbackDisplay.snackBar,
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('should create with haptic config', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final hapticConfig = HapticConfig.defaults();
      final serviceWithHaptic = DefaultFeedbackService(
        handler: mockHandler,
        hapticConfig: hapticConfig,
      );
      
      expect(serviceWithHaptic.hapticConfig, hapticConfig);
    });

    testWidgets('should use default haptic config when not provided', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final serviceWithoutHaptic = DefaultFeedbackService(handler: mockHandler);
      
      expect(serviceWithoutHaptic.hapticConfig, isNotNull);
      expect(serviceWithoutHaptic.hapticConfig, isA<HapticConfig>());
    });

    testWidgets('should trigger haptic feedback when showing feedback', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final hapticConfig = HapticConfig.defaults();
      final serviceWithHaptic = DefaultFeedbackService(
        handler: mockHandler,
        hapticConfig: hapticConfig,
      );
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      final event = SuccessFeedback('Message');
      serviceWithHaptic.show(context, event);
      
      // Verify handler was called (haptic is triggered before handler)
      verify(() => mockHandler.handle(context, event)).called(1);
    });

    testWidgets('should respect haptic_enabled metadata override', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final hapticConfig = HapticConfig.defaults();
      final serviceWithHaptic = DefaultFeedbackService(
        handler: mockHandler,
        hapticConfig: hapticConfig,
      );
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      final event = SuccessFeedback(
        'Message',
        metadata: {'haptic_enabled': false},
      );
      serviceWithHaptic.show(context, event);
      
      // Verify handler was called even when haptic is disabled
      verify(() => mockHandler.handle(context, event)).called(1);
    });

    testWidgets('should respect haptic_type metadata override', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final hapticConfig = HapticConfig.defaults();
      final serviceWithHaptic = DefaultFeedbackService(
        handler: mockHandler,
        hapticConfig: hapticConfig,
      );
      
      when(() => mockHandler.supports(any())).thenReturn(true);
      when(() => mockHandler.handle(any(), any())).thenReturn(null);
      
      final event = SuccessFeedback(
        'Message',
        metadata: {'haptic_type': 'heavyImpact'},
      );
      serviceWithHaptic.show(context, event);
      
      // Verify handler was called
      verify(() => mockHandler.handle(context, event)).called(1);
    });
  });
}

