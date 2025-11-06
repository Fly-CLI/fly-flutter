import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:fly_feedback/src/mixins/fly_feedback_emitter_mixin.dart';

class TestEmitter with FlyFeedbackEmitterMixin {}

void main() {
  group('FlyFeedbackEmitterMixin', () {
    late TestEmitter emitter;

    setUp(() {
      emitter = TestEmitter();
    });

    tearDown(() {
      emitter.disposeFeedbackEmitter();
    });

    test('should return broadcast stream', () {
      final stream = emitter.feedbackStream;
      
      expect(stream, isNotNull);
      expect(stream, isA<Stream<FeedbackEvent>>());
    });

    test('should return empty stream when disposed', () {
      emitter.disposeFeedbackEmitter();
      
      final stream = emitter.feedbackStream;
      
      expect(stream, isA<Stream<FeedbackEvent>>());
    });

    test('should return false for isDisposed when not disposed', () {
      expect(emitter.isDisposed, isFalse);
    });

    test('should return true for isDisposed when disposed', () {
      emitter.disposeFeedbackEmitter();
      
      expect(emitter.isDisposed, isTrue);
    });

    test('should add event to stream', () async {
      final event = SuccessFeedback('Message');
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      final result = emitter.emitFeedback(event);
      
      expect(result, isTrue);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      expect(events.first, equals(event));
    });

    test('should return false when disposed', () {
      emitter.disposeFeedbackEmitter();
      
      final event = SuccessFeedback('Message');
      final result = emitter.emitFeedback(event);
      
      expect(result, isFalse);
    });

    test('should create and emit SuccessFeedback', () async {
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      emitter.emitSuccess('Success message');
      
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      expect(events.first, isA<SuccessFeedback>());
      expect((events.first as SuccessFeedback).message, equals('Success message'));
    });

    test('should create and emit ErrorFeedback', () async {
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      emitter.emitError('Error message');
      
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      expect(events.first, isA<ErrorFeedback>());
      expect((events.first as ErrorFeedback).message, equals('Error message'));
    });

    test('should create and emit WarningFeedback', () async {
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      emitter.emitWarning('Warning message');
      
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      expect(events.first, isA<WarningFeedback>());
      expect((events.first as WarningFeedback).message, equals('Warning message'));
    });

    test('should create and emit InfoFeedback', () async {
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      emitter.emitInfo('Info message');
      
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      expect(events.first, isA<InfoFeedback>());
      expect((events.first as InfoFeedback).message, equals('Info message'));
    });

    test('should create and emit ConfirmationFeedback', () async {
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      emitter.emitConfirmation(
        title: 'Title',
        message: 'Message',
      );
      
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      expect(events.first, isA<ConfirmationFeedback>());
      final confirmation = events.first as ConfirmationFeedback;
      expect(confirmation.title, equals('Title'));
      expect(confirmation.message, equals('Message'));
    });

    test('should close stream and mark as disposed', () {
      expect(emitter.isDisposed, isFalse);
      
      emitter.disposeFeedbackEmitter();
      
      expect(emitter.isDisposed, isTrue);
    });

    test('should be safe to call dispose multiple times', () {
      emitter.disposeFeedbackEmitter();
      emitter.disposeFeedbackEmitter();
      emitter.disposeFeedbackEmitter();
      
      expect(emitter.isDisposed, isTrue);
    });

    test('should emit with all parameters for emitSuccess', () async {
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      bool actionCalled = false;
      emitter.emitSuccess(
        'Message',
        display: FeedbackDisplay.dialog,
        duration: const Duration(seconds: 5),
        action: () => actionCalled = true,
        actionLabel: 'Action',
        metadata: {'key': 'value'},
      );
      
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      final event = events.first as SuccessFeedback;
      expect(event.display, equals(FeedbackDisplay.dialog));
      expect(event.duration, equals(const Duration(seconds: 5)));
      expect(event.actionLabel, equals('Action'));
      expect(event.metadata['key'], equals('value'));
      
      event.action?.call();
      expect(actionCalled, isTrue);
    });

    test('should emit with all parameters for emitError', () async {
      final events = <FeedbackEvent>[];
      
      emitter.feedbackStream.listen((e) {
        events.add(e);
      });
      
      bool retryCalled = false;
      emitter.emitError(
        'Message',
        technicalDetails: 'Details',
        retryAction: () => retryCalled = true,
        retryLabel: 'Retry',
        showTechnicalDetails: true,
        display: FeedbackDisplay.dialog,
        duration: const Duration(seconds: 5),
        metadata: {'key': 'value'},
      );
      
      await Future.delayed(const Duration(milliseconds: 10));
      expect(events.length, equals(1));
      final event = events.first as ErrorFeedback;
      expect(event.technicalDetails, equals('Details'));
      expect(event.retryLabel, equals('Retry'));
      expect(event.showTechnicalDetails, isTrue);
      expect(event.display, equals(FeedbackDisplay.dialog));
      expect(event.duration, equals(const Duration(seconds: 5)));
      expect(event.metadata['key'], equals('value'));
      
      event.retryAction?.call();
      expect(retryCalled, isTrue);
    });
  });
}

