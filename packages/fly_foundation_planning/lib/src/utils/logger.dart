/// Simple logger interface for planning operations.
///
/// This is a minimal interface that can be implemented by any logging system.
abstract class PlanningLogger {
  void info(String message);
  void warn(String message);
  void err(String message);
  void detail(String message);
}

/// No-op logger that discards all messages.
class NoOpLogger implements PlanningLogger {
  const NoOpLogger();

  @override
  void info(String message) {}

  @override
  void warn(String message) {}

  @override
  void err(String message) {}

  @override
  void detail(String message) {}
}

