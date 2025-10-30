import '../appender.dart';
import '../log_event.dart';
import '../log_level.dart';

class DatadogAppender implements Appender {
  DatadogAppender({this.apiKey, this.site, this.minLevel = LogLevel.info});

  final String? apiKey;
  final String? site; // e.g., datadoghq.com
  final LogLevel minLevel;

  @override
  String get name => 'datadog';

  bool get _enabled => (apiKey != null && apiKey!.isNotEmpty) && (site != null && site!.isNotEmpty);

  @override
  Future<void> append(LogEvent event) async {
    if (!_enabled) return;
    if (event.level.severity < minLevel.severity) return;
    // Placeholder: integrate Datadog intake if available.
    // Intentionally a no-op here to avoid external dependencies.
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> dispose() async {}
}


