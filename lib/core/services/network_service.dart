import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprehensive network monitoring and management service
class NetworkService {
  static bool _initialized = false;
  static StreamController<NetworkStatus>? _statusController;
  static StreamController<NetworkEvent>? _eventController;
  static Timer? _monitoringTimer;
  static NetworkStatus _currentStatus = NetworkStatus.unknown;
  static final List<NetworkEvent> _eventHistory = [];
  static final Map<String, NetworkMetrics> _endpointMetrics = {};

  /// Initialize network monitoring service
  static Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('📡 Initializing NetworkService...');

    try {
      _statusController = StreamController<NetworkStatus>.broadcast();
      _eventController = StreamController<NetworkEvent>.broadcast();

      // Check initial connectivity
      await _checkInitialConnectivity();

      // Listen for connectivity changes
      Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      });

      // Start network monitoring
      _startNetworkMonitoring();

      _initialized = true;
      debugPrint('✅ NetworkService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize NetworkService: $e');
      rethrow;
    }
  }

  /// Get network status stream
  static Stream<NetworkStatus> get statusStream =>
      _statusController?.stream ?? const Stream.empty();

  /// Get network event stream
  static Stream<NetworkEvent> get eventStream =>
      _eventController?.stream ?? const Stream.empty();

  /// Get current network status
  static NetworkStatus get currentStatus => _currentStatus;

  /// Check if currently connected to internet
  static bool get isConnected => _currentStatus == NetworkStatus.connected;

  /// Dispose network service
  static void dispose() {
    _statusController?.close();
    _eventController?.close();
    _monitoringTimer?.cancel();
    _initialized = false;
  }

  // ========== Connectivity Management ==========

  /// Check network connectivity
  static Future<NetworkStatus> checkConnectivity() async {
    try {
      // Check device connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return _updateStatus(NetworkStatus.disconnected, 'No network connection');
      }

      // Test actual internet connectivity
      final hasInternet = await _testInternetConnectivity();
      
      if (hasInternet) {
        return _updateStatus(NetworkStatus.connected, 'Internet connection available');
      } else {
        return _updateStatus(NetworkStatus.limited, 'Limited connectivity - no internet access');
      }
    } catch (e) {
      debugPrint('❌ Connectivity check failed: $e');
      return _updateStatus(NetworkStatus.error, 'Connectivity check failed: $e');
    }
  }

  /// Test internet connectivity by attempting to reach multiple servers
  static Future<bool> _testInternetConnectivity() async {
    final testUrls = [
      'google.com',
      'cloudflare.com',
      '8.8.8.8', // Google DNS
    ];

    for (final url in testUrls) {
      try {
        final result = await InternetAddress.lookup(url).timeout(
          const Duration(seconds: 5),
        );
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint('✅ Internet connectivity confirmed via $url');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Failed to reach $url: $e');
        continue;
      }
    }

    debugPrint('❌ No internet connectivity detected');
    return false;
  }

  /// Get detailed connection information
  static Future<ConnectionInfo> getConnectionInfo() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = await _testInternetConnectivity();
      
      ConnectionType connectionType = ConnectionType.none;
      
      // Handle connectivity results (newer API returns List)
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        connectionType = ConnectionType.wifi;
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        connectionType = ConnectionType.cellular;
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        connectionType = ConnectionType.ethernet;
      } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
        connectionType = ConnectionType.bluetooth;
      }

      // Test connection speed (approximate)
      final speed = await _measureConnectionSpeed();

      return ConnectionInfo(
        type: connectionType,
        hasInternet: hasInternet,
        status: _currentStatus,
        speed: speed,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Failed to get connection info: $e');
      return ConnectionInfo(
        type: ConnectionType.none,
        hasInternet: false,
        status: NetworkStatus.error,
        timestamp: DateTime.now(),
      );
    }
  }

  // ========== Network Performance Monitoring ==========

  /// Measure network latency to specific endpoint
  static Future<Duration?> measureLatency(String endpoint) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final result = await InternetAddress.lookup(endpoint).timeout(
        const Duration(seconds: 10),
      );
      
      stopwatch.stop();
      
      if (result.isNotEmpty) {
        final latency = stopwatch.elapsed;
        _recordNetworkMetric(endpoint, 'latency', latency.inMilliseconds.toDouble());
        return latency;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Latency measurement failed for $endpoint: $e');
      return null;
    }
  }

  /// Measure approximate connection speed
  static Future<ConnectionSpeed> _measureConnectionSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Download a small test file (simulated)
      await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      
      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;
      
      // Rough speed categorization based on response time
      if (responseTime < 100) {
        return ConnectionSpeed.fast;
      } else if (responseTime < 500) {
        return ConnectionSpeed.medium;
      } else {
        return ConnectionSpeed.slow;
      }
    } catch (e) {
      debugPrint('⚠️ Speed measurement failed: $e');
      return ConnectionSpeed.unknown;
    }
  }

  /// Record network metrics for endpoint
  static void _recordNetworkMetric(String endpoint, String metric, double value) {
    if (!_endpointMetrics.containsKey(endpoint)) {
      _endpointMetrics[endpoint] = NetworkMetrics(endpoint: endpoint);
    }
    
    final metrics = _endpointMetrics[endpoint]!;
    
    switch (metric) {
      case 'latency':
        metrics.recordLatency(value);
        break;
      case 'success':
        metrics.recordSuccess();
        break;
      case 'failure':
        metrics.recordFailure();
        break;
    }
  }

  /// Get network metrics for endpoint
  static NetworkMetrics? getEndpointMetrics(String endpoint) {
    return _endpointMetrics[endpoint];
  }

  /// Get all network metrics
  static Map<String, NetworkMetrics> getAllMetrics() {
    return Map.unmodifiable(_endpointMetrics);
  }

  // ========== Network Quality Assessment ==========

  /// Assess overall network quality
  static Future<NetworkQuality> assessNetworkQuality() async {
    try {
      final connectionInfo = await getConnectionInfo();
      
      if (!connectionInfo.hasInternet) {
        return NetworkQuality(
          score: 0,
          level: QualityLevel.poor,
          description: 'No internet connection',
          recommendations: ['Check network settings', 'Try different connection'],
        );
      }

      // Test latency to multiple endpoints
      final latencies = <Duration>[];
      final testEndpoints = ['google.com', 'cloudflare.com'];
      
      for (final endpoint in testEndpoints) {
        final latency = await measureLatency(endpoint);
        if (latency != null) {
          latencies.add(latency);
        }
      }

      if (latencies.isEmpty) {
        return NetworkQuality(
          score: 25,
          level: QualityLevel.poor,
          description: 'Unable to measure network performance',
          recommendations: ['Check firewall settings', 'Try different DNS'],
        );
      }

      // Calculate average latency
      final avgLatency = latencies
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a + b) / latencies.length;

      // Assess quality based on latency and connection type
      int score;
      QualityLevel level;
      String description;
      List<String> recommendations = [];

      if (avgLatency < 50) {
        score = 95;
        level = QualityLevel.excellent;
        description = 'Excellent network performance';
      } else if (avgLatency < 100) {
        score = 85;
        level = QualityLevel.good;
        description = 'Good network performance';
      } else if (avgLatency < 200) {
        score = 70;
        level = QualityLevel.fair;
        description = 'Fair network performance';
        recommendations.add('Consider using WiFi for better performance');
      } else {
        score = 40;
        level = QualityLevel.poor;
        description = 'Poor network performance';
        recommendations.addAll([
          'Check for background downloads',
          'Move closer to WiFi router',
          'Consider switching networks',
        ]);
      }

      // Adjust score based on connection type
      switch (connectionInfo.type) {
        case ConnectionType.wifi:
          // No adjustment
          break;
        case ConnectionType.cellular:
          score = (score * 0.9).round(); // Slight penalty for cellular
          break;
        case ConnectionType.ethernet:
          score = (score * 1.1).round().clamp(0, 100); // Bonus for ethernet
          break;
        default:
          score = (score * 0.8).round(); // Penalty for other connections
      }

      return NetworkQuality(
        score: score,
        level: level,
        description: description,
        recommendations: recommendations,
        avgLatency: avgLatency,
        connectionType: connectionInfo.type,
      );

    } catch (e) {
      debugPrint('❌ Network quality assessment failed: $e');
      return NetworkQuality(
        score: 0,
        level: QualityLevel.poor,
        description: 'Network assessment failed: $e',
        recommendations: ['Check network connection'],
      );
    }
  }

  // ========== Retry and Recovery ==========

  /// Execute network operation with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempt = 0;
    
    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        debugPrint('🔄 Network operation attempt $attempt failed: $e');
        
        // Check if we should retry
        if (attempt > maxRetries || (retryIf != null && !retryIf(e))) {
          rethrow;
        }
        
        // Wait before retry, with exponential backoff
        final retryDelay = delay * (attempt * attempt);
        debugPrint('⏳ Retrying in ${retryDelay.inMilliseconds}ms...');
        await Future.delayed(retryDelay);
        
        // Check connectivity before retry
        final status = await checkConnectivity();
        if (status != NetworkStatus.connected) {
          throw NetworkException('No network connectivity for retry');
        }
      }
    }
    
    throw NetworkException('Max retries exceeded');
  }

  /// Wait for network connectivity
  static Future<void> waitForConnectivity({
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final completer = Completer<void>();
    late StreamSubscription subscription;
    Timer? timeoutTimer;
    
    // Set up timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Network connectivity timeout', timeout));
      }
    });
    
    // Listen for connectivity
    subscription = statusStream.listen((status) {
      if (status == NetworkStatus.connected && !completer.isCompleted) {
        completer.complete();
      }
    });
    
    // Check current status first
    if (_currentStatus == NetworkStatus.connected) {
      completer.complete();
    }
    
    try {
      await completer.future;
    } finally {
      subscription.cancel();
      timeoutTimer.cancel();
    }
  }

  // ========== Private Implementation ==========

  /// Check initial connectivity status
  static Future<void> _checkInitialConnectivity() async {
    _currentStatus = await checkConnectivity();
  }

  /// Handle connectivity changes
  static void _handleConnectivityChange(List<ConnectivityResult> results) {
    debugPrint('📡 Connectivity changed: $results');
    
    // Perform detailed check after connectivity change
    Future.delayed(const Duration(seconds: 1), () async {
      await checkConnectivity();
    });
  }

  /// Start network monitoring timer
  static void _startNetworkMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performPeriodicCheck();
    });
  }

  /// Perform periodic network check
  static Future<void> _performPeriodicCheck() async {
    try {
      final previousStatus = _currentStatus;
      await checkConnectivity();
      
      // Log status changes
      if (_currentStatus != previousStatus) {
        _addNetworkEvent(NetworkEvent(
          type: NetworkEventType.statusChanged,
          timestamp: DateTime.now(),
          description: 'Network status changed from $previousStatus to $_currentStatus',
          data: {
            'previous': previousStatus.toString(),
            'current': _currentStatus.toString(),
          },
        ));
      }
    } catch (e) {
      debugPrint('⚠️ Periodic network check failed: $e');
    }
  }

  /// Update network status and notify listeners
  static NetworkStatus _updateStatus(NetworkStatus status, String message) {
    if (_currentStatus != status) {
      debugPrint('📡 Network status: $status - $message');
      
      _currentStatus = status;
      _statusController?.add(status);
      
      _addNetworkEvent(NetworkEvent(
        type: NetworkEventType.statusChanged,
        timestamp: DateTime.now(),
        description: message,
        data: {'status': status.toString()},
      ));
    }
    
    return status;
  }

  /// Add network event to history
  static void _addNetworkEvent(NetworkEvent event) {
    _eventHistory.add(event);
    
    // Keep only last 100 events
    if (_eventHistory.length > 100) {
      _eventHistory.removeAt(0);
    }
    
    _eventController?.add(event);
  }

  /// Get network event history
  static List<NetworkEvent> getEventHistory() {
    return List.unmodifiable(_eventHistory);
  }
}

