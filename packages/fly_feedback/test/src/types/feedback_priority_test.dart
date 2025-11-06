import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/events/feedback_event.dart';
import 'package:fly_feedback/src/types/feedback_priority.dart';
import 'package:fly_feedback/src/types/feedback_types.dart';

void main() {
  group('FeedbackPriority', () {
    test('should have correct priority values', () {
      expect(FeedbackPriority.critical.value, equals(5));
      expect(FeedbackPriority.high.value, equals(4));
      expect(FeedbackPriority.normal.value, equals(3));
      expect(FeedbackPriority.low.value, equals(2));
    });

    test('compareTo should return negative for lower priority', () {
      expect(
        FeedbackPriority.low.compareTo(FeedbackPriority.high),
        lessThan(0),
      );
    });

    test('compareTo should return positive for higher priority', () {
      expect(
        FeedbackPriority.high.compareTo(FeedbackPriority.low),
        greaterThan(0),
      );
    });

    test('compareTo should return zero for equal priority', () {
      expect(
        FeedbackPriority.normal.compareTo(FeedbackPriority.normal),
        equals(0),
      );
    });

    test('isHigherThan should return true for higher priority', () {
      expect(
        FeedbackPriority.high.isHigherThan(FeedbackPriority.low),
        isTrue,
      );
    });

    test('isHigherThan should return false for lower priority', () {
      expect(
        FeedbackPriority.low.isHigherThan(FeedbackPriority.high),
        isFalse,
      );
    });

    test('isLowerThan should return true for lower priority', () {
      expect(
        FeedbackPriority.low.isLowerThan(FeedbackPriority.high),
        isTrue,
      );
    });

    test('isLowerThan should return false for higher priority', () {
      expect(
        FeedbackPriority.high.isLowerThan(FeedbackPriority.low),
        isFalse,
      );
    });
  });

  group('FeedbackTypePriority', () {
    test('should return high priority for error', () {
      expect(
        FeedbackType.error.defaultPriority,
        equals(FeedbackPriority.high),
      );
    });

    test('should return normal priority for warning', () {
      expect(
        FeedbackType.warning.defaultPriority,
        equals(FeedbackPriority.normal),
      );
    });

    test('should return low priority for info', () {
      expect(
        FeedbackType.info.defaultPriority,
        equals(FeedbackPriority.low),
      );
    });

    test('should return low priority for success', () {
      expect(
        FeedbackType.success.defaultPriority,
        equals(FeedbackPriority.low),
      );
    });
  });

  group('FeedbackEventPriority', () {
    test('should use priority from metadata when FeedbackPriority', () {
      final event = SuccessFeedback(
        'Message',
        metadata: {'priority': FeedbackPriority.critical},
      );
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.critical),
      );
    });

    test('should use priority from metadata when int', () {
      final event = SuccessFeedback(
        'Message',
        metadata: {'priority': 4}, // high
      );
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.high),
      );
    });

    test('should ignore invalid int priority in metadata', () {
      final event = SuccessFeedback(
        'Message',
        metadata: {'priority': 99}, // invalid
      );
      
      // Should fall back to type default
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.low),
      );
    });

    test('should use custom mapping when provided', () {
      final event = SuccessFeedback('Message');
      final customMapping = {
        FeedbackType.success: FeedbackPriority.critical,
      };
      
      expect(
        event.calculatePriority(customMapping: customMapping),
        equals(FeedbackPriority.critical),
      );
    });

    test('should prioritize metadata over custom mapping', () {
      final event = SuccessFeedback(
        'Message',
        metadata: {'priority': FeedbackPriority.high},
      );
      final customMapping = {
        FeedbackType.success: FeedbackPriority.critical,
      };
      
      expect(
        event.calculatePriority(customMapping: customMapping),
        equals(FeedbackPriority.high),
      );
    });

    test('should return critical for ConfirmationFeedback', () {
      final event = ConfirmationFeedback(
        title: 'Title',
        message: 'Message',
      );
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.critical),
      );
    });

    test('should return high for ErrorFeedback', () {
      final event = ErrorFeedback('Message');
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.high),
      );
    });

    test('should return normal for WarningFeedback', () {
      final event = WarningFeedback('Message');
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.normal),
      );
    });

    test('should return low for InfoFeedback', () {
      final event = InfoFeedback('Message');
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.low),
      );
    });

    test('should return low for SuccessFeedback', () {
      final event = SuccessFeedback('Message');
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.low),
      );
    });

    test('should fall back to type default when no metadata or mapping', () {
      final event = SuccessFeedback('Message');
      
      expect(
        event.calculatePriority(),
        equals(FeedbackPriority.low),
      );
    });
  });
}

