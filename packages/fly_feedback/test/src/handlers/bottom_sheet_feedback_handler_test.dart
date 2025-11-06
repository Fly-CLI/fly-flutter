import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/bottom_sheet_feedback_handler.dart';

void main() {
  group('BottomSheetFeedbackHandler', () {
    test('should create with default config', () {
      final handler = BottomSheetFeedbackHandler();
      
      expect(handler, isNotNull);
      expect(handler.config, isNotNull);
    });

    test('should return true only for bottomSheet display', () {
      final handler = BottomSheetFeedbackHandler();
      
      expect(handler.supports(FeedbackDisplay.bottomSheet), isTrue);
      expect(handler.supports(FeedbackDisplay.snackBar), isFalse);
      expect(handler.supports(FeedbackDisplay.dialog), isFalse);
      expect(handler.supports(FeedbackDisplay.toast), isFalse);
      expect(handler.supports(FeedbackDisplay.banner), isFalse);
      expect(handler.supports(FeedbackDisplay.custom), isFalse);
    });

    testWidgets('should show bottom sheet immediately when not showing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = BottomSheetFeedbackHandler();
                final event = SuccessFeedback('Message', display: FeedbackDisplay.bottomSheet);
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for bottom sheet animation
      await tester.pumpAndSettle();
      
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
    });

    testWidgets('should queue when bottom sheet already showing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = BottomSheetFeedbackHandler();
                final event1 = SuccessFeedback('Message 1', display: FeedbackDisplay.bottomSheet);
                final event2 = SuccessFeedback('Message 2', display: FeedbackDisplay.bottomSheet);
                
                handler.handle(context, event1);
                // Immediately try to show another bottom sheet
                handler.handle(context, event2);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callbacks
      await tester.pump();
      // Then settle to wait for bottom sheet animation
      await tester.pumpAndSettle();
      
      // Should show first bottom sheet
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      
      // Close first bottom sheet - use close icon button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      
      // Should show second bottom sheet from queue
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
    });

    testWidgets('should process queue after bottom sheet closes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = BottomSheetFeedbackHandler();
                final event1 = SuccessFeedback('Message 1', display: FeedbackDisplay.bottomSheet);
                final event2 = SuccessFeedback('Message 2', display: FeedbackDisplay.bottomSheet);
                
                handler.handle(context, event1);
                handler.handle(context, event2);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callbacks
      await tester.pump();
      // Then settle to wait for bottom sheet animation
      await tester.pumpAndSettle();
      
      // First bottom sheet should be showing
      expect(find.text('Message 1'), findsOneWidget);
      
      // Close first bottom sheet - use close icon button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      
      // Second bottom sheet should be showing from queue
      expect(find.text('Message 2'), findsOneWidget);
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

      final handler = BottomSheetFeedbackHandler();
      final event = SuccessFeedback('Message', display: FeedbackDisplay.bottomSheet);
      
      // Should not throw
      expect(() => handler.handle(context, event), returnsNormally);
    });
  });
}

