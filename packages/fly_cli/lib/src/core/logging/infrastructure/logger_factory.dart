import 'package:fly_cli/src/core/logging/domain/appender.dart';
import 'package:fly_cli/src/core/logging/domain/logger.dart';
import 'package:fly_cli/src/core/logging/domain/logging_context.dart';
import 'package:fly_cli/src/core/logging/infrastructure/appenders/console_appender.dart';
import 'package:fly_cli/src/core/logging/infrastructure/appenders/datadog_appender.dart';
import 'package:fly_cli/src/core/logging/infrastructure/appenders/file_appender.dart';
import 'package:fly_cli/src/core/logging/infrastructure/appenders/http_appender.dart';
import 'package:fly_cli/src/core/logging/infrastructure/appenders/sentry_appender.dart';
import 'package:fly_cli/src/core/logging/infrastructure/formatters/human_formatter.dart';
import 'package:fly_cli/src/core/logging/infrastructure/formatters/json_formatter.dart';
import 'package:fly_cli/src/core/logging/infrastructure/logger_impl.dart';
import 'package:fly_cli/src/core/logging/infrastructure/logging_config.dart';

class LoggerFactory {
  LoggerFactory(this.config, {this.baseContext, this.name});

  final LoggingConfig config;
  final LoggingContext? baseContext;
  final String? name;

  Logger createRoot() {
    final formatter = config.format == LogFormat.json
        ? const JsonFormatter()
        : HumanFormatter(color: config.color);

    final appenders = <Appender>[ConsoleAppender(formatter, quiet: false)];

    if (config.logFile != null && config.logFile!.isNotEmpty) {
      appenders.add(FileAppender(formatter, path: config.logFile!));
    }
    if (config.http.enabled && config.http.endpoint != null) {
      appenders.add(
        HttpAppender(
          formatter,
          endpoint: config.http.endpoint!,
          token: config.http.token,
        ),
      );
    }
    if (config.sentry.enabled) {
      appenders.add(
        SentryAppender(
          dsn: config.sentry.dsn,
          environment: config.sentry.environment,
          release: config.sentry.release,
        ),
      );
    }
    if (config.datadog.enabled) {
      appenders.add(
        DatadogAppender(
          apiKey: config.datadog.apiKey,
          site: config.datadog.site,
          minLevel: config.datadog.minLevel,
        ),
      );
    }

    return LoggerImpl(
      appenders: appenders,
      minLevel: config.level,
      context: baseContext,
      name: name,
    );
  }
}
