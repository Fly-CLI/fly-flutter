import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:foundation_project/core/foundation/logger/fly_logger.dart';
import 'package:foundation_project/core/services/device_condition_service.dart';

/// Network-specific connectivity service for async operations
/// 
/// Wraps DeviceConditionService to provide focused connectivity checking
/// for network operations, with real-time monitoring and connection state tracking
class ConnectivityService {
  final DeviceConditionService _deviceConditionService;
  final Logger _logger;

  ConnectivityService({
    DeviceConditionService? deviceConditionService,
    required Logger logger,
  })  : _deviceConditionService =
            deviceConditionService ?? DeviceConditionService(logger: logger),
        _logger = logger;

  /// Check if device has internet connection
  /// 
  /// Returns true if any internet connection is available (WiFi or mobile data)
  Future<bool> hasInternetConnection() async {
    try {
      final hasConnection = await _deviceConditionService.hasInternetConnection();
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
      final isWifi = await _deviceConditionService.isConnectedToWifi();
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
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final status = await _deviceConditionService.getConnectivityStatus();
      _logger.debug('Connectivity status: $status');
      return status;
    } catch (e) {
      _logger.warn('Failed to get connectivity status: $e');
      return ConnectivityResult.none;
    }
  }

  /// Stream of connectivity changes
  /// 
  /// Subscribe to be notified when network connection changes
  /// Returns a stream of connectivity results
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _deviceConditionService.onConnectivityChanged;
  }

  /// Check if the connection is suitable for network operations
  /// 
  /// [requireWifi] - If true, only WiFi connections are considered suitable
  /// [minBatteryLevel] - Minimum battery level required (0-100)
  /// [requireCharging] - If true, device must be charging
  /// 
  /// Useful for large operations like backups or bulk syncs
  Future<bool> isOptimalForNetworkOperation({
    bool requireWifi = false,
    int minBatteryLevel = 0,
    bool requireCharging = false,
  }) async {
    try {
      return await _deviceConditionService.isOptimalForBackup(
        requireWifi: requireWifi,
        minBatteryLevel: minBatteryLevel,
        requireCharging: requireCharging,
      );
    } catch (e) {
      _logger.warn('Failed to check optimal conditions: $e');
      return false;
    }
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
          !results.every((result) => result == ConnectivityResult.none);

      // For connected state, verify actual internet (not just WiFi connection)
      if (hasConnection) {
        return await hasInternetConnection();
      }

      return false;
    });
  }
}

