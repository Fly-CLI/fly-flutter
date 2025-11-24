import 'dart:io';

import 'package:fly_cli/src/cli/infrastructure/progress/domain/progress_indicator.dart';
import 'package:mason_logger/mason_logger.dart';

/// Spinner-based progress indicator for human-readable output
///
/// Shows an animated spinner with progress messages.
/// Suitable for interactive terminals.
class SpinnerProgressIndicator implements ProgressIndicator {
  SpinnerProgressIndicator({Logger? logger})
      : _logger = logger ?? Logger(),
        _progress = null,
        _spinner = null;

  final Logger _logger;
  ProgressInfo? _progress;
  Progress? _spinner;

  @override
  bool get isActive => _spinner != null;

  @override
  ProgressInfo? get currentProgress => _progress;

  @override
  void start(String message) {
    if (!_shouldShow()) return;

    _spinner = _logger.progress(message);
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
    if (!_shouldShow() || _spinner == null) return;

    final updatedMessage = message ?? _progress?.message ?? '';
    _spinner!.update(updatedMessage);
    _progress = ProgressInfo(
      message: updatedMessage,
      percent: percent ?? _progress?.percent,
      current: current ?? _progress?.current,
      total: total ?? _progress?.total,
      stage: stage ?? _progress?.stage,
    );
  }

  @override
  void complete(String message) {
    if (!_shouldShow() || _spinner == null) return;

    _spinner!.complete(message);
    _progress = ProgressInfo(
      message: message,
      percent: 100,
    );
    _spinner = null;
  }

  @override
  void stop([String? message]) {
    if (_spinner == null) return;

    if (message != null && _shouldShow()) {
      _spinner!.fail(message);
    } else {
      _spinner!.cancel();
    }
    _spinner = null;
    _progress = null;
  }

  bool _shouldShow() {
    // Only show spinner if stdout is a terminal
    return stdout.hasTerminal && !stdout.supportsAnsiEscapes == false;
  }
}

