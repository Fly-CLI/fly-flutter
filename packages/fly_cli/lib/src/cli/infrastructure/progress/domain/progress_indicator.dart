import 'package:fly_cli/src/cli/infrastructure/progress/infrastructure/bar_progress_indicator.dart';
import 'package:fly_cli/src/cli/infrastructure/progress/infrastructure/silent_progress_indicator.dart';
import 'package:fly_cli/src/cli/infrastructure/progress/infrastructure/spinner_progress_indicator.dart';

/// Progress information for command execution
class ProgressInfo {
  const ProgressInfo({
    required this.message,
    this.percent,
    this.current,
    this.total,
    this.stage,
  });

  /// Progress message
  final String message;

  /// Progress percentage (0-100)
  final int? percent;

  /// Current progress value
  final int? current;

  /// Total progress value
  final int? total;

  /// Current stage name (e.g., 'validation', 'execution')
  final String? stage;

  /// Whether progress is complete
  bool get isComplete => percent == 100 || (current != null && total != null && current! >= total!);

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'message': message,
        if (percent != null) 'percent': percent,
        if (current != null) 'current': current,
        if (total != null) 'total': total,
        if (stage != null) 'stage': stage,
      };
}

/// Abstract interface for displaying progress indicators
///
/// Different implementations provide different UI feedback:
/// - [SpinnerProgressIndicator]: Animated spinner with message
/// - [BarProgressIndicator]: Progress bar with percentage
/// - [SilentProgressIndicator]: No visual output (for JSON/quiet modes)
abstract class ProgressIndicator {
  /// Start progress tracking
  ///
  /// [message] - Initial progress message
  void start(String message);

  /// Update progress
  ///
  /// [message] - Updated progress message
  /// [percent] - Progress percentage (0-100, optional)
  /// [current] - Current progress value (optional)
  /// [total] - Total progress value (optional)
  /// [stage] - Current stage name (optional)
  void update({
    String? message,
    int? percent,
    int? current,
    int? total,
    String? stage,
  });

  /// Complete progress tracking
  ///
  /// [message] - Final completion message
  void complete(String message);

  /// Stop/cancel progress tracking
  ///
  /// [message] - Cancellation message (optional)
  void stop([String? message]);

  /// Whether progress is currently active
  bool get isActive;

  /// Get current progress info
  ProgressInfo? get currentProgress;
}

