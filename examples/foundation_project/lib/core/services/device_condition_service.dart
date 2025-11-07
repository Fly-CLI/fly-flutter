import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:foundation_project/foundation/logger/fly_logger.dart';

/// Service for checking device conditions for backups and other operations
///
/// Provides unified interface for checking:
/// - Network connectivity (WiFi, mobile data, none)
/// - Battery level
/// - Charging status
/// - Overall device readiness for resource-intensive operations
class DeviceConditionService {
  final Logger _logger;
  final Connectivity _connectivity;
  final Battery _battery;

  DeviceConditionService({
    required Logger logger,
    Connectivity? connectivity,
    Battery? battery,
  })  : _logger = logger,
        _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery();

  /// Check if device is connected to WiFi
  Future<bool> isConnectedToWifi() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      _logger.warn('Failed to check WiFi status: $e');
      return false;
    }
  }

  /// Check if device has any internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty &&
          !results.every((result) => result == ConnectivityResult.none);
    } catch (e) {
      _logger.warn('Failed to check internet connection: $e');
      return false;
    }
  }

  /// Get current connectivity status
  ///
  /// Returns the first connectivity result from the list
  /// Note: In connectivity_plus 5.0+, devices can have multiple connections
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      _logger.warn('Failed to get connectivity status: $e');
      return ConnectivityResult.none;
    }
  }

  /// Get battery level (0-100)
  ///
  /// Note: Returns 100 if battery info cannot be retrieved
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      _logger.warn('Failed to get battery level: $e');
      return 100; // Assume fully charged on error
    }
  }

  /// Check if device is charging
  ///
  /// Note: Returns false if charging status cannot be retrieved
  Future<bool> isCharging() async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging || state == BatteryState.full;
    } catch (e) {
      _logger.warn('Failed to check charging status: $e');
      return false;
    }
  }

  /// Check if conditions are optimal for backup operations
  ///
  /// [requireWifi] - If true, requires WiFi connection (not mobile data)
  /// [minBatteryLevel] - Minimum battery percentage required (0-100)
  /// [requireCharging] - If true, device must be charging
  ///
  /// Returns true only if all specified conditions are met
  Future<bool> isOptimalForBackup({
    bool requireWifi = false,
    int minBatteryLevel = 0,
    bool requireCharging = false,
  }) async {
    try {
      // Check network connectivity
      if (requireWifi) {
        final hasWifi = await isConnectedToWifi();
        if (!hasWifi) {
          _logger.debug('Not optimal for backup: WiFi not available');
          return false;
        }
      } else {
        final hasInternet = await hasInternetConnection();
        if (!hasInternet) {
          _logger.debug('Not optimal for backup: No internet connection');
          return false;
        }
      }

      // Check battery level
      if (minBatteryLevel > 0) {
        final batteryLevel = await getBatteryLevel();
        if (batteryLevel < minBatteryLevel) {
          _logger.debug(
            'Not optimal for backup: Battery too low ($batteryLevel% < $minBatteryLevel%)',
          );
          return false;
        }
      }

      // Check charging status
      if (requireCharging) {
        final charging = await isCharging();
        if (!charging) {
          _logger.debug('Not optimal for backup: Device not charging');
          return false;
        }
      }

      _logger.debug('Device conditions optimal for backup');
      return true;
    } catch (e) {
      _logger.warn('Failed to check device conditions: $e');
      return false;
    }
  }

  /// Stream of connectivity changes
  ///
  /// Subscribe to this stream to get notified when connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

