import 'package:fly_foundation_planning/src/utils/logger.dart';
import 'package:mason_logger/mason_logger.dart';

/// Adapter to convert CLI Logger to PlanningLogger.
///
/// This adapter allows the planning library to use the CLI's logger
/// without depending on CLI-specific types.
class PlanningLoggerAdapter implements PlanningLogger {
  final Logger _logger;

  /// Creates an adapter that wraps the given CLI [logger].
  PlanningLoggerAdapter(this._logger);

  @override
  void info(String message) => _logger.info(message);

  @override
  void warn(String message) => _logger.warn(message);

  @override
  void err(String message) => _logger.err(message);

  @override
  void detail(String message) => _logger.warn(message);
}

