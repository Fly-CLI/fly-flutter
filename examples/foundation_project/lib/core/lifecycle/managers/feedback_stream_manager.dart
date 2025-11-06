import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/event_stream_manager.dart';

/// Manages the feedback lifecycle event stream.
///
/// Owns the StreamController responsible for broadcasting feedback events that
/// originate from the shared lifecycle emitter.
class FeedbackStreamManager extends EventStreamManager<FeedbackLifecycleEvent> {
  // Base implementation provides all required behavior.
}


