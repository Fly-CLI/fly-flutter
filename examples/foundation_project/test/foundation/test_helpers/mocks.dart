import 'package:fly_connectivity/fly_connectivity.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_localization/fly_localization.dart';
import 'package:fly_flow_guard/fly_flow_guard.dart';
import 'dart:async';

/// Mock implementation of FlyLogger for testing
class MockFlyLogger implements FlyLogger {
  final List<String> _logMessages = [];
  final List<LogLevel> _logLevels = [];
  final List<LogFields> _logFields = [];
  final List<Object?> _errors = [];
  final List<StackTrace?> _stackTraces = [];

  @override
  final String name;

  MockFlyLogger([this.name = 'MockLogger']);

  List<String> get logMessages => List.unmodifiable(_logMessages);
  List<LogLevel> get logLevels => List.unmodifiable(_logLevels);
  List<LogFields> get logFields => List.unmodifiable(_logFields);
  List<Object?> get errors => List.unmodifiable(_errors);
  List<StackTrace?> get stackTraces => List.unmodifiable(_stackTraces);

  void clear() {
    _logMessages.clear();
    _logLevels.clear();
    _logFields.clear();
    _errors.clear();
    _stackTraces.clear();
  }

  @override
  FlyLogger child(LogFields fields) {
    return MockFlyLogger('$name.child');
  }

  @override
  FlyLogger withFields(LogFields fields) {
    return this;
  }

  @override
  void log(
    LogLevel level,
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    // Resolve message if it's a builder function
    final String messageStr = message is LogMessageBuilder
        ? message()
        : message.toString();
    
    _logMessages.add(messageStr);
    _logLevels.add(level);
    if (fields != null) _logFields.add(fields);
    if (error != null) _errors.add(error);
    if (stackTrace != null) _stackTraces.add(stackTrace);
  }

