import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/banner_feedback_handler.dart';

void main() {
  group('BannerFeedbackHandler', () {
    test('should create with default config', () {
      final handler = BannerFeedbackHandler();
      
      expect(handler, isNotNull);
      expect(handler.config, isNotNull);
    });

    test('should return true only for banner display', () {
      final handler = BannerFeedbackHandler();
      
      expect(handler.supports(FeedbackDisplay.banner), isTrue);
      expect(handler.supports(FeedbackDisplay.snackBar), isFalse);
      expect(handler.supports(FeedbackDisplay.dialog), isFalse);
      expect(handler.supports(FeedbackDisplay.bottomSheet), isFalse);
      expect(handler.supports(FeedbackDisplay.toast), isFalse);
      expect(handler.supports(FeedbackDisplay.custom), isFalse);
    });

    testWidgets('should display banner correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final handler = BannerFeedbackHandler();
                final event = SuccessFeedback('Message', display: FeedbackDisplay.banner);
                handler.handle(context, event);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Pump once to trigger post-frame callback
      await tester.pump();
      // Then settle to wait for banner animation
      await tester.pumpAndSettle();
      
      // Banner should be displayed
      expect(find.text('Message'), findsOneWidget);
      expect(find.byType(MaterialBanner), findsOneWidget);
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

      final handler = BannerFeedbackHandler();
      final event = SuccessFeedback('Message', display: FeedbackDisplay.banner);
      
      // Should not throw
      expect(() => handler.handle(context, event), returnsNormally);
    });
  });
}

