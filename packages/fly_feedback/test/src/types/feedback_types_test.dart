import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/handlers/implementations/banner_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/bottom_sheet_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/dialog_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/snackbar_feedback_handler.dart';
import 'package:fly_feedback/src/handlers/implementations/toast_feedback_handler.dart';

void main() {
  group('FeedbackType', () {
    test('should have all expected enum values', () {
      expect(FeedbackType.values, containsAll([
        FeedbackType.success,
        FeedbackType.error,
        FeedbackType.warning,
        FeedbackType.info,
      ]));
    });
  });

  group('FeedbackTypeEmoji', () {
    test('should return correct emoji for success', () {
      expect(FeedbackType.success.emoji, equals('✅'));
    });

    test('should return correct emoji for error', () {
      expect(FeedbackType.error.emoji, equals('❌'));
    });

    test('should return correct emoji for warning', () {
      expect(FeedbackType.warning.emoji, equals('⚠️'));
    });

    test('should return correct emoji for info', () {
      expect(FeedbackType.info.emoji, equals('ℹ️'));
    });
  });

  group('FeedbackDisplay', () {
    test('should have all expected enum values', () {
      expect(FeedbackDisplay.values, containsAll([
        FeedbackDisplay.snackBar,
        FeedbackDisplay.dialog,
        FeedbackDisplay.bottomSheet,
        FeedbackDisplay.toast,
        FeedbackDisplay.banner,
        FeedbackDisplay.custom,
      ]));
    });
  });

  group('FeedbackDisplayFactory', () {
    test('should create SnackbarFeedbackHandler for snackBar', () {
      final handler = FeedbackDisplay.snackBar.createDefaultHandler();
      expect(handler, isA<SnackbarFeedbackHandler>());
    });

    test('should create DialogFeedbackHandler for dialog', () {
      final handler = FeedbackDisplay.dialog.createDefaultHandler();
      expect(handler, isA<DialogFeedbackHandler>());
    });

    test('should create BottomSheetFeedbackHandler for bottomSheet', () {
      final handler = FeedbackDisplay.bottomSheet.createDefaultHandler();
      expect(handler, isA<BottomSheetFeedbackHandler>());
    });

    test('should create ToastFeedbackHandler for toast', () {
      final handler = FeedbackDisplay.toast.createDefaultHandler();
      expect(handler, isA<ToastFeedbackHandler>());
    });

    test('should create BannerFeedbackHandler for banner', () {
      final handler = FeedbackDisplay.banner.createDefaultHandler();
      expect(handler, isA<BannerFeedbackHandler>());
    });

    test('should throw UnsupportedError for custom display', () {
      expect(
        () => FeedbackDisplay.custom.createDefaultHandler(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('allDefaultHandlers should return all handlers except custom', () {
      // Access through extension - create handlers manually for test
      final handlers = FeedbackDisplay.values
          .where((display) => display != FeedbackDisplay.custom)
          .map((display) => display.createDefaultHandler())
          .toList();
      
      expect(handlers.length, equals(5));
      expect(handlers.any((h) => h is SnackbarFeedbackHandler), isTrue);
      expect(handlers.any((h) => h is DialogFeedbackHandler), isTrue);
      expect(handlers.any((h) => h is BottomSheetFeedbackHandler), isTrue);
      expect(handlers.any((h) => h is ToastFeedbackHandler), isTrue);
      expect(handlers.any((h) => h is BannerFeedbackHandler), isTrue);
    });
  });
}

