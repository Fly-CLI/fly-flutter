import 'log_event.dart';

enum FormatterOutputType { human, json }

abstract class LogFormatter {
  FormatterOutputType get outputType;

  // Returns a human-readable string representation of the event.
  String formatToString(LogEvent event);

  // Returns a structured JSON-serializable map for the event.
  Map<String, Object?> formatToJson(LogEvent event);
}


