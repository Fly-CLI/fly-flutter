import 'package:fly_cli/src/core/logging/logger.dart' as flylog;
import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:mason_logger/mason_logger.dart' as mason;

/// A mason_logger-compatible adapter that mirrors all user-facing log calls
/// to the structured logging pipeline.
///
/// This class preserves the existing mason_logger UX (colors, prompts,
/// progress, spinners, etc.) while ensuring every message is also emitted to
/// the structured `flylog.Logger` for machine-readable logs, metrics, and
/// remote shipping.
///
/// Behavior:
/// - `info/warn/err/detail` forward to the wrapped mason `Logger` first, then
///   emit the same message at an appropriate level to `flylog.Logger`.
/// - Null messages are ignored by the structured logger to match mason APIs
///   that accept `String?`.
/// - Only basic text methods are overridden; prompts/progress methods are
///   inherited untouched to retain mason UX semantics.
class StructuredMasonLogger extends mason.Logger {
  StructuredMasonLogger(this._inner, this._structured)
    : super(theme: _inner.theme, level: _inner.level);

  final mason.Logger _inner;
  final flylog.Logger _structured;

  @override
  void info(String? message, {mason.LogStyle? style}) {
    final jsonMode = const EnvironmentManager().jsonOutputEnabled;
    if (!jsonMode) {
      _inner.info(message, style: style);
    }
    if (message != null) {
      _structured.info(message);
    }
  }

  @override
  void warn(String? message, {String tag = 'WARN', mason.LogStyle? style}) {
    final jsonMode = const EnvironmentManager().jsonOutputEnabled;
    if (!jsonMode) {
      _inner.warn(message, tag: tag, style: style);
    }
    if (message != null) {
      _structured.warn(message);
    }
  }

  @override
  void err(String? message, {mason.LogStyle? style}) {
    final jsonMode = const EnvironmentManager().jsonOutputEnabled;
    if (!jsonMode) {
      _inner.err(message, style: style);
    }
    if (message != null) {
      _structured.error(message);
    }
  }

  @override
  void detail(String? message, {mason.LogStyle? style}) {
    final jsonMode = const EnvironmentManager().jsonOutputEnabled;
    if (!jsonMode) {
      _inner.detail(message, style: style);
    }
    if (message != null) {
      _structured.debug(message);
    }
  }
}
