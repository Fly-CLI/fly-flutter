import 'dart:io';

import 'package:fly_cli/src/core/progress/domain/progress_indicator.dart';
import 'package:mason_logger/mason_logger.dart';

/// Progress bar indicator for human-readable output
///
/// Shows a visual progress bar with percentage.
/// Suitable for operations with known total progress.
class BarProgressIndicator implements ProgressIndicator {
  BarProgressIndicator({Logger? logger})
      : _logger = logger ?? Logger(),
        _progress = null,
        _bar = null;

  final Logger _logger;
  ProgressInfo? _progress;
  Progress? _bar;

  @override
  bool get isActive => _bar != null;

  @override
  ProgressInfo? get currentProgress => _progress;

  @override
  void start(String message) {
    if (!_shouldShow()) return;

    _bar = _logger.progress(message);
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
    if (!_shouldShow() || _bar == null) return;

    // Calculate percent from current/total if not provided
    int? calculatedPercent = percent;
    if (calculatedPercent == null && current != null && total != null) {
      final currentValue = current;
      final totalValue = total;
      if (totalValue > 0) {
        calculatedPercent = ((currentValue / totalValue) * 100).round();
      }
    }

    final updatedMessage = message ?? _progress?.message ?? '';
    if (calculatedPercent != null) {
      _bar?.update('$updatedMessage [${calculatedPercent}%]');
    } else {
      _bar?.update(updatedMessage);
    }

    _progress = ProgressInfo(
      message: updatedMessage,
      percent: calculatedPercent ?? _progress?.percent,
      current: current ?? _progress?.current,
      total: total ?? _progress?.total,
      stage: stage ?? _progress?.stage,
    );
  }

  @override
  void complete(String message) {
    if (!_shouldShow() || _bar == null) return;

    _bar!.complete(message);
    _progress = ProgressInfo(
      message: message,
      percent: 100,
    );
    _bar = null;
  }

  @override
  void stop([String? message]) {
    if (_bar == null) return;

    if (message != null && _shouldShow()) {
      _bar!.fail(message);
    } else {
      _bar!.cancel();
    }
    _bar = null;
    _progress = null;
  }

  bool _shouldShow() {
    // Only show progress bar if stdout is a terminal
    return stdout.hasTerminal && !stdout.supportsAnsiEscapes == false;
  }
}

