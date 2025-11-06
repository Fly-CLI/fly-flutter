import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/toast_feedback_handler.dart';

void main() {
  group('ToastFeedbackHandler', () {
    test('should create with default config', () {
      final handler = ToastFeedbackHandler();
      
      expect(handler, isNotNull);
      expect(handler.config, isNotNull);
    });

    test('should return true only for toast display', () {
      final handler = ToastFeedbackHandler();
      
      expect(handler.supports(FeedbackDisplay.toast), isTrue);
      expect(handler.supports(FeedbackDisplay.snackBar), isFalse);
      expect(handler.supports(FeedbackDisplay.dialog), isFalse);
      expect(handler.supports(FeedbackDisplay.bottomSheet), isFalse);
      expect(handler.supports(FeedbackDisplay.banner), isFalse);
      expect(handler.supports(FeedbackDisplay.custom), isFalse);
    });

    testWidgets('should display toast correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = ToastFeedbackHandler();
                final event = SuccessFeedback('Message', display: FeedbackDisplay.toast);
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for toast animation
      await tester.pumpAndSettle();
      
      // Toast should be displayed (implementation may vary)
      expect(find.text('Message'), findsOneWidget);
      
      // Timer will be cancelled when the widget is disposed, so no need to wait
    });

    testWidgets('should handle invalid context gracefully', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Remove widget to invalidate context
      await tester.pumpWidget(const SizedBox());

      final handler = ToastFeedbackHandler();
      final event = SuccessFeedback('Message', display: FeedbackDisplay.toast);
      
      // Should not throw
      expect(() => handler.handle(context, event), returnsNormally);
    });
  });
}

