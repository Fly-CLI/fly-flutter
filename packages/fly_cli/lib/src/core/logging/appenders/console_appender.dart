import 'dart:io';

import 'package:fly_cli/src/core/logging/appender.dart';
import 'package:fly_cli/src/core/logging/formatter.dart';
import 'package:fly_cli/src/core/logging/log_event.dart';
import 'package:fly_cli/src/core/logging/log_level.dart';
import 'package:fly_core/src/environment/environment_manager.dart';

class ConsoleAppender implements Appender {
  ConsoleAppender(this.formatter, {this.quiet = false});

  final LogFormatter formatter;
  final bool quiet;

  @override
  String get name => 'console';

  @override
  Future<void> append(LogEvent event) async {
    if (quiet) return;
    final line = formatter.formatToString(event);
    final isErr = event.level.severity >= LogLevel.warn.severity;
    // In JSON output mode, route all logs to stderr to keep stdout clean for machine output
    final forceStderr = const EnvironmentManager().jsonOutputEnabled;
    final sink = (isErr || forceStderr) ? stderr : stdout;
    sink.writeln(line);
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> dispose() async {}
}


