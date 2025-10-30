# Fly CLI Logging System

A reusable, structured, multi-level logging system for Fly CLI and future services. It supports
human-friendly output in development, structured JSON in production, optional remote shipping,
context propagation, redaction, and basic sampling/throttling.

## Highlights

- Multi-level: trace, debug, info, warn, error, fatal
- Context-aware: command args, version, environment, trace/span IDs
- Dev vs Prod formats: color human text (dev), JSON lines (prod)
- Pluggable appenders: console, file (with rotation), HTTP, Sentry, Datadog
- Redaction by default; sampling and duplicate suppression available
- Config via ENV (and flags later), with safe defaults

## Package Layout

- `domain/`
  - `log_level.dart`, `log_event.dart`, `logging_context.dart`, `logger.dart`, `appender.dart`,
    `formatter.dart`
- `infrastructure/`
  - `logger_impl.dart`, `logger_factory.dart`, `logging_config.dart`, `redaction_policy.dart`
  - `formatters/`: `human_formatter.dart`, `json_formatter.dart`
  - `appenders/`: `console_appender.dart`, `file_appender.dart`, `http_appender.dart`,
    `sentry_appender.dart`, `datadog_appender.dart`

## Quick Start
```dart
import 'package:fly_cli/src/core/logging/infrastructure/logging_config.dart';
import 'package:fly_cli/src/core/logging/infrastructure/logger_factory.dart';
import 'package:fly_cli/src/core/logging/domain/logging_context.dart';

final isProd = bool.fromEnvironment('dart.vm.product');
final cfg = LoggingConfig.fromEnvironment(isProd: isProd);
final baseCtx = LoggingContext(environment: isProd ? 'production' : 'development');
final logger = LoggerFactory(cfg, baseContext: baseCtx, name: 'fly').createRoot();

final cmdLogger = logger.child({'command': 'example', 'args': ['--foo']});
cmdLogger.info('Starting');
try {
  // ...
  cmdLogger.debug('Intermediate step', fields: {'step': 2});
} catch (e, st) {
  cmdLogger.error('Failed', error: e, stackTrace: st);
}
cmdLogger.info('Done');
```

## Log Levels
- `trace`: Very detailed, internal tracing
- `debug`: Developer diagnostics
- `info`: High-level lifecycle and normal operations
- `warn`: Non-fatal anomalies
- `error`: Failures requiring attention
- `fatal`: Process-terminating or critical failures

## Formatters
- `HumanFormatter`
  - Colorized, aligned, with optional stack traces
  - Default in development
- `JsonFormatter`
  - Stable keys: `ts`, `level`, `msg`, `logger`, `fields`, `trace_id`, `span_id`, `err`, `stack`
  - Default in production

## Appenders
- `ConsoleAppender`: Writes to stdout/stderr (warn+ to stderr)
- `FileAppender`: Appends to file with size-based rotation
- `HttpAppender`: Sends JSON events to an HTTP endpoint (best-effort, backoff)
- `SentryAppender`: No-op unless `SENTRY_DSN` set; forwards error/fatal
- `DatadogAppender`: No-op unless `DD_API_KEY` and `DD_SITE` set

## Configuration (ENV)
- Core
  - `FLY_LOG_LEVEL` = `trace|debug|info|warn|error|fatal`
  - `FLY_LOG_FORMAT` = `human|json`
  - `FLY_LOG_FILE` = path to log file
  - `FLY_NO_COLOR` = `true|false`
  - `FLY_LOG_TRACE` = include extra stack/detail `true|false`
- Remote HTTP
  - `FLY_LOG_HTTP_ENDPOINT` = URL (e.g., https://logs.example.com/ingest)
  - `FLY_LOG_HTTP_TOKEN` = bearer token (optional)
- Sentry
  - `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `SENTRY_RELEASE`
- Datadog
  - `DD_API_KEY`, `DD_SITE` (e.g., `datadoghq.com`)
- Shipping Kill Switch
  - `FLY_LOG_SHIP` = `0|1` (see Telemetry & Privacy)

`LoggingConfig.fromEnvironment(isProd: ...)` populates defaults: dev → human/debug; prod → json/info.

## Context and Fields
- Use `Logger.child({...})` to attach persistent contextual fields.
- Use `withFields({...})` for one-off additional fields.
- `LoggingContext` includes environment, version, command, args, workspace, feature flags, and custom extras.

## Redaction, Sampling, Throttling
- `RedactionPolicy` scrubs common secret keys/values before output.
- Sampling can be configured per level (e.g., `debug: 0.25` in prod).
- Duplicate suppression suppresses repeated identical log lines for a short window.

## Telemetry & Privacy (Recommended Approach)
- Off by default: no remote shipping unless explicitly enabled.
- Vendor optional: remote appenders (Sentry/Datadog) are adapters, not requirements.
- Single kill switch: set `FLY_LOG_SHIP=1` to allow remote appenders to activate; `0` (default) disables them.
- Provider activation:
  - Sentry only if `SENTRY_DSN` is set.
  - Datadog only if `DD_API_KEY` and `DD_SITE` are set.
  - Generic HTTP only if `FLY_LOG_HTTP_ENDPOINT` is set.
- Redaction always on, error logs unsampled, non-error logs can be sampled in prod.
- Maintainers should set secrets in CI, never in the repo. Provide a `.env.example` without secrets.

Example `.env.example`:
```
FLY_LOG_LEVEL=info
FLY_LOG_FORMAT=json
FLY_LOG_SHIP=0
# Optional vendor settings (leave empty in repo)
SENTRY_DSN=
DD_API_KEY=
DD_SITE=datadoghq.com
# Vendor-neutral HTTP endpoint
FLY_LOG_HTTP_ENDPOINT=
FLY_LOG_HTTP_TOKEN=
```

## Integration in Fly CLI
- The root logger is created in `command_runner.dart` using `LoggerFactory` and is injected via the service container.
- The CLI logs start/finish events and structured unhandled errors with args and version metadata.

## Testing
- Golden tests for `HumanFormatter` and `JsonFormatter` across levels, with/without error/stack.
- Unit tests for rotation, HTTP backoff, redaction, sampling, and duplicate suppression.
- Integration tests: run commands with flags/env and assert outputs.

## Migration Guidance
- Use `LoggerAdapter` to mirror messages to both `mason_logger` and the structured logger during transition.
- Replace direct `mason_logger` calls gradually with structured logging calls.

## FAQ
- Q: Why JSON in production?
  - A: Machine-parseable logs are easier to search, aggregate, alert on, and ingest.
- Q: Does this send telemetry by default?
  - A: No. Remote shipping is opt-in and gated by `FLY_LOG_SHIP=1` plus provider-specific env vars.
- Q: Can I self-host?
  - A: Yes. Use `HttpAppender` with any endpoint (ELK/OpenSearch/OpenObserve/Loki-compatible gateways).


