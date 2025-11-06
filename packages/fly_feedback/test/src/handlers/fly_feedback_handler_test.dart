import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/fly_feedback_handler.dart';

void main() {
  group('FeedbackHandlerMixin', () {
    testWidgets('should return true for valid mounted context', (tester) async {
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

      // Create a test handler that uses the mixin
      final handler = _TestHandler();
      
      // Access the protected method through a public method
      expect(handler.testIsValidContext(context), isTrue);
    });

    testWidgets('should return false for unmounted context', (tester) async {
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

      // Remove widget to unmount context
      await tester.pumpWidget(const SizedBox());

      final handler = _TestHandler();
      
      // Context should be invalid after unmounting
      expect(handler.testIsValidContext(context), isFalse);
    });
  });
}

/// Test handler that uses FeedbackHandlerMixin
class _TestHandler with FeedbackHandlerMixin implements FlyFeedbackHandler {
  @override
  bool supports(FeedbackDisplay display) => true;

  @override
  void handle(BuildContext context, FeedbackEvent event) {
    // Not used in tests
  }

  /// Expose protected method for testing
  bool testIsValidContext(BuildContext context) {
    return isValidContext(context);
  }
}

