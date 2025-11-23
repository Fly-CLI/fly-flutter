import 'package:fly_cli/src/core/progress/domain/progress_indicator.dart';
import 'package:fly_core/fly_core_dart.dart';

/// Execution phase of a command
enum ExecutionPhase {
  /// Initialization phase (before validation)
  initialization,

  /// Validation phase
  validation,

  /// Middleware phase (before execution)
  middleware,

  /// Execution phase (actual command logic)
  execution,

  /// Completion phase (after execution)
  completion,

  /// Error phase (when an error occurs)
  error,
}

/// Execution context for tracking command execution lifecycle
///
/// Provides structured tracking of execution state including:
/// - Phase transitions (validation → middleware → execution → completion)
/// - Duration tracking per phase
/// - Cancellation support
/// - Arbitrary metadata storage
/// - Foundation for progress tracking (Phase 3)
class CommandExecutionContext {
  /// Create a new execution context
  CommandExecutionContext({
    required this.commandName,
    DateTime? startTime,
    CancellationToken? cancellationToken,
    ExecutionPhase? currentPhase,
    Map<String, dynamic>? metadata,
    ProgressIndicator? progressTracker,
  })  : _startTime = startTime ?? DateTime.now(),
        _cancellationToken = cancellationToken ?? CancellationToken(),
        _currentPhase = currentPhase ?? ExecutionPhase.initialization,
        _metadata = Map<String, dynamic>.from(metadata ?? {}),
        _phaseDurations = <ExecutionPhase, Duration>{},
        _phaseStartTimes = <ExecutionPhase, DateTime>{},
        _progressTracker = progressTracker;

  /// Name of the command being executed
  final String commandName;

  /// Start time of the execution
  final DateTime _startTime;

  /// Cancellation token for the execution
  final CancellationToken _cancellationToken;

  /// Current execution phase
  ExecutionPhase _currentPhase;

  /// Get the current execution phase
  ExecutionPhase get currentPhase => _currentPhase;

  /// Set the current execution phase
  ///
  /// Automatically records the duration of the previous phase if it was started.
  void setPhase(ExecutionPhase phase) {
    // Record duration of current phase if it was started
    if (_phaseStartTimes.containsKey(_currentPhase)) {
      final startTime = _phaseStartTimes[_currentPhase]!;
      final duration = DateTime.now().difference(startTime);
      _phaseDurations[_currentPhase] = duration;
      _phaseStartTimes.remove(_currentPhase);
    }

    // Start timing the new phase
    _currentPhase = phase;
    _phaseStartTimes[phase] = DateTime.now();
  }

  /// Metadata stored in this context
  final Map<String, dynamic> _metadata;

  /// Duration of each phase
  final Map<ExecutionPhase, Duration> _phaseDurations;

  /// Start times for phases currently in progress
  final Map<ExecutionPhase, DateTime> _phaseStartTimes;

  /// Progress tracker for execution (optional)
  ProgressIndicator? _progressTracker;

  /// Get the progress tracker
  ProgressIndicator? get progressTracker => _progressTracker;

  /// Set the progress tracker
  void setProgressTracker(ProgressIndicator tracker) {
    _progressTracker = tracker;
  }

  /// Get elapsed time since execution started
  Duration get elapsed => DateTime.now().difference(_startTime);

  /// Get elapsed time in milliseconds
  int get elapsedMs => elapsed.inMilliseconds;

  /// Get the cancellation token
  CancellationToken get cancellationToken => _cancellationToken;

  /// Whether cancellation was requested
  bool get isCancelled => _cancellationToken.isCancelled;

  /// Get metadata value by key
  T? getMetadata<T>(String key) {
    final value = _metadata[key];
    return value is T ? value : null;
  }

  /// Set metadata value
  void setMetadata(String key, dynamic value) {
    _metadata[key] = value;
  }

  /// Get all metadata
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);

  /// Get duration for a specific phase
  Duration? getPhaseDuration(ExecutionPhase phase) {
    return _phaseDurations[phase];
  }

  /// Get all phase durations
  Map<ExecutionPhase, Duration> get phaseDurations =>
      Map.unmodifiable(_phaseDurations);

  /// Record phase duration manually
  ///
  /// Useful when phase transitions happen outside of setPhase().
  void recordPhaseDuration(ExecutionPhase phase, Duration duration) {
    _phaseDurations[phase] = duration;
  }

  /// Record phase duration in milliseconds
  void recordPhaseDurationMs(ExecutionPhase phase, int milliseconds) {
    _phaseDurations[phase] = Duration(milliseconds: milliseconds);
  }

  /// Get summary of execution context
  Map<String, dynamic> toJson() {
    final currentPhaseDuration = _phaseStartTimes.containsKey(_currentPhase)
        ? DateTime.now().difference(_phaseStartTimes[_currentPhase]!)
        : null;

    return {
      'command_name': commandName,
      'start_time': _startTime.toIso8601String(),
      'elapsed_ms': elapsedMs,
      'current_phase': _currentPhase.name,
      'is_cancelled': isCancelled,
      'phase_durations': _phaseDurations.map(
        (phase, duration) => MapEntry(phase.name, duration.inMilliseconds),
      ),
      if (currentPhaseDuration != null)
        'current_phase_duration_ms': currentPhaseDuration.inMilliseconds,
      if (_progressTracker != null && _progressTracker!.currentProgress != null)
        'progress': _progressTracker!.currentProgress!.toJson(),
      'metadata': Map<String, dynamic>.from(_metadata),
    };
  }
}
