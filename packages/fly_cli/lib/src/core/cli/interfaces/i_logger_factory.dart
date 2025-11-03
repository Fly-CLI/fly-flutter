import 'package:args/args.dart';
import 'package:fly_cli/src/core/logging/logger.dart' as flylog;

/// Interface for logger factory
///
/// This interface provides abstraction over the logger creation implementation,
/// allowing for easier testing and swapping of implementations.
abstract class ILoggerFactory {
  /// Create a root logger
  ///
  /// [isDevelopment] - Whether running in development mode
  /// [parsedArgs] - Optional parsed arguments for logger configuration
  /// [loggerName] - Optional logger name (defaults to 'fly')
  flylog.Logger createRootLogger({
    required bool isDevelopment,
    ArgResults? parsedArgs,
    String loggerName,
  });
}
