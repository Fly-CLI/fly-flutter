import 'package:fly_cli/src/core/logging/domain/appender.dart';
import 'package:fly_cli/src/core/logging/domain/log_event.dart';
import 'package:fly_cli/src/core/logging/domain/log_level.dart';

class SentryAppender implements Appender {
  SentryAppender({required this.dsn, this.environment, this.release});

  final String? dsn;
  final String? environment;
  final String? release;

  @override
  String get name => 'sentry';

  bool get _enabled => dsn != null && dsn!.isNotEmpty;

  @override
  Future<void> append(LogEvent event) async {
    if (!_enabled) return;
    if (event.level.severity < LogLevel.error.severity) return;
    // Placeholder: integrate Sentry SDK if available.
    // Intentionally a no-op here to avoid external dependencies.
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> dispose() async {}
}


