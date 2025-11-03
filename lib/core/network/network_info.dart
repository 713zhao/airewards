/// Abstract interface for network information
abstract class NetworkInfo {
  /// Check if device is connected to internet
  Future<bool> get isConnected;
  
  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream;
  
  /// Get current connection type
  Future<ConnectionType> get connectionType;
  
  /// Check if connection is mobile/cellular
  Future<bool> get isMobileConnection;
  
  /// Check if connection is WiFi
  Future<bool> get isWiFiConnection;
}

/// Types of network connections
enum ConnectionType {
  none,
  mobile,
  wifi,
  ethernet,
  bluetooth,
  vpn,
  other,
}