// ========== Supporting Classes ==========

class ConnectionInfo {
  final ConnectionType type;
  final bool hasInternet;
  final NetworkStatus status;
  final ConnectionSpeed? speed;
  final DateTime timestamp;

  const ConnectionInfo({
    required this.type,
    required this.hasInternet,
    required this.status,
    this.speed,
    required this.timestamp,
  });
}

class NetworkMetrics {
  final String endpoint;
  final List<double> _latencies = [];
  int _successCount = 0;
  int _failureCount = 0;
  DateTime? _lastUpdated;

  NetworkMetrics({required this.endpoint});

  void recordLatency(double latencyMs) {
    _latencies.add(latencyMs);
    if (_latencies.length > 50) {
      _latencies.removeAt(0);
    }
    _lastUpdated = DateTime.now();
  }

  void recordSuccess() {
    _successCount++;
    _lastUpdated = DateTime.now();
  }

  void recordFailure() {
    _failureCount++;
    _lastUpdated = DateTime.now();
  }

  double? get averageLatency {
    if (_latencies.isEmpty) return null;
    return _latencies.reduce((a, b) => a + b) / _latencies.length;
  }

  double get successRate {
    final total = _successCount + _failureCount;
    return total > 0 ? _successCount / total : 0.0;
  }

  int get totalRequests => _successCount + _failureCount;
  DateTime? get lastUpdated => _lastUpdated;
}

class NetworkQuality {
  final int score; // 0-100
  final QualityLevel level;
  final String description;
  final List<String> recommendations;
  final double? avgLatency;
  final ConnectionType? connectionType;

  const NetworkQuality({
    required this.score,
    required this.level,
    required this.description,
    required this.recommendations,
    this.avgLatency,
    this.connectionType,
  });
}

class NetworkEvent {
  final NetworkEventType type;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? data;

  const NetworkEvent({
    required this.type,
    required this.timestamp,
    required this.description,
    this.data,
  });
}

class NetworkException implements Exception {
  final String message;
  final String? code;
  final dynamic cause;

  const NetworkException(this.message, {this.code, this.cause});

  @override
  String toString() => 'NetworkException: $message';
}

enum NetworkStatus {
  unknown,
  connected,
  disconnected,
  limited, // Connected but no internet
  error,
}

enum ConnectionType {
  none,
  wifi,
  cellular,
  ethernet,
  bluetooth,
}

enum ConnectionSpeed {
  unknown,
  slow,
  medium,
  fast,
}

enum QualityLevel {
  poor,
  fair,
  good,
  excellent,
}

enum NetworkEventType {
  statusChanged,
  qualityChanged,
  error,
  recovered,
}