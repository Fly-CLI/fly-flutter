import 'package:fly_cli/src/cli/infrastructure/progress/domain/progress_indicator.dart';

/// Silent progress indicator that tracks progress without displaying it
///
/// Suitable for:
/// - JSON output mode (progress is included in result metadata)
/// - Quiet mode (no visual output)
/// - Automated scripts (progress tracked but not displayed)
class SilentProgressIndicator implements ProgressIndicator {
  SilentProgressIndicator() : _progress = null;

  ProgressInfo? _progress;

  @override
  bool get isActive => _progress != null && !(_progress!.isComplete);

  @override
  ProgressInfo? get currentProgress => _progress;

  @override
  void start(String message) {
    _progress = ProgressInfo(
      message: message,
      percent: 0,
    );
  }

  @override
  void update({
    String? message,
    int? percent,
    int? current,
    int? total,
    String? stage,
  }) {
    _progress = ProgressInfo(
      message: message ?? _progress?.message ?? '',
      percent: percent ?? _progress?.percent,
      current: current ?? _progress?.current,
      total: total ?? _progress?.total,
      stage: stage ?? _progress?.stage,
    );
  }

  @override
  void complete(String message) {
    _progress = ProgressInfo(
      message: message,
      percent: 100,
    );
  }

  @override
  void stop([String? message]) {
    _progress = null;
  }
}

