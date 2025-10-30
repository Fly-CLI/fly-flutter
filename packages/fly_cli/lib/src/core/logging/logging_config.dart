import 'package:fly_cli/src/core/logging/log_level.dart';
import 'package:fly_core/src/environment/environment_manager.dart';
import 'package:fly_core/src/environment/env_var.dart';

enum LogFormat { human, json }

class HttpLoggingConfig {
  const HttpLoggingConfig({this.endpoint, this.token});

  final Uri? endpoint;
  final String? token;

  bool get enabled => endpoint != null;
}

class SentryConfig {
  const SentryConfig({this.dsn, this.environment, this.release});

  final String? dsn;
  final String? environment;
  final String? release;

  bool get enabled => dsn != null && dsn!.isNotEmpty;
}

class DatadogConfig {
  const DatadogConfig({this.apiKey, this.site, this.minLevel = LogLevel.info});

  final String? apiKey;
  final String? site;
  final LogLevel minLevel;

  bool get enabled =>
      (apiKey != null && apiKey!.isNotEmpty) &&
      (site != null && site!.isNotEmpty);
}

class LoggingConfig {
  const LoggingConfig({
    required this.level,
    required this.format,
    this.logFile,
    this.color = true,
    this.trace = false,
    this.http = const HttpLoggingConfig(),
    this.sentry = const SentryConfig(),
    this.datadog = const DatadogConfig(),
  });

  final LogLevel level;
  final LogFormat format;
  final String? logFile;
  final bool color;
  final bool trace;
  final HttpLoggingConfig http;
  final SentryConfig sentry;
  final DatadogConfig datadog;

  factory LoggingConfig.fromEnvironment({required bool isProd}) {
    const manager = EnvironmentManager();
    final levelStr = manager.getString(
          EnvVar.flyLogLevel,
          defaultValue: isProd ? 'info' : 'debug',
        ) ?? (isProd ? 'info' : 'debug');
    final formatStr = manager.getString(
          EnvVar.flyLogFormat,
          defaultValue: isProd ? 'json' : 'human',
        ) ?? (isProd ? 'json' : 'human');
    final noColor = manager.getBool(EnvVar.flyNoColor, defaultValue: false);
    final httpEndpoint = manager.getString(EnvVar.flyLogHttpEndpoint);
    final httpToken = manager.getString(EnvVar.flyLogHttpToken);
    final sentryDsn = manager.getString(EnvVar.sentryDsn);
    final ddApiKey = manager.getString(EnvVar.ddApiKey);
    final ddSite = manager.getString(EnvVar.ddSite);

    return LoggingConfig(
      level: LogLevel.fromString(levelStr, fallback: LogLevel.info),
      format: formatStr.toLowerCase() == 'json'
          ? LogFormat.json
          : LogFormat.human,
      logFile: manager.getString(EnvVar.flyLogFile),
      color: !noColor && !isProd,
      trace: manager.getBool(EnvVar.flyLogTrace, defaultValue: false),
      http: HttpLoggingConfig(
        endpoint: httpEndpoint != null && httpEndpoint.isNotEmpty
            ? Uri.tryParse(httpEndpoint)
            : null,
        token: httpToken,
      ),
      sentry: SentryConfig(
        dsn: sentryDsn,
        environment: manager.getString(EnvVar.sentryEnvironment),
        release: manager.getString(EnvVar.sentryRelease),
      ),
      datadog: DatadogConfig(apiKey: ddApiKey, site: ddSite),
    );
  }

  LoggingConfig withOverrides({
    String? level,
    String? format,
    String? logFile,
    bool? noColor,
    bool? trace,
  }) {
    final nextLevel = level != null && level.isNotEmpty
        ? LogLevel.fromString(level, fallback: this.level)
        : this.level;
    final nextFormat = format != null && format.isNotEmpty
        ? (format.toLowerCase() == 'json' ? LogFormat.json : LogFormat.human)
        : this.format;
    return LoggingConfig(
      level: nextLevel,
      format: nextFormat,
      logFile: logFile ?? this.logFile,
      color: noColor == null ? color : !noColor,
      trace: trace ?? this.trace,
      http: http,
      sentry: sentry,
      datadog: datadog,
    );
  }
}
