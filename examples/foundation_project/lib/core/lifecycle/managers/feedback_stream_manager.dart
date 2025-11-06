import 'dart:async';
import 'package:fly_feedback/fly_feedback.dart';
import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/event_stream_manager.dart';

/// Manages feedback event stream
///
/// Owns the StreamController for feedback events.
/// Works with FeedbackEventWrapper for lifecycle integration but provides
/// direct FeedbackEvent stream access for type safety.
class FeedbackStreamManager extends EventStreamManager<FeedbackEventWrapper> {
  // Store the actual FeedbackEvent stream separately for type-safe access
  StreamController<FeedbackEvent>? _feedbackController;
  
  /// Get the FeedbackEvent stream (type-safe, unwrapped)
  Stream<FeedbackEvent> get feedbackStream {
    _feedbackController ??= StreamController<FeedbackEvent>.broadcast();
    return _feedbackController!.stream;
  }
  
  /// Emit a FeedbackEvent directly (type-safe)
  /// This method is called by the lifecycle integration layer
  bool emitFeedback(FeedbackEvent event) {
    if (isDisposed) {
      return false;
    }
    
    // Emit to both streams: the wrapper stream (for lifecycle) and direct stream (for type safety)
    _feedbackController ??= StreamController<FeedbackEvent>.broadcast();
    
    bool emitted = false;
    if (!_feedbackController!.isClosed) {
      _feedbackController!.add(event);
      emitted = true;
    }
    
    // Also emit as wrapper for lifecycle system compatibility
    emit(FeedbackEventWrapper(event));
    
    return emitted;
  }
  
  @override
  void dispose() {
    _feedbackController?.close();
    _feedbackController = null;
    super.dispose();
  }
}