  @override
  void trace(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(LogLevel.trace, message, error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void debug(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(LogLevel.debug, message, error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void info(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(LogLevel.info, message, error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void warn(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(LogLevel.warn, message, error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void error(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  void fatal(
    Object message, {
    Object? error,
    StackTrace? stackTrace,
    LogFields? fields,
  }) {
    log(LogLevel.fatal, message, error: error, stackTrace: stackTrace, fields: fields);
  }

  @override
  bool isEnabled(LogLevel level) => true; // Always enabled for testing
}

/// Mock implementation of ErrorReporter for testing
class MockErrorReporter implements ErrorReporter {
  final List<Object> _errors = [];
  final List<StackTrace?> _stackTraces = [];
  final List<String?> _reasons = [];
  final List<Map<String, String>?> _customKeys = [];

  List<Object> get errors => List.unmodifiable(_errors);
  List<StackTrace?> get stackTraces => List.unmodifiable(_stackTraces);
  List<String?> get reasons => List.unmodifiable(_reasons);
  List<Map<String, String>?> get customKeys => List.unmodifiable(_customKeys);

  void clear() {
    _errors.clear();
    _stackTraces.clear();
    _reasons.clear();
    _customKeys.clear();
  }

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, String>? customKeys,
  }) {
    _errors.add(error);
    _stackTraces.add(stackTrace);
    _reasons.add(reason);
    _customKeys.add(customKeys);
  }
}

/// Mock implementation of ConnectivityChecker for testing
class MockConnectivityChecker implements ConnectivityChecker {
  bool _hasInternetConnection = true;
  bool _isConnectedToWifi = false;
  ConnectivityType _connectivityStatus = ConnectivityType.mobile;

  MockConnectivityChecker({
    bool hasInternetConnection = true,
    bool isConnectedToWifi = false,
    ConnectivityType connectivityStatus = ConnectivityType.mobile,
  })  : _hasInternetConnection = hasInternetConnection,
        _isConnectedToWifi = isConnectedToWifi,
        _connectivityStatus = connectivityStatus;

  void setHasInternetConnection(bool value) {
    _hasInternetConnection = value;
  }

  void setIsConnectedToWifi(bool value) {
    _isConnectedToWifi = value;
  }

  void setConnectivityStatus(ConnectivityType value) {
    _connectivityStatus = value;
  }

  @override
  Future<bool> hasInternetConnection() async => _hasInternetConnection;

  @override
  Future<bool> isConnectedToWifi() async => _isConnectedToWifi;

  @override
  Future<ConnectivityType> getConnectivityStatus() async => _connectivityStatus;

  @override
  Stream<List<ConnectivityType>> get onConnectivityChanged {
    return Stream.value([_connectivityStatus]);
  }
}

/// Mock implementation of FoundationLocalizationProvider for testing
class MockFoundationLocalizationProvider implements FoundationLocalizationProvider {
  @override
  String get networkErrorConnectionRecovery => 'Connection failed. Please try again.';

  @override
  String get networkErrorTimeoutRecovery => 'Request timed out. Please try again.';

  @override
  String get networkErrorDnsRecovery => 'DNS lookup failed. Please check your connection.';

  @override
  String get networkErrorNoInternetRecovery => 'No internet connection. Please check your network.';

  @override
  String get networkErrorAuthRecovery => 'Authentication failed. Please log in again.';

  @override
  String get networkErrorNotFoundRecovery => 'Resource not found.';

  @override
  String get networkErrorRateLimitRecovery => 'Too many requests. Please try again later.';

  @override
  String get networkErrorServerRecovery => 'Server error. Please try again later.';

  @override
  String get networkErrorCertificateRecovery => 'Certificate error. Please check your connection.';

  @override
  String get networkErrorUnknownRecovery => 'Unknown network error occurred.';

  @override
  String get networkErrorHttpRecovery => 'HTTP error occurred.';

  @override
  String get networkConnectionFailed => 'Connection failed';

  @override
  String get networkNoInternet => 'No internet connection';

  @override
  String get networkTimeout => 'Request timed out';

  @override
  String get networkDnsFailed => 'DNS lookup failed';

  @override
  String get networkCaptivePortal => 'Captive portal detected';

  @override
  String get networkCertificateError => 'Certificate error';

  @override
  String get networkUnknownError => 'Unknown network error';

  @override
  String get networkHttpClientError => 'Client error';

  @override
  String get networkHttpServerError => 'Server error';

  @override
  String get operationTimedOut => 'Operation timed out';

  @override
  String get invalidResponseFormat => 'Invalid response format';

  @override
  String get databaseErrorPleaseTryAgain => 'Database error. Please try again.';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get noInternetConnectionQueuedShort => 'No internet. Operation queued.';

  @override
  String get noInternetConnectionQueuedLong => 'No internet connection. Operation has been queued and will be executed when connection is restored.';

  @override
  String get networkOperationFailedAfterRetries => 'Network operation failed after retries';

  @override
  String get networkOperationDefault => 'Network operation failed';

  @override
  String get unexpectedErrorOccurred => 'An unexpected error occurred';
}

/// Mock implementation of OfflineQueue for testing
class MockOfflineQueue implements OfflineQueue {
  final List<QueuedOperation<Object>> _operations = [];
  bool _shouldSucceed = true;

  List<QueuedOperation<Object>> get operations => List.unmodifiable(_operations);

  void setShouldSucceed(bool value) {
    _shouldSucceed = value;
  }

  void clear() {
    _operations.clear();
  }

  @override
  Future<bool> enqueue<T>(QueuedOperation<T> operation) async {
    _operations.add(operation as QueuedOperation<Object>);
    return _shouldSucceed;
  }

  @override
  Future<void> processQueue() async {
    // Mock implementation
  }

  @override
  Stream<QueuedOperation<Object>> get queueStream {
    if (_operations.isEmpty) {
      return Stream<QueuedOperation<Object>>.empty();
    }
    return Stream.fromIterable(_operations);
  }
}

