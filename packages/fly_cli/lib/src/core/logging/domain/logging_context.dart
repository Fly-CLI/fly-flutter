// Captures per-command/request logging context that can be attached to events

typedef JsonMap = Map<String, Object?>;

class LoggingContext {
  LoggingContext({
    this.traceId,
    this.spanId,
    this.command,
    this.args,
    this.workspace,
    this.version,
    this.environment,
    this.featureFlags,
    JsonMap? extra,
  }) : extra = extra ?? <String, Object?>{};

  final String? traceId;
  final String? spanId;
  final String? command;
  final List<String>? args;
  final String? workspace;
  final String? version;
  final String? environment;
  final List<String>? featureFlags;
  final JsonMap extra;

  LoggingContext copyWith({
    String? traceId,
    String? spanId,
    String? command,
    List<String>? args,
    String? workspace,
    String? version,
    String? environment,
    List<String>? featureFlags,
    JsonMap? extra,
  }) {
    return LoggingContext(
      traceId: traceId ?? this.traceId,
      spanId: spanId ?? this.spanId,
      command: command ?? this.command,
      args: args ?? this.args,
      workspace: workspace ?? this.workspace,
      version: version ?? this.version,
      environment: environment ?? this.environment,
      featureFlags: featureFlags ?? this.featureFlags,
      extra: extra ?? Map<String, Object?>.from(this.extra),
    );
  }

  LoggingContext mergedWith(LoggingContext other) {
    return LoggingContext(
      traceId: other.traceId ?? traceId,
      spanId: other.spanId ?? spanId,
      command: other.command ?? command,
      args: other.args ?? args,
      workspace: other.workspace ?? workspace,
      version: other.version ?? version,
      environment: other.environment ?? environment,
      featureFlags: other.featureFlags ?? featureFlags,
      extra: {...extra, ...other.extra},
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      if (traceId != null) 'trace_id': traceId,
      if (spanId != null) 'span_id': spanId,
      if (command != null) 'command': command,
      if (args != null) 'args': args,
      if (workspace != null) 'workspace': workspace,
      if (version != null) 'version': version,
      if (environment != null) 'environment': environment,
      if (featureFlags != null) 'feature_flags': featureFlags,
      if (extra.isNotEmpty) 'ctx': extra,
    };
  }
}


