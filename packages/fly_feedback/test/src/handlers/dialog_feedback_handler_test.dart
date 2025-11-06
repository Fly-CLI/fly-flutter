import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/dialog_feedback_handler.dart';

void main() {
  group('DialogFeedbackHandler', () {
    test('should create with default config', () {
      final handler = DialogFeedbackHandler();
      
      expect(handler, isNotNull);
      expect(handler.config, isNotNull);
    });

    test('should create with custom config', () {
      final customConfig = DialogFeedbackHandlerConfig.defaults();
      final handler = DialogFeedbackHandler(config: customConfig);
      
      expect(handler.config, equals(customConfig));
    });

    test('should return true only for dialog display', () {
      final handler = DialogFeedbackHandler();
      
      expect(handler.supports(FeedbackDisplay.dialog), isTrue);
      expect(handler.supports(FeedbackDisplay.snackBar), isFalse);
      expect(handler.supports(FeedbackDisplay.bottomSheet), isFalse);
      expect(handler.supports(FeedbackDisplay.toast), isFalse);
      expect(handler.supports(FeedbackDisplay.banner), isFalse);
      expect(handler.supports(FeedbackDisplay.custom), isFalse);
    });

    testWidgets('should show dialog immediately when not showing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = DialogFeedbackHandler();
                final event = SuccessFeedback('Message', display: FeedbackDisplay.dialog);
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for dialog animation
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
    });

    testWidgets('should queue when dialog already showing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = DialogFeedbackHandler();
                final event1 = SuccessFeedback('Message 1', display: FeedbackDisplay.dialog);
                final event2 = SuccessFeedback('Message 2', display: FeedbackDisplay.dialog);
                
                handler.handle(context, event1);
                // Immediately try to show another dialog
                handler.handle(context, event2);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callbacks
      await tester.pump();
      // Then settle to wait for dialog animation
      await tester.pumpAndSettle();
      
      // Should show first dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Message 1'), findsOneWidget);
      
      // Close first dialog - find close icon within the dialog
      final closeButton = find.descendant(
        of: find.byType(AlertDialog).first,
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      
      // Should show second dialog from queue
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog for ConfirmationFeedback', (tester) async {
      bool confirmCalled = false;
      bool cancelCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = DialogFeedbackHandler();
                final event = ConfirmationFeedback(
                  title: 'Title',
                  message: 'Message',
                  confirmLabel: 'Confirm',
                  cancelLabel: 'Cancel',
                  onConfirm: () => confirmCalled = true,
                  onCancel: () => cancelCalled = true,
                );
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for dialog animation
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      
      // Test confirm button
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      
      expect(confirmCalled, isTrue);
    });

    testWidgets('should show alert dialog for other feedback types', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = DialogFeedbackHandler();
                final event = SuccessFeedback('Message', display: FeedbackDisplay.dialog);
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for dialog animation
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
    });

    testWidgets('should process queue after dialog closes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = DialogFeedbackHandler();
                final event1 = SuccessFeedback('Message 1', display: FeedbackDisplay.dialog);
                final event2 = SuccessFeedback('Message 2', display: FeedbackDisplay.dialog);
                
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
      // Then settle to wait for dialog animation
      await tester.pumpAndSettle();
      
      // First dialog should be showing
      expect(find.text('Message 1'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      
      // Close first dialog - find close icon within the dialog
      final closeButton = find.descendant(
        of: find.byType(AlertDialog).first,
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      
      // Second dialog should be showing from queue
      expect(find.text('Message 2'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
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

      final handler = DialogFeedbackHandler();
      final event = SuccessFeedback('Message', display: FeedbackDisplay.dialog);
      
      // Should not throw
      expect(() => handler.handle(context, event), returnsNormally);
    });

    testWidgets('should handle dangerous confirmation dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = DialogFeedbackHandler();
                final event = ConfirmationFeedback(
                  title: 'Delete',
                  message: 'Are you sure?',
                  confirmLabel: 'Delete',
                  isDangerous: true,
                );
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for dialog animation
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete'), findsNWidgets(2)); // Title and button
    });

    testWidgets('should respect barrierDismissible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = DialogFeedbackHandler();
                final event = ConfirmationFeedback(
                  title: 'Title',
                  message: 'Message',
                  barrierDismissible: false,
                );
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for dialog animation
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}

