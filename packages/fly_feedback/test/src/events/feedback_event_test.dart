import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

void main() {
  group('FeedbackEvent', () {
    group('base class', () {
      test('should generate unique IDs', () {
        final event1 = SuccessFeedback('Message 1');
        final event2 = SuccessFeedback('Message 2');
        
        expect(event1.id, isNot(equals(event2.id)));
      });

      test('should assign timestamp on creation', () {
        final before = DateTime.now();
        final event = SuccessFeedback('Message');
        final after = DateTime.now();
        
        expect(event.timestamp.isAfter(before) || event.timestamp.isAtSameMomentAs(before), isTrue);
        expect(event.timestamp.isBefore(after) || event.timestamp.isAtSameMomentAs(after), isTrue);
      });

      test('should use provided timestamp when given', () {
        final customTimestamp = DateTime(2024, 1, 1);
        final event = SuccessFeedback(
          'Message',
          timestamp: customTimestamp,
        );
        
        expect(event.timestamp, equals(customTimestamp));
      });

      test('should use provided ID when given', () {
        const customId = 'custom-id-123';
        final event = SuccessFeedback(
          'Message',
          id: customId,
        );
        
        expect(event.id, equals(customId));
      });

      test('should handle metadata', () {
        final metadata = {'key1': 'value1', 'key2': 42};
        final event = SuccessFeedback(
          'Message',
          metadata: metadata,
        );
        
        expect(event.metadata, equals(metadata));
      });

      test('should have equality based on ID', () {
        const id = 'test-id';
        final event1 = SuccessFeedback('Message 1', id: id);
        final event2 = SuccessFeedback('Message 2', id: id);
        
        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should have different hashCodes for different IDs', () {
        final event1 = SuccessFeedback('Message 1');
        final event2 = SuccessFeedback('Message 2');
        
        expect(event1.hashCode, isNot(equals(event2.hashCode)));
      });
    });

    group('SuccessFeedback', () {
      test('should create with required message', () {
        final event = SuccessFeedback('Success message');
        
        expect(event.message, equals('Success message'));
        expect(event.type, equals(FeedbackType.success));
      });

      test('should create with all parameters', () {
        bool actionCalled = false;
        final event = SuccessFeedback(
          'Success message',
          display: FeedbackDisplay.dialog,
          duration: const Duration(seconds: 5),
          action: () => actionCalled = true,
          actionLabel: 'Action',
          metadata: {'key': 'value'},
        );
        
        expect(event.message, equals('Success message'));
        expect(event.display, equals(FeedbackDisplay.dialog));
        expect(event.duration, equals(const Duration(seconds: 5)));
        expect(event.action, isNotNull);
        expect(event.actionLabel, equals('Action'));
        expect(event.metadata, equals({'key': 'value'}));
        
        event.action?.call();
        expect(actionCalled, isTrue);
      });

      test('should handle null action and actionLabel', () {
        final event = SuccessFeedback('Message');
        
        expect(event.action, isNull);
        expect(event.actionLabel, isNull);
      });
    });

    group('ErrorFeedback', () {
      test('should create with required message', () {
        final event = ErrorFeedback('Error message');
        
        expect(event.message, equals('Error message'));
        expect(event.type, equals(FeedbackType.error));
      });

      test('should create with all parameters', () {
        bool retryCalled = false;
        final event = ErrorFeedback(
          'Error message',
          technicalDetails: 'Technical details',
          retryAction: () => retryCalled = true,
          retryLabel: 'Retry',
          showTechnicalDetails: true,
          display: FeedbackDisplay.dialog,
          duration: const Duration(seconds: 5),
          metadata: {'key': 'value'},
        );
        
        expect(event.message, equals('Error message'));
        expect(event.technicalDetails, equals('Technical details'));
        expect(event.retryAction, isNotNull);
        expect(event.retryLabel, equals('Retry'));
        expect(event.showTechnicalDetails, isTrue);
        expect(event.display, equals(FeedbackDisplay.dialog));
        expect(event.duration, equals(const Duration(seconds: 5)));
        expect(event.metadata, equals({'key': 'value'}));
        
        event.retryAction?.call();
        expect(retryCalled, isTrue);
      });

      test('should handle null technical details and retry', () {
        final event = ErrorFeedback('Message');
        
        expect(event.technicalDetails, isNull);
        expect(event.retryAction, isNull);
        expect(event.retryLabel, isNull);
        expect(event.showTechnicalDetails, isFalse);
      });
    });

    group('WarningFeedback', () {
      test('should create with required message', () {
        final event = WarningFeedback('Warning message');
        
        expect(event.message, equals('Warning message'));
        expect(event.type, equals(FeedbackType.warning));
      });

      test('should create with optional parameters', () {
        final event = WarningFeedback(
          'Warning message',
          display: FeedbackDisplay.dialog,
          duration: const Duration(seconds: 5),
          metadata: {'key': 'value'},
        );
        
        expect(event.message, equals('Warning message'));
        expect(event.display, equals(FeedbackDisplay.dialog));
        expect(event.duration, equals(const Duration(seconds: 5)));
        expect(event.metadata, equals({'key': 'value'}));
      });
    });

    group('InfoFeedback', () {
      test('should create with required message', () {
        final event = InfoFeedback('Info message');
        
        expect(event.message, equals('Info message'));
        expect(event.type, equals(FeedbackType.info));
      });

      test('should create with optional parameters', () {
        final event = InfoFeedback(
          'Info message',
          display: FeedbackDisplay.dialog,
          duration: const Duration(seconds: 5),
          metadata: {'key': 'value'},
        );
        
        expect(event.message, equals('Info message'));
        expect(event.display, equals(FeedbackDisplay.dialog));
        expect(event.duration, equals(const Duration(seconds: 5)));
        expect(event.metadata, equals({'key': 'value'}));
      });
    });

    group('ConfirmationFeedback', () {
      test('should create with required title and message', () {
        final event = ConfirmationFeedback(
          title: 'Title',
          message: 'Message',
        );
        
        expect(event.title, equals('Title'));
        expect(event.message, equals('Message'));
        expect(event.type, equals(FeedbackType.info));
        expect(event.display, equals(FeedbackDisplay.dialog));
      });

      test('should create with all parameters', () {
        bool confirmCalled = false;
        bool cancelCalled = false;
        final event = ConfirmationFeedback(
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
        
        expect(event.title, equals('Title'));
        expect(event.message, equals('Message'));
        expect(event.confirmLabel, equals('Confirm'));
        expect(event.cancelLabel, equals('Cancel'));
        expect(event.isDangerous, isTrue);
        expect(event.barrierDismissible, isFalse);
        expect(event.metadata, equals({'key': 'value'}));
        
        event.onConfirm?.call();
        event.onCancel?.call();
        expect(confirmCalled, isTrue);
        expect(cancelCalled, isTrue);
      });

      test('should handle null callbacks and labels', () {
        final event = ConfirmationFeedback(
          title: 'Title',
          message: 'Message',
        );
        
        expect(event.confirmLabel, isNull);
        expect(event.cancelLabel, isNull);
        expect(event.onConfirm, isNull);
        expect(event.onCancel, isNull);
        expect(event.isDangerous, isFalse);
        expect(event.barrierDismissible, isTrue);
      });
    });
  });
}

