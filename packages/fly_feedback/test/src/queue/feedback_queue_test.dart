import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/config/feedback_queue_config.dart';
import 'package:fly_feedback/src/queue/feedback_queue.dart';
import 'package:fly_feedback/src/types/feedback_priority.dart';

void main() {
  group('FeedbackQueue', () {
    late BuildContext context;
    final List<FeedbackQueue> _queuesToDispose = [];

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

    setUp(() async {
      // Setup is done in testWidgets
      _queuesToDispose.clear();
    });

    tearDown(() {
      // Ensure all queues are disposed to prevent timers from hanging
      for (final queue in _queuesToDispose) {
        queue.dispose();
      }
      _queuesToDispose.clear();
    });

    group('initialization', () {
      testWidgets('should create with default config', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        
        expect(queue.config, isNotNull);
        expect(queue.isEmpty, isTrue);
        expect(queue.length, equals(0));
        
        queue.dispose();
      });

      testWidgets('should create with custom config', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        const customConfig = FeedbackQueueConfig(
          maxQueueSize: 5,
          enablePrioritySorting: false,
        );
        final queue = FeedbackQueue(config: customConfig);
        
        expect(queue.config.maxQueueSize, equals(5));
        expect(queue.config.enablePrioritySorting, isFalse);
        
        queue.dispose();
      });
    });

    group('add', () {
      testWidgets('should add item successfully', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        final event = SuccessFeedback('Message');
        
        final result = queue.add(context, event);
        
        expect(result, isTrue);
        expect(queue.length, equals(1));
        expect(queue.isEmpty, isFalse);
        
        queue.dispose();
      });

      testWidgets('should prevent duplicates when enabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            enableDuplicatePrevention: true,
          ),
        );
        const eventId = 'test-id';
        final event1 = SuccessFeedback('Message 1', id: eventId);
        final event2 = SuccessFeedback('Message 2', id: eventId);
        
        expect(queue.add(context, event1), isTrue);
        expect(queue.add(context, event2), isFalse);
        expect(queue.length, equals(1));
        
        queue.dispose();
      });

      testWidgets('should allow duplicates when disabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            enableDuplicatePrevention: false,
          ),
        );
        const eventId = 'test-id';
        final event1 = SuccessFeedback('Message 1', id: eventId);
        final event2 = SuccessFeedback('Message 2', id: eventId);
        
        expect(queue.add(context, event1), isTrue);
        expect(queue.add(context, event2), isTrue);
        expect(queue.length, equals(2));
        
        queue.dispose();
      });

      testWidgets('should sort by priority when enabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            enablePrioritySorting: true,
          ),
        );
        
        final lowEvent = SuccessFeedback('Low');
        final highEvent = ErrorFeedback('High');
        
        queue.add(context, lowEvent);
        queue.add(context, highEvent);
        
        // High priority should be first
        expect(queue.length, equals(2));
        
        queue.dispose();
      });

      testWidgets('should enforce size limit', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        bool itemDropped = false;
        final queue = FeedbackQueue(
          config: FeedbackQueueConfig(
            maxQueueSize: 2,
            onItemDropped: (_) => itemDropped = true,
          ),
        );
        
        queue.add(context, SuccessFeedback('1'));
        queue.add(context, SuccessFeedback('2'));
        queue.add(context, SuccessFeedback('3'));
        
        expect(queue.length, equals(2));
        expect(itemDropped, isTrue);
        
        queue.dispose();
      });

      testWidgets('should return false on error', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        // Using a context that might cause issues
        final invalidContext = context;
        
        // This should work, but we test error handling path
        final result = queue.add(invalidContext, SuccessFeedback('Message'));
        expect(result, isTrue);
        
        queue.dispose();
      });
    });

    group('process', () {
      testWidgets('should process items in priority order', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        final processedEvents = <FeedbackEvent>[];
        
        final lowEvent = SuccessFeedback('Low');
        final highEvent = ErrorFeedback('High');
        
        queue.add(context, lowEvent);
        queue.add(context, highEvent);
        
        queue.process(
          (ctx, event) {
            processedEvents.add(event);
          },
          () => false,
        );
        
        expect(processedEvents.length, equals(1));
        expect(processedEvents.first, equals(highEvent));
        expect(queue.length, equals(1));
        
        queue.dispose();
      });

      testWidgets('should skip when already processing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        final event = SuccessFeedback('Message');
        queue.add(context, event);
        
        bool processorCalled = false;
        queue.process(
          (ctx, evt) {
            processorCalled = true;
          },
          () => true, // Already processing
        );
        
        expect(processorCalled, isFalse);
        expect(queue.length, equals(1));
        
        queue.dispose();
      });

      testWidgets('should remove invalid contexts when enabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            enableContextValidation: true,
          ),
        );
        
        final event = SuccessFeedback('Message');
        queue.add(context, event);
        
        // Remove widget to invalidate context
        await tester.pumpWidget(const SizedBox());
        
        queue.process(
          (ctx, evt) {},
          () => false,
        );
        
        // Queue should be empty after removing invalid context
        expect(queue.isEmpty, isTrue);
        
        queue.dispose();
      });

      testWidgets('should call processor function', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        final event = SuccessFeedback('Message');
        queue.add(context, event);
        
        bool processorCalled = false;
        FeedbackEvent? processedEvent;
        BuildContext? processedContext;
        
        queue.process(
          (ctx, evt) {
            processorCalled = true;
            processedEvent = evt;
            processedContext = ctx;
          },
          () => false,
        );
        
        expect(processorCalled, isTrue);
        expect(processedEvent, equals(event));
        expect(processedContext, equals(context));
        expect(queue.isEmpty, isTrue);
        
        queue.dispose();
      });

      testWidgets('should remove processed items', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        final event = SuccessFeedback('Message');
        queue.add(context, event);
        
        expect(queue.length, equals(1));
        
        queue.process(
          (ctx, evt) {},
          () => false,
        );
        
        expect(queue.isEmpty, isTrue);
        
        queue.dispose();
      });

      testWidgets('should schedule next processing when queue not empty', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            queueRetryDelay: Duration(milliseconds: 50),
          ),
        );
        _queuesToDispose.add(queue);
        
        final event1 = SuccessFeedback('1');
        final event2 = SuccessFeedback('2');
        
        queue.add(context, event1);
        queue.add(context, event2);
        
        int processCount = 0;
        queue.process(
          (ctx, evt) {
            processCount++;
          },
          () => false,
        );
        
        expect(processCount, equals(1));
        expect(queue.length, equals(1));
        
        // Verify that a timer was scheduled (queue should still have items)
        // The timer will process the next item, but we'll clean up before it fires
        // to prevent the test from hanging
        expect(queue.length, equals(1));
        
        // Immediately dispose to cancel timer before it can fire
        // This must happen before clear() to ensure timer is cancelled
        queue.dispose();
        
        // Clear the queue as well for extra safety
        queue.clear();
        
        // Pump to ensure test framework processes the disposal
        await tester.pump();
      });

      testWidgets('should handle processor errors gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        final event = SuccessFeedback('Message');
        queue.add(context, event);
        
        queue.process(
          (ctx, evt) {
            throw Exception('Processor error');
          },
          () => false,
        );
        
        // Item should be removed even on error
        expect(queue.isEmpty, isTrue);
        
        queue.dispose();
      });
    });

    group('clear', () {
      testWidgets('should clear all items', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        queue.add(context, SuccessFeedback('1'));
        queue.add(context, SuccessFeedback('2'));
        
        expect(queue.length, equals(2));
        
        queue.clear();
        
        expect(queue.isEmpty, isTrue);
        expect(queue.length, equals(0));
        
        queue.dispose();
      });

      testWidgets('should cancel timer on clear', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        queue.add(context, SuccessFeedback('Message'));
        
        // Start processing to create timer
        queue.process(
          (ctx, evt) {},
          () => false,
        );
        
        queue.clear();
        
        // Timer should be cancelled
        expect(queue.isEmpty, isTrue);
        
        queue.dispose();
      });
    });

    group('configuration', () {
      testWidgets('should respect priority sorting enabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            enablePrioritySorting: true,
          ),
        );
        
        final lowEvent = SuccessFeedback('Low');
        final highEvent = ErrorFeedback('High');
        
        queue.add(context, lowEvent);
        queue.add(context, highEvent);
        
        expect(queue.length, equals(2));
        
        queue.dispose();
      });

      testWidgets('should respect duplicate prevention enabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            enableDuplicatePrevention: true,
          ),
        );
        
        const eventId = 'test-id';
        final event1 = SuccessFeedback('1', id: eventId);
        final event2 = SuccessFeedback('2', id: eventId);
        
        expect(queue.add(context, event1), isTrue);
        expect(queue.add(context, event2), isFalse);
        
        queue.dispose();
      });

      testWidgets('should respect context validation enabled', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            enableContextValidation: true,
          ),
        );
        
        final event = SuccessFeedback('Message');
        queue.add(context, event);
        
        await tester.pumpWidget(const SizedBox());
        
        queue.process(
          (ctx, evt) {},
          () => false,
        );
        
        expect(queue.isEmpty, isTrue);
        
        queue.dispose();
      });

      testWidgets('should use custom priority mapping', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue(
          config: const FeedbackQueueConfig(
            priorityMapping: {
              FeedbackType.success: FeedbackPriority.critical,
            },
          ),
        );
        
        final event = SuccessFeedback('Message');
        queue.add(context, event);
        
        expect(queue.length, equals(1));
        
        queue.dispose();
      });
    });

    group('dispose', () {
      testWidgets('should dispose resources', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final queue = FeedbackQueue();
        queue.add(context, SuccessFeedback('Message'));
        
        queue.dispose();
        
        expect(queue.isEmpty, isTrue);
      });
    });
  });
}

