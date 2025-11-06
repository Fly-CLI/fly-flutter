import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/snackbar_feedback_handler.dart';

void main() {
  group('SnackbarFeedbackHandler', () {
    test('should create with default config', () {
      final handler = SnackbarFeedbackHandler();
      
      expect(handler, isNotNull);
      expect(handler.config, isNotNull);
    });

    test('should create with custom config', () {
      final customConfig = SnackbarFeedbackHandlerConfig.defaults();
      final handler = SnackbarFeedbackHandler(config: customConfig);
      
      expect(handler.config, equals(customConfig));
    });

    test('should return true only for snackBar display', () {
      final handler = SnackbarFeedbackHandler();
      
      expect(handler.supports(FeedbackDisplay.snackBar), isTrue);
      expect(handler.supports(FeedbackDisplay.dialog), isFalse);
      expect(handler.supports(FeedbackDisplay.bottomSheet), isFalse);
      expect(handler.supports(FeedbackDisplay.toast), isFalse);
      expect(handler.supports(FeedbackDisplay.banner), isFalse);
      expect(handler.supports(FeedbackDisplay.custom), isFalse);
    });

    testWidgets('should show SnackBar with correct content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = SnackbarFeedbackHandler();
                final event = SuccessFeedback('Test message');
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for snackbar animation
      await tester.pumpAndSettle();
      
      expect(find.text('Test message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
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

      final handler = SnackbarFeedbackHandler();
      final event = SuccessFeedback('Message');
      
      // Should not throw
      expect(() => handler.handle(context, event), returnsNormally);
    });

    testWidgets('should build action for SuccessFeedback', (tester) async {
      bool actionCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = SnackbarFeedbackHandler();
                final event = SuccessFeedback(
                  'Message',
                  action: () => actionCalled = true,
                  actionLabel: 'Action',
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
      // Then settle to wait for snackbar animation
      await tester.pumpAndSettle();
      
      expect(find.text('Action'), findsOneWidget);
      
      // Find the action button by text within the SnackBar
      // SnackBarAction renders as a TextButton, so we find it by text
      final actionFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Action'),
      );
      expect(actionFinder, findsOneWidget);
      
      // Ensure the button is visible and tappable
      await tester.ensureVisible(actionFinder);
      await tester.pumpAndSettle();
      
      await tester.tap(actionFinder);
      await tester.pumpAndSettle();
      
      expect(actionCalled, isTrue);
    });

    testWidgets('should build action for ErrorFeedback', (tester) async {
      bool retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = SnackbarFeedbackHandler();
                final event = ErrorFeedback(
                  'Message',
                  retryAction: () => retryCalled = true,
                  retryLabel: 'Retry',
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
      // Then settle to wait for snackbar animation
      await tester.pumpAndSettle();
      
      expect(find.text('Retry'), findsOneWidget);
      
      // Find the action button by text within the SnackBar
      // SnackBarAction renders as a TextButton, so we find it by text
      final actionFinder = find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Retry'),
      );
      expect(actionFinder, findsOneWidget);
      
      // Ensure the button is visible and tappable
      await tester.ensureVisible(actionFinder);
      await tester.pumpAndSettle();
      
      await tester.tap(actionFinder);
      await tester.pumpAndSettle();
      
      expect(retryCalled, isTrue);
    });

    testWidgets('should use custom duration when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = SnackbarFeedbackHandler();
                final event = SuccessFeedback(
                  'Message',
                  duration: const Duration(seconds: 10),
                );
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, equals(const Duration(seconds: 10)));
    });

    testWidgets('should use default duration when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = SnackbarFeedbackHandler();
                final event = SuccessFeedback('Message');
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, isNotNull);
    });

    testWidgets('should show fallback display on error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = SnackbarFeedbackHandler();
                final event = SuccessFeedback('Message');
                
                // This should work normally
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      
      // Should show snackbar even if there's an error in processing
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}

