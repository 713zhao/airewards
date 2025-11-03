import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// Memory management and optimization service for AI Rewards System
@lazySingleton
class MemoryManagementService {
  static Timer? _memoryMonitoringTimer;
  static final List<WeakReference<Object>> _trackedObjects = [];
  static final Map<String, int> _allocationStats = {};
  static int _maxMemoryUsageMB = 0;
  
  // Memory thresholds (in MB)
  static const int _warningThresholdMB = 150;
  static const int _criticalThresholdMB = 200;
  
  /// Initialize memory management service
  static Future<void> initialize() async {
    try {
      // Start memory monitoring in debug mode
      if (kDebugMode) {
        _startMemoryMonitoring();
      }
      
      // Configure image cache for optimal memory usage
      _configureImageCache();
      
      // Set up memory pressure handling
      _setupMemoryPressureHandling();
      
      debugPrint('💾 MemoryManagementService initialized');
    } catch (e) {
      debugPrint('⚠️ MemoryManagementService initialization failed: $e');
    }
  }

  /// Start periodic memory monitoring
  static void _startMemoryMonitoring() {
    _memoryMonitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _checkMemoryUsage(),
    );
  }

  /// Configure image cache for optimal memory usage
  static void _configureImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Set reasonable limits for kid-friendly app
    imageCache.maximumSize = 100; // Max 100 cached images
    imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB max
    
    debugPrint('🖼️ Image cache configured for optimal memory usage');
  }

  /// Set up memory pressure handling
  static void _setupMemoryPressureHandling() {
    // Listen for system memory warnings
    SystemChannels.system.setMessageHandler((message) async {
      if (message is Map && message['type'] == 'memoryPressure') {
        await handleMemoryPressure();
      }
      return null;
    });
  }

  /// Check current memory usage
  static void _checkMemoryUsage() {
    if (!kDebugMode) return;
    
    try {
      final currentMemoryMB = _getCurrentMemoryUsageMB();
      
      if (currentMemoryMB > _maxMemoryUsageMB) {
        _maxMemoryUsageMB = currentMemoryMB;
      }
      
      if (currentMemoryMB > _criticalThresholdMB) {
        debugPrint('🚨 CRITICAL: Memory usage high: ${currentMemoryMB}MB');
        handleMemoryPressure();
      } else if (currentMemoryMB > _warningThresholdMB) {
        debugPrint('⚠️ WARNING: Memory usage elevated: ${currentMemoryMB}MB');
      } else {
        debugPrint('💾 Memory usage normal: ${currentMemoryMB}MB');
      }
      
      // Clean up weak references
      _cleanupWeakReferences();
      
    } catch (e) {
      debugPrint('⚠️ Memory check failed: $e');
    }
  }

  /// Get current memory usage in MB
  static int _getCurrentMemoryUsageMB() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Use ProcessInfo for mobile platforms
      final rss = ProcessInfo.currentRss;
      return (rss / (1024 * 1024)).round();
    } else {
      // Fallback for other platforms
      return 0;
    }
  }

  /// Handle memory pressure by clearing caches
  static Future<void> handleMemoryPressure() async {
    debugPrint('🧹 Handling memory pressure - clearing caches');
    
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Force garbage collection
      await _forceGarbageCollection();
      
      // Clear any tracked objects that are no longer referenced
      _cleanupWeakReferences();
      
      debugPrint('✅ Memory pressure handling completed');
      
    } catch (e) {
      debugPrint('⚠️ Memory pressure handling failed: $e');
    }
  }

  /// Force garbage collection
  static Future<void> _forceGarbageCollection() async {
    if (kDebugMode) {
      // Request garbage collection by creating memory pressure
      for (int i = 0; i < 3; i++) {
        // Force a potential garbage collection cycle
        final List<int> tempList = List.generate(10000, (index) => index);
        tempList.clear();
        await Future.delayed(const Duration(milliseconds: 10));
      }
      debugPrint('🗑️ Garbage collection requested');
    }
  }

  /// Track object for memory leak detection
  static void trackObject(Object object, String category) {
    if (kDebugMode) {
      _trackedObjects.add(WeakReference(object));
      _allocationStats[category] = (_allocationStats[category] ?? 0) + 1;
    }
  }

  /// Clean up weak references to disposed objects
  static void _cleanupWeakReferences() {
    if (!kDebugMode) return;
    
    final initialCount = _trackedObjects.length;
    _trackedObjects.removeWhere((ref) => ref.target == null);
    final cleanedCount = initialCount - _trackedObjects.length;
    
    if (cleanedCount > 0) {
      debugPrint('🧹 Cleaned up $cleanedCount disposed object references');
    }
  }

  /// Get memory statistics for debugging
  static Map<String, dynamic> getMemoryStats() {
    return {
      'current_memory_mb': _getCurrentMemoryUsageMB(),
      'max_memory_mb': _maxMemoryUsageMB,
      'tracked_objects': _trackedObjects.length,
      'allocation_stats': Map<String, int>.from(_allocationStats),
      'image_cache_size': PaintingBinding.instance.imageCache.currentSize,
      'image_cache_bytes': PaintingBinding.instance.imageCache.currentSizeBytes,
      'warning_threshold_mb': _warningThresholdMB,
      'critical_threshold_mb': _criticalThresholdMB,
    };
  }

  /// Optimize ListView for large datasets
  static Widget buildOptimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      cacheExtent: 250.0, // Cache only a small number of items
      itemBuilder: (context, index) {
        if (index >= items.length) return const SizedBox.shrink();
        return itemBuilder(context, items[index]);
      },
    );
  }

  /// Create memory-efficient grid view
  static Widget buildOptimizedGridView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      cacheExtent: 500.0, // Limited cache for grid items
      itemBuilder: (context, index) {
        if (index >= items.length) return const SizedBox.shrink();
        return itemBuilder(context, items[index]);
      },
    );
  }

  /// Dispose of resources properly
  static Future<void> dispose() async {
    _memoryMonitoringTimer?.cancel();
    _memoryMonitoringTimer = null;
    
    _trackedObjects.clear();
    _allocationStats.clear();
    
    debugPrint('🧹 MemoryManagementService disposed');
  }

  /// Get memory metrics for dashboard
  static Future<Map<String, dynamic>> getMemoryMetrics() async {
    // Clean up weak references first
    _cleanupWeakReferences();
    
    final stats = getMemoryStats();
    
    return {
      'usedMemoryMB': stats['current_memory_mb'] ?? 0.0,
      'maxMemoryMB': stats['max_memory_mb'] ?? 512.0,
      'trackedObjects': stats['tracked_objects'] ?? 0,
      'imageCacheSize': stats['image_cache_size'] ?? 0,
      'imageCacheBytes': stats['image_cache_bytes'] ?? 0,
      'allocationStats': stats['allocation_stats'] ?? {},
      'memoryPressure': _getCurrentMemoryUsageMB() / _maxMemoryUsageMB > 0.8 ? 'high' : 'normal',
    };
  }
}

