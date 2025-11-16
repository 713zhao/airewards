import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Performance monitoring and optimization service for AI Rewards System
@lazySingleton
class PerformanceService {
  static FirebasePerformance? _performance;
  
  // Performance metrics tracking
  final Map<String, Trace> _activeTraces = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, Duration> _averageTimes = {};
  
  /// Initialize performance service
  static Future<void> initialize() async {
    try {
      _performance = FirebasePerformance.instance;
      
      // Enable performance collection only in release mode
      await _performance!.setPerformanceCollectionEnabled(!kDebugMode);
      
      if (kDebugMode) {
        debugPrint('🚀 PerformanceService initialized (Debug mode - collection disabled)');
      } else {
        debugPrint('🚀 PerformanceService initialized (Release mode - collection enabled)');
      }
    } catch (e) {
      debugPrint('⚠️ Performance service initialization failed: $e');
    }
  }

  /// Start performance trace for an operation
  Future<void> startTrace(String name) async {
    try {
      if (_performance == null) return;
      
      final trace = _performance!.newTrace(name);
      await trace.start();
      _activeTraces[name] = trace;
      
      // Increment operation counter
      _operationCounts[name] = (_operationCounts[name] ?? 0) + 1;
      
      if (kDebugMode) {
        debugPrint('📊 Performance trace started: $name');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to start trace $name: $e');
    }
  }

  /// Stop performance trace and record metrics
  Future<void> stopTrace(String name, {Map<String, String>? attributes}) async {
    try {
      final trace = _activeTraces[name];
      if (trace == null) return;
      
      // Add custom attributes if provided
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      await trace.stop();
      _activeTraces.remove(name);
      
      if (kDebugMode) {
        debugPrint('✅ Performance trace stopped: $name');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to stop trace $name: $e');
    }
  }

  /// Record a custom metric
  Future<void> recordMetric(String traceName, String metricName, int value) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace != null) {
        trace.setMetric(metricName, value);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to record metric $metricName: $e');
    }
  }

  /// Track screen transition performance
  Future<void> trackScreenTransition(String fromScreen, String toScreen) async {
    final traceName = 'screen_transition_${fromScreen}_to_$toScreen';
    await startTrace(traceName);
    
    // Auto-stop after reasonable timeout
    Future.delayed(const Duration(seconds: 5), () {
      stopTrace(traceName, attributes: {
        'from_screen': fromScreen,
        'to_screen': toScreen,
      });
    });
  }

