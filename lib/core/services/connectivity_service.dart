import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Enumeration for different connectivity states
enum ConnectivityState {
  connected,
  disconnected,
  slow,
  unknown,
}

/// Service for monitoring network connectivity
@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  StreamController<ConnectivityState>? _connectivityController;
  ConnectivityState _currentState = ConnectivityState.unknown;
  Timer? _connectivityTimer;

  /// Current connectivity state
  ConnectivityState get currentState => _currentState;

  /// Stream of connectivity changes
  Stream<ConnectivityState> get connectivityStream {
    _connectivityController ??= StreamController<ConnectivityState>.broadcast();
    _startMonitoring();
    return _connectivityController!.stream;
  }

  /// Initialize connectivity monitoring
  void initialize() {
    _startMonitoring();
    debugPrint('✅ ConnectivityService initialized');
  }

  /// Start monitoring connectivity changes
  void _startMonitoring() {
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    
    // Check initial connectivity
    _checkConnectivity();
    
    // Set up periodic connectivity checks
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _checkConnectivity();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = await _hasInternetConnection(connectivityResult);
      
      ConnectivityState newState;
      
      if (hasConnection) {
        // Check connection quality
        final isSlowConnection = await _isSlowConnection();
        newState = isSlowConnection 
            ? ConnectivityState.slow 
            : ConnectivityState.connected;
      } else {
        newState = ConnectivityState.disconnected;
      }

      if (newState != _currentState) {
        _currentState = newState;
        _connectivityController?.add(_currentState);
        debugPrint('📶 Connectivity changed to: ${_currentState.name}');
      }
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      _currentState = ConnectivityState.unknown;
      _connectivityController?.add(_currentState);
    }
  }

  /// Check if device has internet connection by attempting to reach a reliable host
  Future<bool> _hasInternetConnection(List<ConnectivityResult> results) async {
    // If no connectivity result indicates connection, return false immediately
    if (results.every((result) => result == ConnectivityResult.none)) {
      return false;
    }

    try {
      if (kIsWeb) {
        // For web, skip internet verification to avoid CORS issues
        // Connectivity status from connectivity_plus is sufficient for web
        debugPrint('🌐 Web platform - skipping internet verification');
        return true;
      } else {
        // For mobile, use InternetAddress.lookup
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 10));
        
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (e) {
      debugPrint('🌐 Internet connection check failed: $e');
      return false;
    }
  }

  /// Check if connection is slow by measuring response time
  Future<bool> _isSlowConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      if (kIsWeb) {
        // For web, skip speed test to avoid CORS issues
        debugPrint('🌐 Web platform - skipping connection speed test');
        return false; // Assume good connection on web
      } else {
        // For mobile, use InternetAddress.lookup
        await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
      }
      
      stopwatch.stop();
      
      // Consider connection slow if it takes more than 2 seconds
      final isSlow = stopwatch.elapsedMilliseconds > 2000;
      
      if (isSlow) {
        debugPrint('🐌 Slow connection detected: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return isSlow;
    } catch (e) {
      debugPrint('❌ Connection speed check failed: $e');
      return true; // Consider it slow if we can't measure
    }
  }

  /// Check if device has any form of connection
  Future<bool> hasConnection() async {
    await _checkConnectivity();
    return _currentState == ConnectivityState.connected || 
           _currentState == ConnectivityState.slow;
  }

  /// Check if device has a good (not slow) connection
  Future<bool> hasGoodConnection() async {
    await _checkConnectivity();
    return _currentState == ConnectivityState.connected;
  }

  /// Check if device is completely offline
  Future<bool> isOffline() async {
    await _checkConnectivity();
    return _currentState == ConnectivityState.disconnected;
  }

  /// Wait for connection to be restored
  Future<void> waitForConnection({Duration timeout = const Duration(minutes: 5)}) async {
    if (await hasConnection()) return;

    final completer = Completer<void>();
    StreamSubscription<ConnectivityState>? subscription;
    Timer? timeoutTimer;

    subscription = connectivityStream.listen((state) {
      if (state == ConnectivityState.connected || state == ConnectivityState.slow) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    timeoutTimer = Timer(timeout, () {
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Connection timeout', timeout));
      }
    });

    return completer.future;
  }

  /// Get connection type string for logging
  String get connectionType {
    switch (_currentState) {
      case ConnectivityState.connected:
        return 'Good Connection';
      case ConnectivityState.slow:
        return 'Slow Connection';
      case ConnectivityState.disconnected:
        return 'No Connection';
      case ConnectivityState.unknown:
        return 'Unknown Connection';
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController?.close();
    debugPrint('🔧 ConnectivityService disposed');
  }
}

/// Exception thrown when connection operations timeout
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message after ${timeout.inSeconds}s';
}