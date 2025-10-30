import 'dart:convert';

import 'package:fly_cli/src/core/logging/domain/formatter.dart';
import 'package:fly_cli/src/core/logging/domain/log_event.dart';

class JsonFormatter implements LogFormatter {
  const JsonFormatter();

  @override
  FormatterOutputType get outputType => FormatterOutputType.json;

  @override
  Map<String, Object?> formatToJson(LogEvent event) {
    return event.toJson();
  }

  @override
  String formatToString(LogEvent event) {
    return jsonEncode(formatToJson(event));
  }
}


