import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/queue/queued_feedback_item.dart';
import 'package:fly_feedback/src/types/feedback_priority.dart';

void main() {
  group('QueuedFeedbackItem', () {
    late BuildContext context;
    late FeedbackEvent event;

    setUp(() {
      event = SuccessFeedback('Test message');
    });

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

    testWidgets('should create with required parameters', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final timestamp = DateTime.now();
      final item = QueuedFeedbackItem(
        event: event,
        context: context,
        timestamp: timestamp,
        priority: FeedbackPriority.normal,
      );
      
      expect(item.event, equals(event));
      expect(item.context, equals(context));
      expect(item.timestamp, equals(timestamp));
      expect(item.priority, equals(FeedbackPriority.normal));
      expect(item.id, equals(event.id));
    });

    testWidgets('should calculate age correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final timestamp = DateTime.now().subtract(const Duration(seconds: 5));
      final item = QueuedFeedbackItem(
        event: event,
        context: context,
        timestamp: timestamp,
        priority: FeedbackPriority.normal,
      );
      
      final age = item.age;
      expect(age.inSeconds, greaterThanOrEqualTo(5));
      expect(age.inSeconds, lessThan(6));
    });

    testWidgets('should validate context when mounted', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final item = QueuedFeedbackItem(
        event: event,
        context: context,
        timestamp: DateTime.now(),
        priority: FeedbackPriority.normal,
      );
      
      expect(item.isContextValid, isTrue);
    });

    testWidgets('should detect stale items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final timestamp = DateTime.now().subtract(const Duration(seconds: 10));
      final item = QueuedFeedbackItem(
        event: event,
        context: context,
        timestamp: timestamp,
        priority: FeedbackPriority.normal,
      );
      
      final maxWait = const Duration(seconds: 5);
      expect(item.isStale(maxWait), isTrue);
    });

    testWidgets('should not detect fresh items as stale', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final timestamp = DateTime.now().subtract(const Duration(seconds: 2));
      final item = QueuedFeedbackItem(
        event: event,
        context: context,
        timestamp: timestamp,
        priority: FeedbackPriority.normal,
      );
      
      final maxWait = const Duration(seconds: 5);
      expect(item.isStale(maxWait), isFalse);
    });

    testWidgets('should compare by priority first', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final timestamp = DateTime.now();
      final highPriorityItem = QueuedFeedbackItem(
        event: SuccessFeedback('High'),
        context: context,
        timestamp: timestamp,
        priority: FeedbackPriority.high,
      );
      
      final lowPriorityItem = QueuedFeedbackItem(
        event: SuccessFeedback('Low'),
        context: context,
        timestamp: timestamp,
        priority: FeedbackPriority.low,
      );
      
      // High priority should come before low priority
      expect(highPriorityItem.compareTo(lowPriorityItem), lessThan(0));
      expect(lowPriorityItem.compareTo(highPriorityItem), greaterThan(0));
    });

    testWidgets('should compare by timestamp when priority is equal', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final olderTimestamp = DateTime.now().subtract(const Duration(seconds: 5));
      final newerTimestamp = DateTime.now();
      
      final olderItem = QueuedFeedbackItem(
        event: SuccessFeedback('Older'),
        context: context,
        timestamp: olderTimestamp,
        priority: FeedbackPriority.normal,
      );
      
      final newerItem = QueuedFeedbackItem(
        event: SuccessFeedback('Newer'),
        context: context,
        timestamp: newerTimestamp,
        priority: FeedbackPriority.normal,
      );
      
      // Older item should come before newer item (FIFO)
      expect(olderItem.compareTo(newerItem), lessThan(0));
      expect(newerItem.compareTo(olderItem), greaterThan(0));
    });

    testWidgets('should have equality based on ID', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      const eventId = 'test-id';
      final event1 = SuccessFeedback('Message 1', id: eventId);
      final event2 = SuccessFeedback('Message 2', id: eventId);
      
      final item1 = QueuedFeedbackItem(
        event: event1,
        context: context,
        timestamp: DateTime.now(),
        priority: FeedbackPriority.normal,
      );
      
      final item2 = QueuedFeedbackItem(
        event: event2,
        context: context,
        timestamp: DateTime.now(),
        priority: FeedbackPriority.high,
      );
      
      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });

    testWidgets('should have different hashCodes for different IDs', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final item1 = QueuedFeedbackItem(
        event: SuccessFeedback('Message 1'),
        context: context,
        timestamp: DateTime.now(),
        priority: FeedbackPriority.normal,
      );
      
      final item2 = QueuedFeedbackItem(
        event: SuccessFeedback('Message 2'),
        context: context,
        timestamp: DateTime.now(),
        priority: FeedbackPriority.normal,
      );
      
      expect(item1.hashCode, isNot(equals(item2.hashCode)));
    });

    testWidgets('should return correct string representation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final item = QueuedFeedbackItem(
        event: event,
        context: context,
        timestamp: DateTime.now(),
        priority: FeedbackPriority.normal,
      );
      
      final str = item.toString();
      expect(str, contains(item.id));
      expect(str, contains('priority'));
      expect(str, contains('age'));
    });
  });
}

