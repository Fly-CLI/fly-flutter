import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/event_stream_manager.dart';

/// Manages screen event stream
///
/// Owns the StreamController for screen events.
/// Can be extended for custom behavior if needed.
class ScreenStreamManager extends EventStreamManager<ScreenEvent> {
  // No additional logic needed - base class handles everything
  // Can override for custom behavior if needed
}

