import 'dart:convert';

import '../../domain/formatter.dart';
import '../../domain/log_event.dart';
import '../../domain/log_level.dart';

class HumanFormatter implements LogFormatter {
  HumanFormatter({this.color = true, this.includeStack = true});

  final bool color;
  final bool includeStack;

  @override
  FormatterOutputType get outputType => FormatterOutputType.human;

  @override
  String formatToString(LogEvent event) {
    final ts = event.timestamp.toIso8601String();
    final level = _colorize(_pad(event.level), _colorFor(event.level));
    final logger = event.loggerName != null ? '${event.loggerName} ' : '';
    final ctx = event.context?.toJson() ?? const {};
    final fields = event.fields.isNotEmpty
        ? ' ${jsonEncode(event.fields)}'
        : '';
    final ctxStr = ctx.isNotEmpty ? ' ${jsonEncode(ctx)}' : '';
    final base = '[$ts] $level $logger- ${event.message}$fields$ctxStr';

    if (event.error == null && event.stackTrace == null) return base;

    final err = event.error != null ? '\n  err: ${event.error}' : '';
    final stack = includeStack && event.stackTrace != null
        ? '\n  stack: ${event.stackTrace}'
        : '';
    return '$base$err$stack';
  }

  @override
  Map<String, Object?> formatToJson(LogEvent event) {
    return event.toJson();
  }

  String _pad(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return 'TRACE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return ' INFO';
      case LogLevel.warn:
        return ' WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.fatal:
        return 'FATAL';
    }
  }

  String _colorFor(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return '\u001b[37m'; // gray
      case LogLevel.debug:
        return '\u001b[36m'; // cyan
      case LogLevel.info:
        return '\u001b[32m'; // green
      case LogLevel.warn:
        return '\u001b[33m'; // yellow
      case LogLevel.error:
        return '\u001b[31m'; // red
      case LogLevel.fatal:
        return '\u001b[35m'; // magenta
    }
  }

  String _colorize(String text, String colorCode) {
    if (!color) return text;
    const reset = '\u001b[0m';
    return '$colorCode$text$reset';
  }
}
