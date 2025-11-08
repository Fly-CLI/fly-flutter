import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_connectivity/fly_connectivity.dart';

/// Default implementation of [ConnectivityChecker] using `connectivity_plus` package.
/// 
/// This implementation provides basic connectivity checking functionality
/// by wrapping the `connectivity_plus` package and converting its types
/// to foundation-agnostic types.
/// 
/// **Example:**
/// ```dart
/// final checker = DefaultConnectivityChecker(logger: logger);
/// final hasConnection = await checker.hasInternetConnection();
/// ```
class DefaultConnectivityChecker implements ConnectivityChecker {
  final FlyLogger _logger;
  final Connectivity _connectivity = Connectivity();

  /// Creates a [DefaultConnectivityChecker] instance.
  /// 
  /// [logger] - Logger instance for logging connectivity checks
  DefaultConnectivityChecker({required FlyLogger logger}) : _logger = logger;

  /// Converts ConnectivityResult from connectivity_plus to ConnectivityType
  ConnectivityType _convertConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.none:
        return ConnectivityType.none;
      case ConnectivityResult.wifi:
        return ConnectivityType.wifi;
      case ConnectivityResult.mobile:
        return ConnectivityType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectivityType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectivityType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectivityType.vpn;
      case ConnectivityResult.other:
        return ConnectivityType.other;
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.isNotEmpty &&
          !results.every((result) => result == ConnectivityResult.none);
      _logger.debug('Internet connection check: $hasConnection');
      return hasConnection;
    } catch (e) {
      _logger.warn('Failed to check internet connection: $e');
      return false;
    }
  }

  @override
  Future<bool> isConnectedToWifi() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final isWifi = results.contains(ConnectivityResult.wifi);
      _logger.debug('WiFi connection check: $isWifi');
      return isWifi;
    } catch (e) {
      _logger.warn('Failed to check WiFi connection: $e');
      return false;
    }
  }

  @override
  Future<ConnectivityType> getConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Return the first result, or none if empty
      final status = results.isNotEmpty
          ? _convertConnectivityResult(results.first)
          : ConnectivityType.none;
      _logger.debug('Connectivity status: $status');
      return status;
    } catch (e) {
      _logger.warn('Failed to get connectivity status: $e');
      return ConnectivityType.none;
    }
  }

  @override
  Stream<List<ConnectivityType>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.map(_convertConnectivityResult).toList(),
    );
  }
}

