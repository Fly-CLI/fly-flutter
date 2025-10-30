import 'log_event.dart';

abstract class Appender {
  String get name;

  Future<void> append(LogEvent event);

  Future<void> flush() async {}

  Future<void> dispose() async {}
}


