/// Types of network connectivity.
/// 
/// This enum represents the different types of network connections
/// available on a device, independent of any specific connectivity library.
enum ConnectivityType {
  /// No network connection available
  none,

  /// Connected via WiFi
  wifi,

  /// Connected via mobile data (2G, 3G, 4G, 5G)
  mobile,

  /// Connected via Ethernet
  ethernet,

  /// Connected via Bluetooth
  bluetooth,

  /// Connected via other means
  other,

  /// Connected via VPN
  vpn,
}
