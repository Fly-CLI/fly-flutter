import 'package:fly_brick_composer/src/utils/logger.dart';
import 'package:mason_logger/mason_logger.dart';

/// Adapter to convert CLI Logger to ComposerLogger.
///
/// This adapter allows the composer library to use the CLI's logger
/// without depending on CLI-specific types.
class ComposerLoggerAdapter implements ComposerLogger {
  final Logger _logger;

  /// Creates an adapter that wraps the given CLI [logger].
  ComposerLoggerAdapter(this._logger);

  @override
  void info(String message) => _logger.info(message);

  @override
  void warn(String message) => _logger.warn(message);

  @override
  void err(String message) => _logger.err(message);

  @override
  void detail(String message) => _logger.warn(message);
}
