// Defines log severity levels and helpers

enum LogLevel {
  trace(10),
  debug(20),
  info(30),
  warn(40),
  error(50),
  fatal(60);

  const LogLevel(this.severity);
  final int severity;

  bool operator <(LogLevel other) => severity < other.severity;
  bool operator <=(LogLevel other) => severity <= other.severity;
  bool operator >(LogLevel other) => severity > other.severity;
  bool operator >=(LogLevel other) => severity >= other.severity;

  @override
  String toString() => name;

  static LogLevel fromString(String value, {LogLevel fallback = LogLevel.info}) {
    switch (value.toLowerCase().trim()) {
      case 'trace':
        return LogLevel.trace;
      case 'debug':
        return LogLevel.debug;
      case 'info':
        return LogLevel.info;
      case 'warn':
      case 'warning':
        return LogLevel.warn;
      case 'error':
        return LogLevel.error;
      case 'fatal':
      case 'critical':
        return LogLevel.fatal;
      default:
        return fallback;
    }
  }
}