/// Memory-efficient widget mixin
mixin MemoryOptimizedWidget<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<AnimationController> _animationControllers = [];

  @override
  void initState() {
    super.initState();
    MemoryManagementService.trackObject(this, runtimeType.toString());
  }

  /// Add a subscription that will be automatically disposed
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Add a timer that will be automatically disposed
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Add an animation controller that will be automatically disposed
  void addAnimationController(AnimationController controller) {
    _animationControllers.add(controller);
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    // Dispose all animation controllers
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();

    super.dispose();
  }
}

/// Memory-efficient list item widget
class MemoryEfficientListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const MemoryEfficientListItem({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Lazy loading container that only builds when visible
class LazyContainer extends StatefulWidget {
  final Widget Function() builder;
  final double height;
  final Widget? placeholder;

  const LazyContainer({
    super.key,
    required this.builder,
    required this.height,
    this.placeholder,
  });

  @override
  State<LazyContainer> createState() => _LazyContainerState();
}

class _LazyContainerState extends State<LazyContainer> {
  bool _hasBuilt = false;
  Widget? _child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Build child only when it comes into view
          if (!_hasBuilt) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final renderObject = context.findRenderObject() as RenderBox?;
              if (renderObject != null) {
                final position = renderObject.localToGlobal(Offset.zero);
                final viewport = MediaQuery.of(context).size;
                
                // Check if widget is near viewport
                final isNearViewport = position.dy < viewport.height + 200 && 
                                     position.dy + widget.height > -200;
                
                if (isNearViewport && !_hasBuilt) {
                  setState(() {
                    _hasBuilt = true;
                    _child = widget.builder();
                  });
                }
              }
            });
          }

          return _hasBuilt && _child != null
              ? _child!
              : widget.placeholder ?? const SizedBox.shrink();
        },
      ),
    );
  }
}