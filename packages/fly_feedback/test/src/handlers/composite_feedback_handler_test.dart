import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/composite_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/snackbar_feedback_handler.dart';
import 'package:mocktail/mocktail.dart';

class MockFlyFeedbackHandler extends Mock implements FlyFeedbackHandler {}

class BuildContextFake extends Fake implements BuildContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(FeedbackDisplay.snackBar);
    registerFallbackValue(SuccessFeedback(''));
    registerFallbackValue(BuildContextFake());
  });

  group('CompositeFeedbackHandler', () {
    late BuildContext context;
    late MockFlyFeedbackHandler handler1;
    late MockFlyFeedbackHandler handler2;
    late SnackbarFeedbackHandler snackbarHandler;

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
      handler1 = MockFlyFeedbackHandler();
      handler2 = MockFlyFeedbackHandler();
      snackbarHandler = SnackbarFeedbackHandler();
    });

    testWidgets('should create with handlers list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final composite = CompositeFeedbackHandler([handler1, handler2]);
      
      expect(composite, isNotNull);
    });

    testWidgets('should return true if any handler supports display', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => handler1.supports(FeedbackDisplay.snackBar)).thenReturn(false);
      when(() => handler2.supports(FeedbackDisplay.snackBar)).thenReturn(true);
      
      final composite = CompositeFeedbackHandler([handler1, handler2]);
      
      expect(composite.supports(FeedbackDisplay.snackBar), isTrue);
    });

    testWidgets('should return false if no handler supports display', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => handler1.supports(FeedbackDisplay.dialog)).thenReturn(false);
      when(() => handler2.supports(FeedbackDisplay.dialog)).thenReturn(false);
      
      final composite = CompositeFeedbackHandler([handler1, handler2]);
      
      expect(composite.supports(FeedbackDisplay.dialog), isFalse);
    });

    testWidgets('should delegate to first supporting handler', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => handler1.supports(FeedbackDisplay.snackBar)).thenReturn(false);
      when(() => handler2.supports(FeedbackDisplay.snackBar)).thenReturn(true);
      when(() => handler2.handle(any(), any())).thenReturn(null);
      
      final composite = CompositeFeedbackHandler([handler1, handler2]);
      final event = SuccessFeedback('Message', display: FeedbackDisplay.snackBar);
      
      composite.handle(context, event);
      
      verify(() => handler1.supports(FeedbackDisplay.snackBar)).called(1);
      verify(() => handler2.supports(FeedbackDisplay.snackBar)).called(1);
      verify(() => handler2.handle(context, event)).called(1);
      verifyNever(() => handler1.handle(any(), any()));
    });

    testWidgets('should fall back to SnackbarHandler on error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => handler1.supports(FeedbackDisplay.dialog)).thenReturn(true);
      when(() => handler1.handle(any(), any())).thenThrow(Exception('Error'));
      
      final composite = CompositeFeedbackHandler([handler1, snackbarHandler]);
      final event = SuccessFeedback('Message', display: FeedbackDisplay.dialog);
      
      // Should not throw, should fall back to snackbar
      expect(() => composite.handle(context, event), returnsNormally);
      
      verify(() => handler1.handle(context, event)).called(1);
    });

    testWidgets('should throw when no handler supports display type', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => handler1.supports(FeedbackDisplay.custom)).thenReturn(false);
      when(() => handler2.supports(FeedbackDisplay.custom)).thenReturn(false);
      
      final composite = CompositeFeedbackHandler([handler1, handler2]);
      final event = SuccessFeedback('Message', display: FeedbackDisplay.custom);
      
      expect(
        () => composite.handle(context, event),
        throwsA(isA<UnsupportedError>()),
      );
    });

    testWidgets('should throw when no fallback handler available', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      when(() => handler1.supports(FeedbackDisplay.dialog)).thenReturn(true);
      when(() => handler1.handle(any(), any())).thenThrow(Exception('Error'));
      
      final composite = CompositeFeedbackHandler([handler1]);
      final event = SuccessFeedback('Message', display: FeedbackDisplay.dialog);
      
      expect(
        () => composite.handle(context, event),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

