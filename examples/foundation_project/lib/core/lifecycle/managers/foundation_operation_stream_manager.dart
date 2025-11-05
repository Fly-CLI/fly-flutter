import 'package:foundation_project/core/lifecycle/lifecycle_events.dart';
import 'package:foundation_project/core/lifecycle/managers/event_stream_manager.dart';

/// Manages foundation operation event stream
///
/// Owns the StreamController for foundation operation events.
/// Handles all async operation lifecycle events.
class FoundationOperationStreamManager
    extends EventStreamManager<FoundationOperationEvent> {
  // No additional logic needed - base class handles everything
  // Can override for custom behavior if needed
}

