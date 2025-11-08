import 'dart:async';

import 'package:fly_logger/fly_logger.dart';
import 'package:fly_connectivity/fly_connectivity.dart';

/// Network-specific connectivity service for async operations
/// 
/// Provides focused connectivity checking for network operations,
/// with real-time monitoring and connection state tracking.
/// 
/// Uses [ConnectivityChecker] interface for pluggable connectivity implementations.
/// 
/// Applications must provide a [ConnectivityChecker] implementation.
class ConnectivityService {
  final ConnectivityChecker _checker;
  final FlyLogger _logger;

  ConnectivityService({
    required ConnectivityChecker checker,
    required FlyLogger logger,
  })  : _checker = checker,
        _logger = logger;

  /// Check if device has internet connection
  /// 
  /// Returns true if any internet connection is available (WiFi or mobile data)
  Future<bool> hasInternetConnection() async {
    try {
      final hasConnection = await _checker.hasInternetConnection();
      _logger.debug('Internet connection check: $hasConnection');
      return hasConnection;
    } catch (e) {
      _logger.warn('Failed to check internet connection: $e');
      // Conservative: assume no connection on error
      return false;
    }
  }

  /// Check if device is connected to WiFi specifically
  Future<bool> isConnectedToWifi() async {
    try {
      final isWifi = await _checker.isConnectedToWifi();
      _logger.debug('WiFi connection check: $isWifi');
      return isWifi;
    } catch (e) {
      _logger.warn('Failed to check WiFi connection: $e');
      return false;
    }
  }

  /// Get current connectivity status
  /// 
  /// Returns the type of connection (wifi, mobile, none, etc.)
  Future<ConnectivityType> getConnectivityStatus() async {
    try {
      final status = await _checker.getConnectivityStatus();
      _logger.debug('Connectivity status: $status');
      return status;
    } catch (e) {
      _logger.warn('Failed to get connectivity status: $e');
      return ConnectivityType.none;
    }
  }

  /// Stream of connectivity changes
  /// 
  /// Subscribe to be notified when network connection changes
  /// Returns a stream of connectivity types
  Stream<List<ConnectivityType>> get onConnectivityChanged {
    return _checker.onConnectivityChanged;
  }

  /// Wait for internet connection with timeout
  /// 
  /// Useful for operations that want to wait briefly for connection
  /// before failing. Returns true if connection becomes available.
  /// 
  /// [timeout] - Maximum time to wait for connection
  /// [pollInterval] - How often to check connection status
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(seconds: 1),
  }) async {
    _logger.debug('Waiting for connection (timeout: ${timeout.inSeconds}s)');

    final startTime = DateTime.now();
    while (DateTime.now().difference(startTime) < timeout) {
      if (await hasInternetConnection()) {
        _logger.debug('Connection acquired');
        return true;
      }
      await Future.delayed(pollInterval);
    }

    _logger.debug('Connection wait timeout');
    return false;
  }

  /// Create a stream controller that emits connection state changes
  /// 
  /// Returns a stream that emits true when connected, false when disconnected
  Stream<bool> createConnectionStateStream() {
    return onConnectivityChanged.asyncMap((results) async {
      // Check if any result indicates connectivity
      final hasConnection = results.isNotEmpty &&
          !results.every((result) => result == ConnectivityType.none);

      // For connected state, verify actual internet (not just WiFi connection)
      if (hasConnection) {
        return await hasInternetConnection();
      }

      return false;
    });
  }
}

