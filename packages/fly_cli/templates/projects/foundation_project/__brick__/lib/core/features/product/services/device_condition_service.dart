import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:{{project_name_snake}}/core/foundation/utils/app_logger.dart';

/// Simplified device condition service for foundation project
/// Provides connectivity checking and device condition monitoring
class DeviceConditionService {
  final Connectivity _connectivity = Connectivity();
  final AppLogger _logger = AppLogger('DeviceConditionService');
  StreamController<List<ConnectivityResult>>? _connectivityController;

  DeviceConditionService() {
    _initConnectivityStream();
  }

  void _initConnectivityStream() {
    _connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
    _connectivity.onConnectivityChanged.listen((results) {
      _connectivityController?.add(results);
    });
  }

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty &&
          !results.every((result) => result == ConnectivityResult.none);
    } catch (e) {
      _logger.warning('Failed to check internet connection: $e');
      return false;
    }
  }

  /// Check if device is connected to WiFi
  Future<bool> isConnectedToWifi() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      _logger.warning('Failed to check WiFi connection: $e');
      return false;
    }
  }

  /// Get current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty) return ConnectivityResult.none;
      return results.first;
    } catch (e) {
      _logger.warning('Failed to get connectivity status: $e');
      return ConnectivityResult.none;
    }
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivityController?.stream ?? const Stream.empty();
  }

  /// Check if conditions are optimal for backup operations
  /// Simplified version for foundation project
  Future<bool> isOptimalForBackup({
    bool requireWifi = false,
    int minBatteryLevel = 0,
    bool requireCharging = false,
  }) async {
    try {
      if (requireWifi) {
        return await isConnectedToWifi();
      }
      return await hasInternetConnection();
    } catch (e) {
      _logger.warning('Failed to check optimal conditions: $e');
      return false;
    }
  }

  void dispose() {
    _connectivityController?.close();
    _connectivityController = null;
  }
}

