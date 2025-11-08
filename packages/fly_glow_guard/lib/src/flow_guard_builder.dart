part of 'flow_guard.dart';

/// Collection of override-able defaults used by [FlowGuard].
class FlowGuardDefaults {
  const FlowGuardDefaults({
    this.timeout,
    this.checkConnectivity,
    this.queueIfOffline,
    this.operationName,
    this.retryConfig,
  });

  final Duration? timeout;
  final bool? checkConnectivity;
  final bool? queueIfOffline;
  final String? operationName;
  final RetryConfig? retryConfig;

  bool get hasOverrides =>
      timeout != null ||
      checkConnectivity != null ||
      queueIfOffline != null ||
      operationName != null ||
      retryConfig != null;

  FlowGuardDefaults copyWith({
    Duration? timeout,
    bool? checkConnectivity,
    bool? queueIfOffline,
    String? operationName,
    RetryConfig? retryConfig,
  }) {
    return FlowGuardDefaults(
      timeout: timeout ?? this.timeout,
      checkConnectivity: checkConnectivity ?? this.checkConnectivity,
      queueIfOffline: queueIfOffline ?? this.queueIfOffline,
      operationName: operationName ?? this.operationName,
      retryConfig: retryConfig ?? this.retryConfig,
    );
  }
}

/// Fluent builder that offers full control over [FlowGuard] configuration.
class FlowGuardBuilder {
  FlyLogger? _logger;
  ConnectivityService? _connectivityService;
  ConnectivityChecker? _connectivityChecker;
  OfflineQueue? _offlineQueue;
  FoundationLocalizationProvider? _localizations;
  ErrorMessageFormatter? _errorMessageFormatter;

  Duration? _defaultTimeout;
  bool? _defaultCheckConnectivity;
  bool? _defaultQueueIfOffline;
  String? _defaultOperationName;
  RetryConfig? _defaultRetryConfig;

  FlowGuardBuilder logger(FlyLogger logger) {
    _logger = logger;
    return this;
  }

  FlowGuardBuilder connectivityService(ConnectivityService service) {
    _connectivityService = service;
    return this;
  }

  FlowGuardBuilder connectivityChecker(ConnectivityChecker checker) {
    _connectivityChecker = checker;
    return this;
  }

  FlowGuardBuilder offlineQueue(OfflineQueue offlineQueue) {
    _offlineQueue = offlineQueue;
    return this;
  }

  FlowGuardBuilder localizations(
    FoundationLocalizationProvider localizations,
  ) {
    _localizations = localizations;
    return this;
  }

  FlowGuardBuilder errorMessageFormatter(
    ErrorMessageFormatter formatter,
  ) {
    _errorMessageFormatter = formatter;
    return this;
  }

  FlowGuardBuilder defaultTimeout(Duration timeout) {
    _defaultTimeout = timeout;
    return this;
  }

  FlowGuardBuilder defaultCheckConnectivity(bool value) {
    _defaultCheckConnectivity = value;
    return this;
  }

  FlowGuardBuilder defaultQueueIfOffline(bool value) {
    _defaultQueueIfOffline = value;
    return this;
  }

  FlowGuardBuilder defaultOperationName(String name) {
    _defaultOperationName = name;
    return this;
  }

  FlowGuardBuilder defaultRetryConfig(RetryConfig? config) {
    _defaultRetryConfig = config;
    return this;
  }

  FlowGuard build() {
    final logger = _logger;
    if (logger == null) {
      throw StateError('FlyLogger must be provided before building FlowGuard.');
    }

    final defaults = FlowGuardDefaults(
      timeout: _defaultTimeout,
      checkConnectivity: _defaultCheckConnectivity,
      queueIfOffline: _defaultQueueIfOffline,
      operationName: _defaultOperationName,
      retryConfig: _defaultRetryConfig,
    );

    return FlowGuard(
      logger: logger,
      connectivityService: _connectivityService,
      connectivityChecker: _connectivityChecker,
      offlineQueue: _offlineQueue,
      localizations: _localizations,
      errorMessageFormatter: _errorMessageFormatter,
      defaults: defaults.hasOverrides ? defaults : null,
    );
  }
}

