import 'package:fly_connectivity/src/connectivity_type.dart';

/// Abstract interface for connectivity checking services.
/// 
/// This interface allows the foundation to check network connectivity
/// without creating hard dependencies on specific implementations.
/// 
/// Applications should provide their own implementations of this interface.
/// 
/// **Example:**
/// ```dart
/// class CustomConnectivityChecker implements ConnectivityChecker {
///   @override
///   Future<bool> hasInternetConnection() async {
///     // Custom implementation
///   }
///   
///   // Implement other methods...
/// }
/// ```
abstract class ConnectivityChecker {
  /// Checks if the device has an internet connection.
  /// 
  /// Returns `true` if any internet connection is available
  /// (WiFi or mobile data), `false` otherwise.
  Future<bool> hasInternetConnection();

  /// Checks if the device is connected to WiFi specifically.
  /// 
  /// Returns `true` if connected to WiFi, `false` otherwise.
  Future<bool> isConnectedToWifi();

  /// Gets the current connectivity status.
  /// 
  /// Returns the type of connection (wifi, mobile, none, etc.)
  Future<ConnectivityType> getConnectivityStatus();

  /// Stream of connectivity changes.
  /// 
  /// Subscribe to be notified when network connection changes.
  /// Returns a stream of connectivity types.
  Stream<List<ConnectivityType>> get onConnectivityChanged;
}
