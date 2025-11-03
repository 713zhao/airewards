import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'network_info.dart';

/// Connectivity service implementation
@LazySingleton(as: NetworkInfo)
class ConnectivityService implements NetworkInfo {
  final Connectivity _connectivity;
  late StreamController<bool> _connectivityController;
  late Stream<bool> _connectivityStream;
  bool _isConnected = false;

  ConnectivityService(this._connectivity) {
    _connectivityController = StreamController<bool>.broadcast();
    _connectivityStream = _connectivityController.stream;
    _initializeConnectivity();
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      });
      
      // Get initial connectivity status
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('❌ Error initializing connectivity: $e');
      _isConnected = false;
      _connectivityController.add(false);
    }
  }

  /// Update connection status based on connectivity results
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    final bool wasConnected = _isConnected;
    
    // Check if any connection type indicates internet access
    _isConnected = results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );

    // Verify actual internet connectivity if connection is available
    if (_isConnected) {
      _isConnected = await _verifyInternetAccess();
    }

    // Notify listeners only if status changed
    if (_isConnected != wasConnected) {
      _connectivityController.add(_isConnected);
      debugPrint('🌐 Connection status changed: ${_isConnected ? "Connected" : "Disconnected"}');
    }
  }

  /// Verify actual internet access by pinging a reliable server
  Future<bool> _verifyInternetAccess() async {
    try {
      if (kIsWeb) {
        // For web, skip internet verification to avoid CORS issues
        // Connectivity status from connectivity_plus is sufficient for web
        debugPrint('🌐 Web platform - skipping internet verification');
        return true;
      } else {
        // For mobile, use InternetAddress.lookup
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (e) {
      debugPrint('⚠️  Internet verification failed: $e');
      return false;
    }
  }

  @override
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results);
      return _isConnected;
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      return false;
    }
  }

  @override
  Stream<bool> get connectivityStream => _connectivityStream;

  @override
  Future<ConnectionType> get connectionType async {
    try {
      final results = await _connectivity.checkConnectivity();
      
      if (results.contains(ConnectivityResult.wifi)) {
        return ConnectionType.wifi;
      } else if (results.contains(ConnectivityResult.mobile)) {
        return ConnectionType.mobile;
      } else if (results.contains(ConnectivityResult.ethernet)) {
        return ConnectionType.ethernet;
      } else if (results.contains(ConnectivityResult.bluetooth)) {
        return ConnectionType.bluetooth;
      } else if (results.contains(ConnectivityResult.vpn)) {
        return ConnectionType.vpn;
      } else if (results.contains(ConnectivityResult.other)) {
        return ConnectionType.other;
      } else {
        return ConnectionType.none;
      }
    } catch (e) {
      debugPrint('❌ Error getting connection type: $e');
      return ConnectionType.none;
    }
  }

  @override
  Future<bool> get isMobileConnection async {
    final type = await connectionType;
    return type == ConnectionType.mobile;
  }

  @override
  Future<bool> get isWiFiConnection async {
    final type = await connectionType;
    return type == ConnectionType.wifi;
  }

  /// Dispose resources
  void dispose() {
    _connectivityController.close();
  }
}