  /// Track user action performance
  Future<void> trackUserAction(String action, Future<void> Function() operation) async {
    final traceName = 'user_action_$action';
    await startTrace(traceName);
    
    final stopwatch = Stopwatch()..start();
    
    try {
      await operation();
      stopwatch.stop();
      
      await recordMetric(traceName, 'duration_ms', stopwatch.elapsedMilliseconds);
      await stopTrace(traceName, attributes: {
        'action': action,
        'success': 'true',
      });
    } catch (e) {
      stopwatch.stop();
      await stopTrace(traceName, attributes: {
        'action': action,
        'success': 'false',
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Track app launch performance
  static Future<void> trackAppLaunch() async {
    try {
      final trace = _performance?.newTrace('app_launch');
      await trace?.start();
      
      // Stop trace when first frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await trace?.stop();
        debugPrint('📱 App launch performance tracked');
      });
    } catch (e) {
      debugPrint('⚠️ Failed to track app launch: $e');
    }
  }

  /// Track memory usage
  static void trackMemoryUsage(String context) {
    if (kDebugMode) {
      // Get memory info using developer service
      final runtimeInfo = 0; // Placeholder for memory info
      debugPrint('💾 Memory usage in $context: ${(runtimeInfo / (1024 * 1024)).toStringAsFixed(2)} MB');
    }
  }

  /// Track animation performance
  Future<void> trackAnimation(String animationName, VoidCallback animation) async {
    final traceName = 'animation_$animationName';
    await startTrace(traceName);
    
    final stopwatch = Stopwatch()..start();
    
    // Monitor frame rate during animation
    int frameCount = 0;
    late VoidCallback frameCallback;
    
    frameCallback = () {
      frameCount++;
      if (stopwatch.elapsedMilliseconds < 2000) { // Track for 2 seconds max
        WidgetsBinding.instance.addPostFrameCallback((_) => frameCallback());
      } else {
        stopwatch.stop();
        final fps = frameCount / (stopwatch.elapsedMilliseconds / 1000);
        
        recordMetric(traceName, 'fps', fps.round());
        recordMetric(traceName, 'frame_count', frameCount);
        recordMetric(traceName, 'duration_ms', stopwatch.elapsedMilliseconds);
        
        stopTrace(traceName, attributes: {
          'animation_name': animationName,
          'target_fps': '60',
          'achieved_fps': fps.round().toString(),
        });
      }
    };
    
    // Start animation and frame tracking
    WidgetsBinding.instance.addPostFrameCallback((_) => frameCallback());
    animation();
  }

  /// Track network request performance
  Future<T> trackNetworkRequest<T>(String requestName, Future<T> Function() request) async {
    final traceName = 'network_$requestName';
    await startTrace(traceName);
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await request();
      stopwatch.stop();
      
      await recordMetric(traceName, 'duration_ms', stopwatch.elapsedMilliseconds);
      await stopTrace(traceName, attributes: {
        'request_name': requestName,
        'success': 'true',
      });
      
      return result;
    } catch (e) {
      stopwatch.stop();
      await recordMetric(traceName, 'duration_ms', stopwatch.elapsedMilliseconds);
      await stopTrace(traceName, attributes: {
        'request_name': requestName,
        'success': 'false',
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Get performance statistics for debugging
  Map<String, dynamic> getPerformanceStats() {
    return {
      'active_traces': _activeTraces.length,
      'operation_counts': Map<String, int>.from(_operationCounts),
      'average_times': _averageTimes.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
    };
  }

  /// Clean up performance service
  Future<void> cleanup() async {
    // Stop all active traces
    for (final traceName in _activeTraces.keys.toList()) {
      await stopTrace(traceName);
    }
    
    _operationCounts.clear();
    _averageTimes.clear();
    
    debugPrint('🧹 PerformanceService cleaned up');
  }

  /// Get performance metrics for dashboard (static method)
  static Future<Map<String, dynamic>> getPerformanceMetrics() async {
    final instance = PerformanceService();
    final stats = instance.getPerformanceStats();
    
    return {
      'frameRate': 60.0, // Would need frame rate monitoring
      'appLaunchTime': stats['average_times']?['app_launch'] ?? 0,
      'screenTransitions': stats['operation_counts']?.values.fold(0, (a, b) => a + b) ?? 0,
      'userActions': stats['operation_counts']?.length ?? 0,
      'networkRequests': stats['operation_counts']?.entries
          .where((e) => e.key.startsWith('network_'))
          .fold(0, (sum, entry) => sum + entry.value) ?? 0,
      'avgNetworkResponseTime': stats['average_times']?.entries
          .where((e) => e.key.startsWith('network_'))
          .fold(0.0, (sum, entry) => sum + entry.value) / 
          (stats['average_times']?.entries
              .where((e) => e.key.startsWith('network_'))
              .length ?? 1),
      'failedNetworkRequests': 0, // Would need error tracking
      'cacheHitRate': 0.8, // Placeholder
    };
  }

  /// Clear metrics (static method)
  static Future<void> clearMetrics() async {
    final instance = PerformanceService();
    instance._operationCounts.clear();
    instance._averageTimes.clear();
  }
}

/// Performance monitoring widget wrapper
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String screenName;
  final PerformanceService performanceService;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.screenName,
    required this.performanceService,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    
    // Track screen load time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopwatch.stop();
      widget.performanceService.recordMetric(
        'screen_${widget.screenName}',
        'load_time_ms',
        _stopwatch.elapsedMilliseconds,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension for easy performance tracking
extension PerformanceTracking on Widget {
  Widget withPerformanceMonitoring(String screenName, PerformanceService service) {
    return PerformanceMonitor(
      screenName: screenName,
      performanceService: service,
      child: this,
    );
  }
}